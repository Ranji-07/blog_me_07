# Developer Portfolio

This repo contains a local-first portfolio app with:

- `frontend/`: active Flutter Web rebuild
- `frontendref/`: legacy frontend kept for reference during the redesign
- `backend/`: FastAPI backend

## Local Scope

The project has been trimmed for web UI development and local API work.

- Frontend: Flutter Web
- Backend: FastAPI
- Database: local SQLite file at `backend/portfolio_dev.db`

## Run Locally

Backend:

```bat
cd backend
py -3.12 -m venv .venv312
.\.venv312\Scripts\pip install -r requirements.txt
.\.venv312\Scripts\python -m app.init_db
.\start-local.bat
```

Frontend:

```bat
cd frontend
C:\flutter\bin\flutter.bat pub get
.\start-local.bat
```

Reference frontend:

```bat
cd frontendref
C:\flutter\bin\flutter.bat pub get
.\start-local.bat
```

Default local URLs:

- Frontend: `http://127.0.0.1:3000`
- Backend: `http://127.0.0.1:8000`
- API docs: `http://127.0.0.1:8000/docs`

## Deployment Notes

- The backend now includes `backend/render.yaml` and `backend/Procfile`.
- Hosted admin email links use `APP_BASE_URL`.
- Hosted frontend origins should be added to `CORS_ALLOW_ORIGINS`.
- The Flutter frontend now supports `--dart-define=API_BASE_URL=...` so you can point it at local or hosted backend without editing source.
