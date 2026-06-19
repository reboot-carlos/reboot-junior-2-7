"""
Configuration - Zachar IA
Gestion des variables d'environnement et des paramètres globaux
"""

import os
import logging
from dotenv import load_dotenv

load_dotenv()
logger = logging.getLogger(__name__)


class Settings:
    """Configuration de l'application"""

    def __init__(self):
        # Application
        self.title = "Zachar IA"
        self.description = "Chatbot intelligent alimenté par Claude AI"
        self.version = "1.0.0"
        self.debug = os.getenv("DEBUG", "false").lower() == "true"
        self.environment = os.getenv("ENVIRONMENT", "development")

        # Server
        self.host = os.getenv("HOST", "0.0.0.0")
        self.port = int(os.getenv("PORT", 8000))

        # API Claude
        self.api_key = os.getenv("ANTHROPIC_API_KEY", "")
        if not self.api_key:
            raise ValueError("ANTHROPIC_API_KEY non définie dans .env")

        self.api_model = os.getenv("CLAUDE_MODEL", "claude-haiku-4-5")
        self.api_timeout = int(os.getenv("API_TIMEOUT", 30))

        # CORS - restrict to safe origins in production
        if self.environment == "production":
            self.cors_origins = [os.getenv("ALLOWED_ORIGIN", "http://localhost:8000")]
        else:
            self.cors_origins = ["http://localhost:8000", "http://localhost:3000", "http://127.0.0.1:8000"]


settings = Settings()
