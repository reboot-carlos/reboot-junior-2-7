# Running with Docker

## Quick Start

### Build the image
```bash
docker build -t zachar-ia:latest .
```

### Run with docker-compose
```bash
# Copy .env.example to .env and update ANTHROPIC_API_KEY
cp .env.example .env

# Start the container
docker-compose up -d

# View logs
docker-compose logs -f zachar-ia

# Stop
docker-compose down
```

### Run standalone
```bash
docker run -p 8000:8000 \
  -e ANTHROPIC_API_KEY='sk-ant-...' \
  -e ENVIRONMENT=production \
  zachar-ia:latest
```

## Environment Variables

- `ANTHROPIC_API_KEY` (required) - Your Anthropic API key
- `ENVIRONMENT` - 'development' or 'production' (default: development)
- `DEBUG` - 'true' or 'false' (default: false)
- `HOST` - Server host (default: 0.0.0.0)
- `PORT` - Server port (default: 8000)
- `CLAUDE_MODEL` - Claude model to use (default: claude-opus-4-1-20250805)
- `ALLOWED_ORIGIN` - CORS origin for production (default: http://localhost:8000)

## API Endpoints

- `GET /` - Landing page
- `GET /index.html` - Chatbot interface
- `POST /api/chat` - Send message to Claude
- `POST /api/chat/reset` - Reset conversation
- `GET /api/chat/status` - Get conversation status
- `GET /health` - Health check
- `GET /info` - App info
- `GET /api/docs` - API documentation (dev only)

## Health Check

The container includes a built-in health check:
```bash
curl http://localhost:8000/health
```

## Production Checklist

- [ ] Use proper secrets management (not .env files)
- [ ] Set `ENVIRONMENT=production` and `DEBUG=false`
- [ ] Configure `ALLOWED_ORIGIN` to your domain
- [ ] Use HTTPS in production
- [ ] Set up proper logging aggregation
- [ ] Configure resource limits (CPU, memory)
- [ ] Use a reverse proxy (nginx, Traefik)
- [ ] Enable rate limiting if needed
- [ ] Regular security audits
