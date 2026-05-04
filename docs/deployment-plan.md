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

If `./scripts/configure_github_pages.sh` returns:

```text
Resource not accessible by personal access token
```

edit the GitHub token and confirm `healthybrain.ai` has `Pages: read and write`.
Repository admin access alone is not sufficient for the Pages API.

If it returns:

```text
Invalid cname
The custom domain `healthybrain.ai` is already taken.
```

verify `healthybrain.ai` in GitHub account settings:

1. Open `https://github.com/settings/pages`.
2. Under `Verified domains`, add `healthybrain.ai`.
3. GitHub will show a TXT record name and value.
4. Add that TXT record in Porkbun.
5. Keep the TXT record after verification.

This repository includes a helper for step 4:

```bash
GITHUB_PAGES_VERIFY_VALUE="<value from GitHub>" ./scripts/add_github_pages_verification_txt.sh
```

Then confirm DNS propagation:

```bash
dig _github-pages-challenge-wolfgang-ganglberger.healthybrain.ai +nostats +nocomments +nocmd TXT
```

After GitHub verifies the domain, re-run:

```bash
./scripts/configure_github_pages.sh
```

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

The DNS automation removes Porkbun's default wildcard record (`*.healthybrain.ai`
to `pixie.porkbun.com`) because wildcard records increase GitHub Pages takeover
risk and can interfere with the GitHub verification TXT lookup.

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
