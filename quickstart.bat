@echo off
REM ========================================
REM ZACHAR IA - Quick Start Script (Windows)
REM ========================================

echo.
echo 🚀 Zachar IA - Demarrage Rapide
echo ================================
echo.

REM Verifier Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python non trouve. Installez Python 3.11+
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('python --version') do set PYTHON_VERSION=%%i
echo ✅ %PYTHON_VERSION%

REM Creer venv si necessaire
if not exist "venv" (
    echo 📦 Creation de l'environnement virtuel...
    python -m venv venv
)

REM Activer venv
call venv\Scripts\activate.bat

REM Installer dependances
echo 📚 Installation des dependances...
pip install -q -r requirements.txt

REM Creer .env s'il n'existe pas
if not exist ".env" (
    echo ⚙️  Creation du fichier .env...
    copy .env.example .env
    echo.
    echo ⚠️  IMPORTANT: Mettez a jour .env avec votre ANTHROPIC_API_KEY
    echo    Obtenir une cle: https://console.anthropic.com
    echo.
    pause
)

REM Verifier la cle API
findstr /M "sk_" .env >nul
if errorlevel 1 (
    echo ❌ Cle API manquante dans .env
    pause
    exit /b 1
)

echo.
echo 🎉 Configuration OK!
echo ================================
echo.
echo 🌐 Lancement du serveur...
echo    Acces: http://localhost:8000
echo.
echo 💡 Commandes utiles:
echo    - Swagger UI: http://localhost:8000/api/docs
echo    - ReDoc: http://localhost:8000/api/redoc
echo.
echo Appuyez sur Ctrl+C pour arreter
echo.

python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000

pause
