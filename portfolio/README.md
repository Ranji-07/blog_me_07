# Portfolio Frontend

Flutter Web frontend for the portfolio.

## Local Development

```bat
cd portfolio
C:\flutter\bin\flutter.bat pub get
.\start-local.bat
```

Default local backend:

- `http://127.0.0.1:8000`

Override for hosted backend:

```bat
C:\flutter\bin\flutter.bat run -d chrome --dart-define=API_BASE_URL=https://your-backend-domain.example.com
```
