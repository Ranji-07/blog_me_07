# Portfolio Backend API

FastAPI backend for the portfolio frontend.

## Local Development

The backend now runs locally by default with SQLite.

### Setup

```bat
cd portfolio-backend
py -3.12 -m venv .venv312
.\.venv312\Scripts\pip install -r requirements.txt
.\.venv312\Scripts\python init_db.py
.\start-local.bat
```

### URLs

- API: `http://127.0.0.1:8000`
- Swagger Docs: `http://127.0.0.1:8000/docs`
- ReDoc: `http://127.0.0.1:8000/redoc`

## Deployment Prep

This backend is now prepared for env-based deployment:

- `render.yaml` for Render-style deployment
- `Procfile` for generic process-based hosts
- `APP_BASE_URL` for confirmation links in admin emails
- `CORS_ALLOW_ORIGINS` for hosted frontend domains
- `PORT`, `API_HOST`, and `API_PORT` support for platform-managed ports

### Environment Variables

Minimum production-style settings:

```env
DATABASE_URL=postgresql://...
ADMIN_EMAIL=admin@example.com
ADMIN_API_KEY=replace-with-generated-admin-api-key
EMAIL_DELIVERY_MODE=smtp
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_EMAIL=admin@example.com
SMTP_PASSWORD=replace-with-app-password
APP_BASE_URL=https://your-backend-domain.example.com
CORS_ALLOW_ORIGINS=https://your-frontend-domain.example.com
```

For local-only work you can keep:

```env
DATABASE_URL=sqlite:///./portfolio_dev.db
EMAIL_DELIVERY_MODE=log
```
