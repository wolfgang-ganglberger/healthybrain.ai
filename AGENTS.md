# HealthyBrain.ai Agent Notes

This repository is a small static holding page for `https://healthybrain.ai`.

## Intent

- Keep `healthybrain.ai` separate from the personal website.
- Do not redirect it to `wolfgangganglberger.com` unless explicitly requested.
- Use the page as a clean placeholder for a future brain-health project.
- Link back to `https://wolfgangganglberger.com` for current public identity.

## Deployment Model

- Static files at repository root.
- GitHub Pages source: `main` branch, root folder.
- Custom domain: `healthybrain.ai`.
- DNS provider: Porkbun.

## Operational References

- Deployment plan: `docs/deployment-plan.md`
- Credential template: `.env.local.example`
- Credential validator: `scripts/check_healthybrain_credentials.sh`
- Porkbun DNS automation: `scripts/configure_porkbun_dns.sh`
- GitHub Pages verification TXT helper: `scripts/add_github_pages_verification_txt.sh`
- GitHub Pages automation: `scripts/configure_github_pages.sh`

## Safety

- Never commit `.env.local`.
- Keep this page sparse and non-medical. Do not make diagnostic, treatment, or product claims before the project exists.
