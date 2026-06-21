# Cosmos - Project Overview

Cosmos is a portfolio project demonstrating full-stack architecture, containerization, CI/CD pipelines, and the full SDLC. It consists of three repositories, all located under `C:/Code/` (`/mnt/c/Code/` in WSL).

## Repositories

| Repo | Path | Purpose |
|---|---|---|
| `cosmos-api` | `/mnt/c/Code/cosmos-api` | C# backend monorepo — all services and shared packages |
| `cosmos-ui` | `/mnt/c/Code/cosmos-ui` | React/TypeScript frontend monorepo — all apps and shared packages |
| `cosmos-schema` | `/mnt/c/Code/cosmos-schema` | OpenAPI contracts — auto-synced from backend services |
| `cosmos-infra` | `/mnt/c/Code/cosmos-infra` | IaC — Terraform (Hetzner VPS), k3s, Kustomize manifests, deploy pipelines |

## Architecture

```
cosmos-api (C# / ASP.NET Core)
    ↕ OpenAPI contract (cosmos-schema)
cosmos-ui (React / TypeScript)
```

Each backend service auto-publishes its OpenAPI spec to `cosmos-schema` on CI merge. The frontend consumes those specs to generate typed API clients.

## cosmos-api

**Stack:** C# / ASP.NET Core 8, PostgreSQL, Redis
**Solution file:** `cosmos-api.sln` — ties all projects together, one `dotnet build` builds everything

```
/cosmos-api
  /services         ← independently deployable ASP.NET Core services
  /packages         ← shared C# class libraries (NuGet-style, internal)
  /infra
    docker-compose.yml    ← spins up postgres + redis locally
  /scripts
    create-service.bat    ← scaffolds a new service (run from repo root)
    create-package.bat    ← scaffolds a new shared package (run from repo root)
    run-service.bat       ← runs a service + infra via docker compose (run from repo root)
  /.github
    /workflows
      ci.yml              ← runs on every push/PR (restore, build, test)
      cd-staging.yml      ← manual dispatch; deploys master to staging
      cd-prod.yml         ← manual dispatch; deploys master to production
  cosmos-api.sln
```

### Services

Each service lives under `/services/Cosmos.[Name]/` and follows this structure:

```
/services/Cosmos.[Name]/
  /src
    /Controllers
    /Services
    /Models
    /Middleware
    /Config
    Program.cs
    appsettings.json
    appsettings.Development.json
    appsettings.Staging.example.json      ← template only; real values via k8s secrets
    appsettings.Production.example.json   ← template only; real values via k8s secrets
    Cosmos.[Name].csproj
  /tests
    Cosmos.[Name].Tests.csproj
  Dockerfile
  docker-compose.yml    ← service-specific compose, merged with infra/docker-compose.yml at runtime
```

### Packages

Shared internal libraries live under `/packages/Cosmos.[Name]/`:

```
/packages/Cosmos.[Name]/
  /src
    Cosmos.[Name].csproj
  /tests
    Cosmos.[Name].Tests.csproj
```

### Local Development

```bash
# Start infrastructure only (postgres + redis)
# NOTE: --env-file is required because the .env lives in infra/, not the repo root.
# Docker Compose only auto-loads .env from the current directory.
docker compose --env-file infra/.env -f infra/docker-compose.yml up -d

# Run a specific service + its infrastructure
scripts\run-service.bat

# Build entire solution
dotnet build

# Run all tests
dotnet test

# Scaffold a new service (run from repo root)
scripts\create-service.bat

# Scaffold a new package (run from repo root)
scripts\create-package.bat
```

### Environments

Single long-lived branch (`master`) plus feature branches. Deploys are **manual**
(`workflow_dispatch`) — there is no per-environment branch. CI must pass first, then
you click "Run workflow" to promote.

| Environment | Source | Trigger |
|---|---|---|
| Development | local | `docker compose` via `scripts/run-service.bat` |
| Staging | `master` | manual dispatch of `cd-staging.yml` |
| Production | `master` | manual dispatch of `cd-prod.yml` |

## cosmos-ui

**Stack:** React, TypeScript, pnpm workspaces

```
/cosmos-ui
  /apps             ← deployable React applications
  /packages         ← shared internal npm packages (e.g. @cosmos/auth)
```

## cosmos-schema

Stores OpenAPI YAML specs auto-published by backend services on CI merge. Frontend uses these to generate typed API clients.

```
/cosmos-schema
  /openapi
    [service-name].yaml
```

## Key Conventions

- All C# projects are prefixed with `Cosmos.` (e.g. `Cosmos.Auth`, `Cosmos.Shared.Contracts`)
- All frontend packages are scoped to `@cosmos/` (e.g. `@cosmos/auth`)
- Each service has its own `Dockerfile` for independent containerization
- Secrets are never committed. `appsettings.Staging.json` / `appsettings.Production.json` are gitignored; only `*.example.json` templates are tracked
- Real Staging/Production config is supplied at deploy time via k8s secrets / env vars (see `cosmos-infra`)
- Each service's Docker build uses the **repo root** as its build context (via a root `.dockerignore`) so shared `/packages` references resolve
