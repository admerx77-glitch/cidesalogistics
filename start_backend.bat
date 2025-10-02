@echo off
REM Inicia el backend FastAPI
cd /d %~dp0
IF NOT EXIST venv (
  py -m venv venv
  call venv\Scripts\activate
  pip install -r backend\requirements.txt
) ELSE (
  call venv\Scripts\activate
)
set PYTHONPATH=%CD%\backend
uvicorn app.main:app --reload --port 8000
@echo off
setlocal
cd /d %~dp0

echo ====== CIDESA Backend (FastAPI) ======

REM 1) Detectar Python
where py >nul 2>nul && set "PYLAUNCHER=py"
if not defined PYLAUNCHER where python >nul 2>nul && set "PYLAUNCHER=python"
if not defined PYLAUNCHER (
  echo [ERROR] No se encontro Python. Instala Python 3.10+ y marca "Add to PATH".
  pause
  exit /b 1
)

REM 2) Validar estructura
if not exist backend\requirements.txt (
  echo [ERROR] No encuentro backend\requirements.txt. Asegurate de estar en la carpeta correcta (CIDESA_MVP).
  pause
  exit /b 1
)

REM 3) Crear venv si no existe
if not exist venv (
  echo Creando entorno virtual...
  %PYLAUNCHER% -m venv venv || (
    echo [ERROR] Fallo al crear venv.
    pause
    exit /b 1
  )
)

REM 4) Activar venv
call "venv\Scripts\activate.bat" || (
  echo [ERROR] No se pudo activar venv. Revisa que exista venv\Scripts\activate.bat
  pause
  exit /b 1
)

REM 5) Instalar dependencias
python -m pip install --upgrade pip
pip install -r backend\requirements.txt || (
  echo [ERROR] Fallo pip install.
  pause
  exit /b 1
)

REM 6) Lanzar FastAPI (app en backend\app\main.py -> app.main:app)
set "PYTHONPATH=%CD%\backend"
python -m uvicorn app.main:app --app-dir backend --reload --port 8000

