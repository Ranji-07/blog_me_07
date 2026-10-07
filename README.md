# Developer Portfolio

Public static portfolio: <https://ranji-07.github.io/blog_me_07/>

This repository contains two deployable parts:

- `frontend/`: Flutter Web public portfolio, deployed as a static GitHub Pages
  site from `frontend/config/portfolio.json`.
- `backend/`: separate FastAPI, database, CMS, asset, analytics, and admin
  service for local development or a future backend deployment.

The public portfolio does not call the backend. Its contact form opens a
prepared email draft in the visitor's configured mail application.

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

## Static hosting

GitHub Pages builds `frontend/` through `.github/workflows/deploy-static.yml`.
The expected project URL is <https://ranji-07.github.io/blog_me_07/>. For
deployment instructions and troubleshooting, read `frontend/README.md`.

## Project status

- Current product and outstanding decisions: `docs/PROJECT_STATUS.md`
- Completed backend phase record: `bd_phase.md`
- Backend setup and API reference: `backend/README.md`
