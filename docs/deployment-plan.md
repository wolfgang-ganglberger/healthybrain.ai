# HealthyBrain.ai Deployment Plan

## Desired End State

- `https://healthybrain.ai` serves the holding page in this repository.
- `https://www.healthybrain.ai` resolves to the same GitHub Pages site and should redirect to the apex domain after GitHub Pages is configured.
- The page links to `https://wolfgangganglberger.com`.
- The domain is not redirected wholesale to the personal homepage.

## GitHub Repository

Recommended repository:

- Owner: `wolfgang-ganglberger`
- Repository: `healthybrain.ai`
- Visibility: public
- GitHub Pages source: `main`, `/ (root)`
- Custom domain: `healthybrain.ai`

Manual steps:

1. Create a new GitHub repository named `healthybrain.ai`.
2. Push this local repository to GitHub.
3. Open repository `Settings` -> `Pages`.
4. Set source to `Deploy from a branch`, branch `main`, folder `/ (root)`.
5. Set custom domain to `healthybrain.ai`.
6. After DNS propagates, enable `Enforce HTTPS`.

## GitHub API Automation

If a GitHub token is configured, run:

```bash
./scripts/configure_github_pages.sh
```

For a fine-grained GitHub token, give this repository:

- `Pages`: read and write
- `Administration`: read and write

If using the same token as the personal website, make sure the token is allowed
to access both repositories.

## Porkbun DNS

Remove conflicting default root and `www` records, then add:

| Type | Host | Answer |
| --- | --- | --- |
| A | `@` | `185.199.108.153` |
| A | `@` | `185.199.109.153` |
| A | `@` | `185.199.110.153` |
| A | `@` | `185.199.111.153` |
| AAAA | `@` | `2606:50c0:8000::153` |
| AAAA | `@` | `2606:50c0:8001::153` |
| AAAA | `@` | `2606:50c0:8002::153` |
| AAAA | `@` | `2606:50c0:8003::153` |
| CNAME | `www` | `wolfgang-ganglberger.github.io` |

API automation:

```bash
./scripts/configure_porkbun_dns.sh
```

Porkbun API access must be enabled for `healthybrain.ai`.

## Credential Setup

Either create `.env.local` in this repository:

```bash
cp .env.local.example .env.local
```

or reuse the existing credentials in:

```text
../wolfgang-ganglberger.github.io/.env.local
```

Then validate:

```bash
./scripts/check_healthybrain_credentials.sh
```

## Verification

After DNS propagates:

```bash
dig healthybrain.ai +noall +answer -t A
dig healthybrain.ai +noall +answer -t AAAA
dig www.healthybrain.ai +noall +answer
curl -I https://healthybrain.ai
curl -I https://www.healthybrain.ai
```

Expected:

- Apex A/AAAA records point to GitHub Pages.
- `www` is a CNAME to `wolfgang-ganglberger.github.io`.
- HTTPS works after GitHub Pages certificate issuance.
