# HealthyBrain.ai Holding Page

This repository contains the static holding page for `https://healthybrain.ai`.

The domain should not redirect to `wolfgangganglberger.com` yet. It should
remain a clean, separate future-project domain with one lightweight page linking
back to the main personal site.

## Local Preview

```bash
python3 -m http.server 8000
```

Then open `http://127.0.0.1:8000`.

## Deployment

The intended deployment is GitHub Pages with `healthybrain.ai` as the custom
domain.

See `docs/deployment-plan.md` for GitHub and Porkbun setup.

## Automation Credentials

Scripts load credentials from `.env.local` if present. If not present, they also
try `../wolfgang-ganglberger.github.io/.env.local` so the same local credentials
can be reused.

```bash
cp .env.local.example .env.local
./scripts/check_healthybrain_credentials.sh
```
