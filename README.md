# PDX Hackerspace Library

[![CI](https://github.com/pdxhackerspace/library/actions/workflows/ci.yml/badge.svg)](https://github.com/pdxhackerspace/library/actions/workflows/ci.yml)

A minimal Rails app for tracking physical books that can be loaned at PDX Hackerspace.

## Stack

- Rails 8.1, Ruby 4.0.5
- PostgreSQL 16, Redis 8, Sidekiq 8
- Bootstrap 5.3, Hotwire (Turbo + Stimulus)
- Docker Compose for local dev, test, lint, and production-style deployment
- GitHub Actions CI; Docker images published to GHCR on version tags

## Quick start (Docker)

```bash
cp .env.example .env
docker compose -f docker-compose.dev.yml up --build
```

Open http://localhost:3000 and sign in with the admin credentials from `.env`.

Pending migrations run automatically when the web or Sidekiq containers start (`bin/prepare-database`).

## Compose stacks

| File | Purpose |
|------|---------|
| `docker-compose.dev.yml` | Local dev — bind-mounted code, Postgres + Redis, dev image with Node/Yarn |
| `docker-compose.test.yml` | Test suite — bind-mounted code, ephemeral DB |
| `docker-compose.lint.yml` | RuboCop — bind-mounted code, no database |
| `docker-compose.production.yml` | Production-style — built image, external Postgres via `DATABASE_URL` |

Each stack uses fully qualified container names and network names (`pdxhackerspace-library-*`) to avoid collisions with other Docker projects.

Build helper images when needed:

```bash
docker compose -f docker-compose.test.build.yml build pdxhackerspace-library-test-runner
docker compose -f docker-compose.lint.build.yml build pdxhackerspace-library-lint-rubocop
```

## Tests and lint

```bash
docker compose -f docker-compose.test.yml run --rm pdxhackerspace-library-test-runner
docker compose -f docker-compose.lint.yml run --rm pdxhackerspace-library-lint-rubocop
```

## Authentication

**Local admin** — set `ADMIN_EMAIL`, `ADMIN_PASSWORD`, and optionally `ADMIN_NAME` in `.env`. The account is created on `db:seed` (run automatically in development Docker on startup; run manually in production if needed).

**OIDC (optional)** — set `OIDC_ISSUER`, `OIDC_CLIENT_ID`, and `OIDC_CLIENT_SECRET`, plus `APP_BASE_URL` (or `OIDC_REDIRECT_URI`). SSO appears on the login page when those are present. Admin and editor roles come from granted OAuth scopes (`is_admin`, `is_editor` by default) and are refreshed on each login. Set `OIDC_DEBUG=true` for verbose OIDC logging, including full auth payloads in the Rails log.

## ISBN metadata lookup

When you add or edit a book, the app can fill in title, authors, description, covers, and other fields from the ISBN. It tries [Open Library](https://openlibrary.org/) first (no API key required). If that misses, it falls back to the [Google Books API](https://developers.google.com/books).

### Google Books API key (optional fallback)

Open Library covers most books. The Google Books key is only needed when Open Library has no match.

1. Sign in to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a project (or select an existing one).
3. Open **APIs & Services → Library**, search for **Books API**, and click **Enable**.
4. Open **APIs & Services → Credentials → Create credentials → API key**.
5. Copy the key and add it to `.env`:

   ```bash
   GOOGLE_BOOKS_API_KEY=your-api-key-here
   ```

6. (Recommended) Click **Edit API key** and restrict it:
   - **API restrictions:** limit to **Books API**
   - **Application restrictions:** if you restrict by IP, allow your server’s outbound IP (the app calls Google from Sidekiq, not the browser)

Restart the web and Sidekiq containers after changing `.env`. The Books API is free for typical library catalog use; you do not need billing enabled for normal metadata lookups.

## NFC tag writing

Editors can write NFC tags from a book’s show page.

- **Android:** Chrome on an NFC-capable phone writes a book URL plus JSON metadata (ISBN, title, authors, location). Requires HTTPS in production.
- **iPhone:** Opens a Shortcuts workflow that writes the book URL only. Staff install the shortcut once — see [docs/nfc/ios-shortcut-setup.md](docs/nfc/ios-shortcut-setup.md).

Optional env vars:

```bash
NFC_IOS_SHORTCUT_NAME=Write Library Book Tag
NFC_TAG_MAX_BYTES=496
```

Use NTAG215 tags or larger for Android dual-record writes. Set `APP_BASE_URL` so written URLs use your public host.

## Guest browsing (on-space)

Visitors on your hackerspace network can browse the catalog without signing in. Set comma-separated CIDRs in `.env`:

```bash
GUEST_SUBNET_CIDRS=192.168.1.0/24,10.0.0.0/8
```

When running behind a reverse proxy, Rails only reads forwarded headers when the direct connection comes from a trusted proxy. Add the proxy’s address or subnet to `TRUSTED_PROXIES` — include non-private proxy IPs explicitly (for example a tunnel or load balancer address):

```bash
TRUSTED_PROXIES=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,127.0.0.1,172.225.80.225
```

If the app is only reachable through an internal proxy and the proxy IP varies, you can opt in to trusting forwarded headers without listing every proxy address. Only use this when the app is not directly exposed to the internet:

```bash
TRUST_FORWARDED_HEADERS=true
```

Some proxies set `X-Real-IP` instead of `X-Forwarded-For`; the app reads both when the upstream is trusted. For other headers (for example Cloudflare’s `CF-Connecting-IP`), set `CLIENT_IP_HEADER=CF-Connecting-IP`.

To troubleshoot guest subnet matching and proxy header handling, enable request logging:

```bash
NETWORK_ACCESS_DEBUG=true
```

Each guest-access check logs the on-space decision, resolved client IP, proxy headers (`X-Forwarded-For`, etc.), configured guest CIDRs, and trusted proxies to the Rails log.

On-space guests can view the home page and book details. Checking out, editing, search, and other sections still require login. Off-subnet visitors must sign in to view anything.

## Sentry (optional)

Set `SENTRY_DSN` to enable error reporting for Rails requests and Sidekiq jobs. Disabled in test; off by default when the DSN is unset.

```bash
SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=0
```

`SENTRY_TRACES_SAMPLE_RATE` controls performance tracing (0 disables it). The app release is tagged automatically from `APP_VERSION` / `VERSION`.

## Versioning and releases

The canonical version is in `VERSION`. To release:

1. Bump `VERSION` following semver
2. Commit and tag: `git tag v0.1.0 && git push origin v0.1.0`
3. GitHub Actions builds, tests, and pushes `ghcr.io/<owner>/pdxhackerspace-library:latest`, `:0.1.0`, and `:0`

Images are only built and published on tag pushes, not on every commit.

## Production

Set `DATABASE_URL`, `REDIS_URL`, `SECRET_KEY_BASE`, and `RAILS_MASTER_KEY` in `.env`, then:

```bash
docker compose -f docker-compose.production.yml up -d
```

Pending migrations run automatically when the web or Sidekiq containers start.

Pull a released image instead of building locally:

```bash
export APP_VERSION=0.1.0
# configure compose to use ghcr.io/... image
```
