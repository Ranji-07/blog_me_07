# Portfolio Frontend

Static Flutter web portfolio. Public content is bundled from
[`config/portfolio.json`](config/portfolio.json), so it can be hosted without
the FastAPI backend.

## Local Development

```bat
cd frontend
C:\flutter\bin\flutter.bat pub get
.\start-local.bat
```

The public pages make no network request to the backend. The contact form
opens a prefilled message in the visitor's configured email app using
`mailto:`.

## GitHub Pages deployment

1. Push this repository to GitHub with `main` as its deployment branch.
2. In **GitHub → Settings → Pages**, set **Source** to **GitHub Actions**.
3. Push a change to `main`. The included workflow builds `frontend/` and
   publishes it.
4. The first deployment URL is shown in **Actions** and **Settings → Pages**.

The workflow supports a GitHub project site such as
`https://username.github.io/repository-name/`. For a custom domain later,
change the workflow `--base-href` value to `/` and configure the domain in
GitHub Pages.

## Local release build

```bat
cd frontend
.\build-static.bat /
```

For a GitHub project site, use the repository name as the base path:

```bat
.\build-static.bat /repository-name/
```

The release output is `frontend/build/web/`.

To show a temporary public under-construction page while content is being edited, add `--dart-define=SITE_STATUS=under_construction` to the Flutter run or build command. The default `SITE_STATUS=200` shows the portfolio. `/200` and `/under-construction` are preview routes; unknown Flutter routes show the 404 page. A web host must be configured separately to return an actual HTTP 404 response.

The contact form sends the message to the owner and a copy to the visitor through the backend. The visible name separately opens a simple email draft to the owner. Set `--dart-define=ADMIN_CONTACT_EMAIL=address@example.com` to change the draft recipient. On 404 and under-construction pages the name comes from `--dart-define=PORTFOLIO_NAME=YourName` (default: `Tarzan`), so it is available even if the API is down.

Reference app:

- The previous frontend is preserved in `../frontendref`.
