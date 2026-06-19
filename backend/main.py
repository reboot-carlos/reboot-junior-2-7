"""
Application Principale - Zachar IA
FastAPI backend pour le chatbot intelligent
"""

import os
import logging
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from backend.config import settings
from backend.claude_service import ClaudeService

# Configure logging
logging.basicConfig(level=logging.INFO if not settings.debug else logging.DEBUG)
logger = logging.getLogger(__name__)

# Déterminer les chemins
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(BASE_DIR)
FRONTEND_DIR = os.path.join(PROJECT_DIR, "frontend")
STATIC_DIR = os.path.join(PROJECT_DIR, "static")

# Créer le répertoire static s'il n'existe pas
os.makedirs(STATIC_DIR, exist_ok=True)

# Initialiser l'application
app = FastAPI(
    title=settings.title,
    description=settings.description,
    version=settings.version,
    docs_url="/api/docs" if settings.debug else None,
    redoc_url="/api/redoc" if settings.debug else None,
)

# CORS Middleware - Configuré depuis settings
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)

# Monter les fichiers statiques
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


# ============================================================
# MODÈLES PYDANTIC
# ============================================================


class ChatRequest(BaseModel):
    """Requête de chat"""

    message: str = Field(..., min_length=1, max_length=5000)
    chatbot_name: str = Field(default="Zachar IA", max_length=100)
    user_name: str = Field(default="", max_length=100)
    language: str = Field(default="french", pattern="^(french|english|spanish|german)$")
    blagues: bool = False
    behavior: str = Field(default="friendly", pattern="^(friendly|professional|funny)$")


class ChatResponse(BaseModel):
    """Réponse du chat"""

    response: str
    conversation_length: int
    success: bool


# Global service instance for stateless handling per request
_claude_service = ClaudeService()


# ============================================================
# ROUTES - Pages
# ============================================================


@app.get("/", tags=["Pages"])
async def root():
    """Servir la landing page"""
    landing_path = os.path.join(FRONTEND_DIR, "landing.html")
    return FileResponse(landing_path, media_type="text/html")


@app.get("/index.html", tags=["Pages"])
async def chatbot():
    """Servir le chatbot"""
    index_path = os.path.join(FRONTEND_DIR, "index.html")
    return FileResponse(index_path, media_type="text/html")


@app.get("/css/{filename}", tags=["Assets"])
async def get_css(filename: str):
    safe_name = os.path.basename(filename)
    css_path = os.path.join(FRONTEND_DIR, "css", safe_name)
    if not os.path.exists(css_path):
        raise HTTPException(status_code=404, detail="Not found")
    return FileResponse(css_path, media_type="text/css")


@app.get("/js/{filename}", tags=["Assets"])
async def get_js(filename: str):
    safe_name = os.path.basename(filename)
    js_path = os.path.join(FRONTEND_DIR, "js", safe_name)
    if not os.path.exists(js_path):
        raise HTTPException(status_code=404, detail="Not found")
    return FileResponse(js_path, media_type="text/javascript")


# ============================================================
# API - Chat
# ============================================================


@app.post("/api/chat", tags=["Chat"], response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Envoyer un message au chatbot Claude

    - **message** (required): Le message de l'utilisateur
    - **chatbot_name** (optional): Nom du chatbot
    - **user_name** (optional): Nom de l'utilisateur
    - **language** (optional): Langue (french, english, spanish, german)
    - **behavior** (optional): Comportement (friendly, professional, funny)
    - **blagues** (optional): Inclure des blagues
    """
    try:
        response = _claude_service.chat(
            user_message=request.message,
            chatbot_name=request.chatbot_name,
            user_name=request.user_name or None,
            language=request.language,
            blagues=request.blagues,
            behavior=request.behavior,
        )

        return ChatResponse(
            response=response,
            conversation_length=_claude_service.get_conversation_length(),
            success=True,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Chat error: {type(e).__name__}")
        raise HTTPException(status_code=500, detail="Erreur serveur")


@app.post("/api/chat/reset", tags=["Chat"])
async def reset_chat():
    """Réinitialiser la conversation"""
    _claude_service.reset_conversation()
    return {
        "success": True,
        "message": "Conversation réinitialisée",
        "conversation_length": 0,
    }


@app.get("/api/chat/status", tags=["Chat"])
async def chat_status():
    """Obtenir le statut du chat"""
    return {
        "conversation_length": _claude_service.get_conversation_length(),
        "model": settings.api_model,
        "api_active": True,
        "chatbot_name": "Zachar IA",
    }


# ============================================================
# HEALTH CHECK
# ============================================================


@app.get("/health", tags=["Health"])
async def health_check():
    """Vérifier l'état de santé de l'application"""
    return {
        "status": "healthy",
        "service": settings.title,
        "version": settings.version,
        "environment": settings.environment,
    }


@app.get("/info", tags=["Info"])
async def app_info():
    """Obtenir les informations de l'application"""
    return {
        "name": settings.title,
        "description": settings.description,
        "version": settings.version,
        "environment": settings.environment,
        "debug": settings.debug,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "backend.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level="info" if not settings.debug else "debug",
    )
