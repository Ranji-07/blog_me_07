@echo off
set PYTHONUTF8=1
if "%DATABASE_URL%"=="" set DATABASE_URL=sqlite:///./portfolio_dev.db
if "%EMAIL_DELIVERY_MODE%"=="" set EMAIL_DELIVERY_MODE=log
if "%EMAIL_OUTBOX_DIR%"=="" set EMAIL_OUTBOX_DIR=.\dev_outbox
if not exist ".\.venv312\Scripts\python.exe" (
  echo Missing backend virtual environment at .\.venv312
  echo Run setup-local.bat first.
  exit /b 1
)
call .\.venv312\Scripts\python.exe init_db.py
call .\.venv312\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000
