#!/bin/bash
# Local Docker integration test for Zachar IA.
# Builds the image, starts a container, runs all checks, tears down.

set -uo pipefail

# ── config ────────────────────────────────────────────────────────────────────
IMAGE="zachar-ia:local-test"
CONTAINER="zachar-local-test"
PORT=8099
BASE="http://localhost:$PORT"
TIMEOUT=30          # seconds to wait for container to be healthy

# ── colour helpers ────────────────────────────────────────────────────────────
GREEN="\033[0;32m"; RED="\033[0;31m"; YELLOW="\033[1;33m"
CYAN="\033[0;36m";  BOLD="\033[1m";   NC="\033[0m"

pass() { echo -e "  ${GREEN}✓${NC}  $1"; PASSED=$((PASSED+1)); }
fail() { echo -e "  ${RED}✗${NC}  $1"; FAILED=$((FAILED+1)); }
info() { echo -e "  ${YELLOW}→${NC}  $1"; }
section() { echo -e "\n${CYAN}${BOLD}$1${NC}"; }

PASSED=0; FAILED=0

# ── cleanup trap ──────────────────────────────────────────────────────────────
cleanup() {
  docker stop "$CONTAINER" &>/dev/null || true
  docker rm   "$CONTAINER" &>/dev/null || true
}
trap cleanup EXIT

# ── helpers ───────────────────────────────────────────────────────────────────
# Returns HTTP status code for a request.
http_code() { curl -s -o /dev/null -w "%{http_code}" "$@"; }

# Returns the full response body.
http_body() { curl -s "$@"; }

# Asserts status code equals expected.
assert_status() {
  local label=$1 expected=$2; shift 2
  local got
  got=$(http_code "$@")
  if [[ "$got" == "$expected" ]]; then
    pass "$label → $got"
  else
    fail "$label → expected $expected, got $got"
  fi
}

# Asserts the body contains a substring (bash glob, avoids grep/echo -e issues).
assert_contains() {
  local label=$1 needle=$2; shift 2
  local body
  body=$(http_body "$@")
  if [[ "$body" == *"$needle"* ]]; then
    pass "$label"
  else
    fail "$label (expected to contain: $needle)"
    info "First 200 chars: ${body:0:200}"
  fi
}

# ── 1. prerequisites ──────────────────────────────────────────────────────────
section "1/6  Prerequisites"

command -v docker &>/dev/null && pass "docker installed" || { fail "docker not found"; exit 1; }
command -v curl   &>/dev/null && pass "curl installed"   || { fail "curl not found";   exit 1; }

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a; source .env; set +a
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  fail "ANTHROPIC_API_KEY not set (add it to .env)"
  exit 1
fi
pass "ANTHROPIC_API_KEY present"

# ── 2. build ──────────────────────────────────────────────────────────────────
section "2/6  Docker build"

info "Building $IMAGE …"
if docker build -t "$IMAGE" . -q &>/dev/null; then
  pass "Image built successfully"
else
  fail "Docker build failed"
  exit 1
fi

IMAGE_USER=$(docker inspect "$IMAGE" --format='{{.Config.User}}')
[[ "$IMAGE_USER" == "appuser" ]] && pass "Runs as non-root user (appuser)" \
                                  || fail "Expected appuser, got '$IMAGE_USER'"

# ── 3. start container ────────────────────────────────────────────────────────
section "3/6  Container startup"

docker run -d \
  --name "$CONTAINER" \
  -p "$PORT:8000" \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -e ENVIRONMENT=production \
  -e DEBUG=false \
  "$IMAGE" &>/dev/null

pass "Container started (port $PORT)"

# Wait for /health to respond.
info "Waiting for app to be ready …"
ready=false
for i in $(seq 1 $TIMEOUT); do
  if curl -sf "$BASE/health" &>/dev/null; then
    ready=true; break
  fi
  sleep 1
done

if $ready; then
  pass "App ready after ${i}s"
else
  fail "App did not respond within ${TIMEOUT}s"
  info "Container logs:"
  docker logs "$CONTAINER" 2>&1 | tail -20
  exit 1
fi

