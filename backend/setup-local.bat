@echo off
set PY312=C:\Users\ranji\AppData\Local\Programs\Python\Python312\python.exe

if not exist "%PY312%" (
  echo Python 3.12 not found at:
  echo %PY312%
  echo Install Python 3.12 or update this script with your Python path.
  exit /b 1
)

if not exist ".\.venv312\Scripts\python.exe" (
  echo Creating virtual environment...
  call "%PY312%" -m venv .venv312
)

echo Installing backend dependencies...
call .\.venv312\Scripts\python.exe -m pip install -r requirements.txt

echo Backend setup complete.
echo Next run: start-local.bat
