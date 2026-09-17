# Portfolio Frontend

Active Flutter Web rebuild for the portfolio.

## Local Development

```bat
cd frontend
C:\flutter\bin\flutter.bat pub get
.\start-local.bat
```

Default local backend:

- `http://127.0.0.1:8000`

Override for hosted backend:

```bat
C:\flutter\bin\flutter.bat run -d chrome --dart-define=API_BASE_URL=https://your-backend-domain.example.com
```

To show a temporary public under-construction page while content is being edited, add `--dart-define=SITE_STATUS=under_construction` to the Flutter run or build command. The default `SITE_STATUS=200` shows the portfolio. `/200` and `/under-construction` are preview routes; unknown Flutter routes show the 404 page. A web host must be configured separately to return an actual HTTP 404 response.

The contact form sends the message to the owner and a copy to the visitor through the backend. The visible name separately opens a simple email draft to the owner. Set `--dart-define=ADMIN_CONTACT_EMAIL=address@example.com` to change the draft recipient. On 404 and under-construction pages the name comes from `--dart-define=PORTFOLIO_NAME=YourName` (default: `Tarzan`), so it is available even if the API is down.

Reference app:

- The previous frontend is preserved in `../frontendref`.