# ── 4. endpoint tests ─────────────────────────────────────────────────────────
section "4/6  Endpoint tests"

# Static pages
assert_status  "GET /  (landing page)"          200  "$BASE/"
assert_status  "GET /index.html  (chatbot UI)"  200  "$BASE/index.html"
assert_contains "Landing page is HTML"  "DOCTYPE"     "$BASE/"
assert_contains "Chatbot page is HTML" "DOCTYPE"     "$BASE/index.html"

# Assets
assert_status  "GET /css/chatbot-pro.css"        200  "$BASE/css/chatbot-pro.css"
assert_status  "GET /static/saros.jpg"           200  "$BASE/static/saros.jpg"
assert_status  "GET /static/saros-boss.avif"     200  "$BASE/static/saros-boss.avif"

# Path traversal blocked
assert_status  "Path traversal blocked on /css/" 404  "$BASE/css/../../etc/passwd"

# Info / health
assert_contains "GET /health → status:healthy"  '"status":"healthy"'  "$BASE/health"
assert_contains "GET /info → name present"      '"name"'              "$BASE/info"
assert_contains "GET /info → version present"   '"version"'           "$BASE/info"

# Chat API – status before any messages
STATUS=$(http_body "$BASE/api/chat/status")
if echo "$STATUS" | grep -q '"conversation_length":0'; then
  pass "GET /api/chat/status → conversation_length is 0"
else
  fail "GET /api/chat/status → unexpected body: $STATUS"
fi

# ── 5. input validation ───────────────────────────────────────────────────────
section "5/6  Input validation"

assert_status "POST /api/chat empty message → 422" 422 \
  -X POST "$BASE/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message":""}'

assert_status "POST /api/chat invalid language → 422" 422 \
  -X POST "$BASE/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hi","language":"klingon"}'

assert_status "POST /api/chat invalid behavior → 422" 422 \
  -X POST "$BASE/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hi","behavior":"evil"}'

# ── 6. live Claude call ───────────────────────────────────────────────────────
section "6/6  Live Claude API call"

info "Sending real message to Claude …"
RESPONSE=$(curl -s -X POST "$BASE/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message":"Reply with exactly the word PONG and nothing else.","language":"english"}')

if echo "$RESPONSE" | grep -q '"success":true'; then
  pass "POST /api/chat → success:true"
else
  fail "POST /api/chat → missing success:true"
  info "Response: $RESPONSE"
fi

REPLY=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['response'])" 2>/dev/null || echo "")
if [[ -n "$REPLY" ]]; then
  pass "Claude replied: \"${REPLY:0:80}\""
else
  fail "Could not parse Claude reply"
fi

# Conversation length should now be 1
STATUS2=$(http_body "$BASE/api/chat/status")
if echo "$STATUS2" | grep -q '"conversation_length":1'; then
  pass "Conversation length incremented to 1"
else
  fail "Conversation length not incremented — got: $STATUS2"
fi

# Reset
RESET=$(http_body -X POST "$BASE/api/chat/reset")
if echo "$RESET" | grep -q '"success":true'; then
  pass "POST /api/chat/reset → success:true"
else
  fail "POST /api/chat/reset → $RESET"
fi

STATUS3=$(http_body "$BASE/api/chat/status")
if echo "$STATUS3" | grep -q '"conversation_length":0'; then
  pass "Conversation reset to 0"
else
  fail "Conversation not reset — got: $STATUS3"
fi

# ── summary ───────────────────────────────────────────────────────────────────
TOTAL=$((PASSED + FAILED))
echo -e "\n${BOLD}─────────────────────────────────────────${NC}"
echo -e "${BOLD}Results: ${GREEN}$PASSED passed${NC}${BOLD}, ${RED}$FAILED failed${NC}${BOLD} / $TOTAL total${NC}"
echo -e "${BOLD}─────────────────────────────────────────${NC}\n"

[[ $FAILED -eq 0 ]] && echo -e "${GREEN}${BOLD}All tests passed — ready to deploy.${NC}\n" && exit 0
echo -e "${RED}${BOLD}$FAILED test(s) failed — fix before deploying.${NC}\n" && exit 1
