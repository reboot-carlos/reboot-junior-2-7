#!/bin/bash

# Script de démarrage pour Zachar IA API

echo "🚀 Démarrage de Zachar IA..."
echo ""

# Vérifier si Python est installé
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 n'est pas installé"
    exit 1
fi

# Vérifier si les dépendances sont installées
if ! python3 -c "import fastapi" 2>/dev/null; then
    echo "📦 Installation des dépendances..."
    pip install -r requirements.txt
    echo ""
fi

# Démarrer l'application
echo "✅ L'application démarre..."
echo "📍 Accès : http://localhost:8000"
echo "📚 Documentation : http://localhost:8000/api/docs"
echo ""
echo "Appuie sur Ctrl+C pour arrêter"
echo ""

python3 -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
