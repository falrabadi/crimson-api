# Crimson.Auth

The **identity provider** for the Crimson platform. It owns user accounts and is
the single source of truth for *who a caller is*. It handles **account creation,
authentication, and token issuance** — the "passport office" that other services
trust.

## Responsibilities (scope discipline)

This service is deliberately kept small and security-focused. It owns identity
and credentials — **not** rich user profile data.

| ✅ Owns | ❌ Does NOT own (belongs to a future `Crimson.Profile`/resource service) |
|---|---|
| email + password hash | display name, avatar, bio, preferences |
| account lifecycle: register, (planned) verify email, reset/change password | addresses, billing, app settings |
| **coarse** roles/scopes baked into token claims (e.g. `user`, `admin`) | domain data |
| refresh tokens, (planned) revocation/blacklist | fine-grained authorization decisions |

**AuthN vs AuthZ:** this service answers *authentication* (who you are) and
**issues** coarse role claims. **Fine-grained authorization** ("can this user
edit *this* order?") is enforced by each resource service using those claims —
not here.

## The auth model (how it's meant to work)

- **Asymmetric JWTs.** This service signs access tokens with a *private* key;
  anyone can verify them with the *public* key published at
  `GET /.well-known/jwks.json`. (Planned — see Status.)
- **Local validation, not phone-home.** Downstream C# services consume the
  `Crimson.Auth.Sdk` NuGet package (planned), which fetches + **caches** the
  JWKS public keys and validates each request's token *in-process*. They do not
  call this service on every request — that's the whole point of JWKS (scales,
  and downstream services keep working even if auth is briefly down).
- **Short-lived access + long-lived refresh.** Access tokens expire fast
  (minutes); a refresh token exchanges for a new access token. Immediate
  revocation (logout-before-expiry) is handled by a Redis blacklist (planned).
- **The ecosystem:** this service + `Crimson.Auth.Sdk` (backend NuGet, local
  token validation) + `@crimson/auth` (frontend npm, a client that calls this
  service for login/refresh/logout/userinfo).

## Status

**Done**
- `POST /register`, `POST /login` (credential verification)
- EF Core 10 + PostgreSQL persistence (`users` table, unique email index)
- Password hashing via the framework's `PasswordHasher<T>` (PBKDF2)
- `GET /health`; `InitialCreate` EF migration; unit/integration tests

**Planned (next)**
- JWT access + refresh **token issuance** on login
- Asymmetric signing key + `GET /.well-known/jwks.json`
- `POST /refresh`, `POST /logout` + Redis revocation blacklist
- `GET /me`; email verification & password reset
- The `Crimson.Auth.Sdk` consumer package

## Endpoints

| Method | Route | Purpose | Status |
|---|---|---|---|
| POST | `/register` | create an account | ✅ |
| POST | `/login` | verify credentials → (will return) tokens | ✅ creds / ⏳ tokens |
| POST | `/refresh` | exchange refresh token for a new access token | ⏳ |
| POST | `/logout` | revoke the current token (blacklist) | ⏳ |
| GET | `/me` | current user from the token | ⏳ |
| GET | `/.well-known/jwks.json` | public keys for token verification | ⏳ |
| GET | `/health` | liveness/readiness probe | ✅ |

## Layout

```
Crimson.Auth/
├── src/
│   ├── Controllers/    HTTP endpoints (thin — delegate to Services)
│   ├── Services/       AuthService: register/login logic, the business rules
│   ├── Models/         User entity + request/response DTOs
│   ├── Data/           AuthDbContext + design-time factory (for `dotnet ef`)
│   ├── Migrations/     EF Core migrations (the Postgres schema)
│   ├── Middleware/     (empty for now)
│   ├── Config/         (empty for now)
│   └── Program.cs      DI wiring + pipeline
├── tests/              xUnit; SQLite in-memory for service tests, WebApplicationFactory for endpoints
├── Dockerfile          multi-stage; build context is the REPO ROOT (shared /packages + global.json)
└── docker-compose.yml  this service + postgres/redis (host port 5001 → container 8080)
```

## Conventions & decisions specific to this service

- **`net10.0`**, nullable + implicit usings on; controller-based (not minimal API).
- **`PasswordHasher<T>` comes from the ASP.NET Core shared framework** — do *not*
  add the `Microsoft.Extensions.Identity.Core` package (it's redundant; triggers NU1510).
- **Emails are normalized** (trimmed + lowercased) before storage/lookup; the
  unique index is on that normalized value.
- **No account enumeration:** `/login` returns the *same* generic
  "Invalid email or password" whether the account is unknown or the password is
  wrong.
- **No in-app HTTPS redirect.** TLS terminates at the cluster ingress; the
  container speaks plain HTTP on `8080`.
- Secrets (`appsettings.{Staging,Production}.json`) are gitignored; only
  `*.example.json` templates are committed. Real config is injected at deploy
  time via env vars / k8s secrets.

## Local development

```bash
# Build / test the whole solution from the repo root
dotnet build
dotnet test

# Add an EF migration (dotnet-ef is pinned as a local tool in .config/)
dotnet tool restore
dotnet ef migrations add <Name> --project services/Crimson.Auth/src

# Run locally with its Postgres + Redis (needs Docker)
docker compose --env-file infra/.env -f infra/docker-compose.yml -f services/Crimson.Auth/docker-compose.yml up --build
```
