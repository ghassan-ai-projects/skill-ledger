# Configuration

## Runtime Defaults

SkillLedger is a Rails API-only application. The default configuration is intentionally minimal for local work.

## Ruby And Bundler

- Ruby version: `3.3.11`
- Bundler version in lockfile: `4.0.12`

## Database Configuration

Database settings live in [config/database.yml](../config/database.yml).

The repository now supports two development modes:

- default local SQLite without extra environment variables
- PostgreSQL when `DATABASE_URL` is set

### Development

- `storage/development.sqlite3`

### Test

- `storage/test.sqlite3`
- or PostgreSQL when `TEST_DATABASE_URL` is set

### Production

The production config uses SQLite-backed databases for:

- primary data
- cache
- queue
- cable

Files are stored under `storage/` by default.

## PostgreSQL Development Via Compose

The included [docker-compose.yml](../docker-compose.yml) uses:

- database name: `skill_ledger_development`
- username: `skill_ledger`
- password: `skill_ledger`
- container hostname: `db`

The app container injects:

- `RAILS_ENV=development`
- `DATABASE_URL=postgres://skill_ledger:skill_ledger@db:5432/skill_ledger_development`

## Authentication

Authentication is request-based and uses:

- header: `X-API-Key`
- model field: `accounts.api_key`

API keys are generated automatically for new accounts.

## Pagination And Sorting Defaults

These defaults are enforced in [app/controllers/api/v1/base_controller.rb](../app/controllers/api/v1/base_controller.rb):

- default page size: `20`
- maximum page size: `100`
- default sort: `created_at desc`
- allowed sort columns for skills index: `price`, `name`, `created_at`

## Artifact Verification Expectations

Artifacts are stored as JSON manifests and currently support the `mcp_tool_manifest` type.

Required manifest fields:

- `name`
- `description`
- `version`
- `runtime`
- `entrypoint`
- `input_schema`
- `output_schema`

The current verifier also requires:

- `runtime` equal to `client`
- checksum consistency
- valid bundled file objects when `files` is present

## OpenAPI And Swagger

- OpenAPI source: [openapi.yaml](../openapi.yaml)
- mounted docs UI path: `/api-docs`

## CI

GitHub Actions currently runs:

- Bundler audit
- Brakeman
- RuboCop
- Rails tests

See [.github/workflows/ci.yml](../.github/workflows/ci.yml).
