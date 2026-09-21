@echo off
call C:\flutter\bin\flutter.bat run -d web-server --web-port 3000 --web-hostname 127.0.0.1 --dart-define=API_BASE_URL=http://127.0.0.1:8000
