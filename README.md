# Zachar IA

Chatbot IA interactif propulsé par Claude (Anthropic), servi via FastAPI.

## Structure

```
RebootJR/
├── backend/
│   ├── main.py            # FastAPI app, routes
│   ├── config.py          # Configuration via env vars
│   └── claude_service.py  # Anthropic API integration
├── frontend/
│   ├── index.html         # Chatbot UI
│   ├── landing.html       # Landing page
│   └── css/
│       └── chatbot-pro.css
├── static/                # Images and assets served at /static/
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── .env.example
```

## Démarrage rapide

### Prérequis

- Python 3.12+
- Une clé API Anthropic (`https://console.anthropic.com`)

### Local

```bash
cp .env.example .env
# Ajouter ANTHROPIC_API_KEY dans .env

./quickstart.sh       # Linux/Mac
quickstart.bat        # Windows
```

Ou manuellement :

```bash
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python -m uvicorn backend.main:app --reload --port 8000
```

Accéder à : **http://localhost:8000**

### Docker

```bash
cp .env.example .env
# Ajouter ANTHROPIC_API_KEY dans .env

docker-compose up -d
```

Voir `DOCKER_README.md` pour plus de détails.

## API

| Méthode | Endpoint           | Description                    |
|---------|--------------------|--------------------------------|
| GET     | `/`                | Landing page                   |
| GET     | `/index.html`      | Chatbot UI                     |
| POST    | `/api/chat`        | Envoyer un message             |
| POST    | `/api/chat/reset`  | Réinitialiser la conversation  |
| GET     | `/api/chat/status` | Statut de la conversation      |
| GET     | `/health`          | Health check                   |
| GET     | `/info`            | Infos de l'application         |
| GET     | `/api/docs`        | Swagger UI (dev uniquement)    |

### Exemple `/api/chat`

```bash
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Bonjour!", "language": "french"}'
```

```json
{
  "response": "Bonjour! Comment puis-je vous aider?",
  "conversation_length": 1,
  "success": true
}
```

## Variables d'environnement

| Variable             | Défaut                     | Description                  |
|----------------------|----------------------------|------------------------------|
| `ANTHROPIC_API_KEY`  | *(requis)*                 | Clé API Anthropic            |
| `CLAUDE_MODEL`       | `claude-opus-4-1-20250805` | Modèle Claude à utiliser     |
| `ENVIRONMENT`        | `development`              | `development` ou `production`|
| `DEBUG`              | `false`                    | Active Swagger UI si `true`  |
| `PORT`               | `8000`                     | Port du serveur              |
| `ALLOWED_ORIGIN`     | `http://localhost:8000`    | CORS origin (production)     |

## Stack

- **Backend** : FastAPI + Uvicorn
- **IA** : Anthropic Claude API
- **Frontend** : HTML5 + CSS3 + Vanilla JS
- **Config** : Pydantic + python-dotenv
