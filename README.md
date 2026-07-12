# Developer Portfolio

This repo contains a local-first portfolio app with:

- `portfolio/`: Flutter Web frontend
- `portfolio-backend/`: FastAPI backend

## Local Scope

The project has been trimmed for web UI development and local API work.

- Frontend: Flutter Web
- Backend: FastAPI
- Database: local SQLite file at `portfolio-backend/portfolio_dev.db`

## Run Locally

Backend:

```bat
cd portfolio-backend
py -3.12 -m venv .venv312
.\.venv312\Scripts\pip install -r requirements.txt
.\start-local.bat
```

Frontend:

```bat
cd portfolio
C:\flutter\bin\flutter.bat pub get
.\start-local.bat
```

Default local URLs:

- Frontend: `http://127.0.0.1:3000`
- Backend: `http://127.0.0.1:8000`
- API docs: `http://127.0.0.1:8000/docs`

## Deployment Notes

- The backend now includes `portfolio-backend/render.yaml` and `portfolio-backend/Procfile`.
- Hosted admin email links use `APP_BASE_URL`.
- Hosted frontend origins should be added to `CORS_ALLOW_ORIGINS`.
- The Flutter frontend now supports `--dart-define=API_BASE_URL=...` so you can point it at local or hosted backend without editing source.
