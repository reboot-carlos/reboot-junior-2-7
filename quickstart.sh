#!/bin/bash

# ========================================
# ZACHAR IA - Quick Start Script
# ========================================

echo "🚀 Zachar IA - Démarrage Rapide"
echo "================================"

# Vérifier Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 non trouvé. Installez Python 3.11+"
    exit 1
fi

echo "✅ Python $(python3 --version)"

# Créer venv si nécessaire
if [ ! -d "venv" ]; then
    echo "📦 Création de l'environnement virtuel..."
    python3 -m venv venv
fi

# Activer venv
source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null

# Installer dépendances
echo "📚 Installation des dépendances..."
pip install -q -r requirements.txt

# Créer .env s'il n'existe pas
if [ ! -f ".env" ]; then
    echo "⚙️  Création du fichier .env..."
    cp .env.example .env
    echo ""
    echo "⚠️  IMPORTANT: Mettez à jour .env avec votre ANTHROPIC_API_KEY"
    echo "   Obtenir une clé: https://console.anthropic.com"
    echo ""
    read -p "Appuyez sur Entrée après avoir mis à jour .env..."
fi

# Vérifier la clé API
if ! grep -q "sk_" .env; then
    echo "❌ Clé API manquante dans .env"
    exit 1
fi

echo ""
echo "🎉 Configuration OK!"
echo "================================"
echo ""
echo "🌐 Lancement du serveur..."
echo "   Accédez à: http://localhost:8000"
echo ""
echo "💡 Commandes utiles:"
echo "   - Swagger UI: http://localhost:8000/api/docs"
echo "   - ReDoc: http://localhost:8000/api/redoc"
echo ""
echo "Appuyez sur Ctrl+C pour arrêter"
echo ""

# Lancer le serveur
python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
