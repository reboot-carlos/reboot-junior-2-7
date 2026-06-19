@echo off
REM Script de démarrage pour Zachar IA API (Windows)

echo 🚀 Démarrage de Zachar IA...
echo.

REM Vérifier si Python est installé
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python n'est pas installé ou n'est pas dans le PATH
    exit /b 1
)

REM Créer et activer le virtual environment
if not exist venv (
    echo 📦 Création du virtual environment...
    python -m venv venv
)

REM Activer le virtual environment
call venv\Scripts\activate.bat

REM Installer les dépendances
pip install -r requirements.txt >nul 2>&1

REM Démarrer l'application
echo ✅ L'application démarre...
echo 📍 Accès : http://localhost:8000
echo 📚 Documentation : http://localhost:8000/api/docs
echo.
echo Appuie sur Ctrl+C pour arrêter
echo.

python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
pause
