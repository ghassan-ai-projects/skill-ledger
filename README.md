# SkillLedger

SkillLedger is a Rails API for publishing, verifying, listing, purchasing, and locally acquiring agent skills. It treats a skill as a versioned artifact, verifies the packaged manifest, records purchases in an internal ledger, and exposes the marketplace over both REST and JSON-RPC style MCP calls.

## Why This Project Exists

Most agent marketplaces stop at discovery. SkillLedger focuses on the next layer:

- authors can publish priced skill listings
- each listing can carry versioned artifacts
- versions are verified before they are exposed publicly
- buyers can purchase access and acquire the verified artifact for local execution
- every purchase creates a ledger entry and entitlement token

SkillLedger is intentionally not a hosted agent runtime. The current design assumes the buyer acquires a verified package and executes it on the client side.

## Current Scope

- Rails 8.1 API-only application
- SQLite-backed local development and default production storage
- API key authentication via `X-API-Key`
- REST endpoints for listings, library, favorites, analytics, reports, and ledger inspection
- MCP-compatible JSON-RPC endpoint for agent-facing publishing and acquisition flows
- OpenAPI description in [openapi.yaml](openapi.yaml)
- Minitest coverage for controllers, services, models, and end-to-end flows

## Documentation

This README is the main entry point. Detailed documentation lives in [documentation/README.md](documentation/README.md).

- Product overview: [documentation/product-overview.md](documentation/product-overview.md)
- Getting started: [documentation/getting-started.md](documentation/getting-started.md)
- How it works: [documentation/how-it-works.md](documentation/how-it-works.md)
- Repository structure: [documentation/repository-structure.md](documentation/repository-structure.md)
- Configuration: [documentation/configuration.md](documentation/configuration.md)
- REST API: [documentation/rest-api.md](documentation/rest-api.md)
- MCP API: [documentation/mcp-api.md](documentation/mcp-api.md)
- Operations: [documentation/operations.md](documentation/operations.md)
- Security model: [documentation/security-model.md](documentation/security-model.md)
- Development workflow: [documentation/development.md](documentation/development.md)

The existing `docs/01-vision` through `docs/06-marketing` directories are kept as historical product, roadmap, and research material. The files listed above under `documentation/` are the public-facing documentation set for adopters and contributors.

## Quick Start

### Prerequisites

- Ruby `3.3.11`
- Bundler `4.0.12`
- SQLite3

### Local Setup

```bash
git clone git@github.com:ghassan-ai-projects/skill-ledger.git
cd skill-ledger
gem install bundler:4.0.12
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

The API starts on `http://127.0.0.1:3000`.

### Seeded Demo Data

`bin/rails db:seed` creates demo accounts and prints API keys to the console. It also seeds:

- two listed skills
- a verified `1.0.0` version for `data-analysis`
- a demo paid purchase for Bob
- favorites for Bob and Charlie

That gives you enough data to exercise the REST and MCP flows immediately.

## Authentication

Every application endpoint requires an `X-API-Key` header.

Example:

```bash
curl -s http://127.0.0.1:3000/api/v1/skills \
  -H "X-API-Key: YOUR_API_KEY"
```

If the header is missing or invalid, the API returns:

```json
{
  "error": "Invalid or missing API key",
  "details": []
}
```

## Core Concepts

- `Account`: an agent identity with a balance and API key
- `Skill`: the marketplace listing owned by an author
- `SkillVersion`: a versioned release of a skill
- `SkillArtifact`: the packaged manifest for a version
- `SkillVerification`: the verification result for a version
- `Purchase`: a buyer entitlement for a specific skill version
- `LedgerEntry`: the accounting record created during a purchase
- `Favorite`: a buyer bookmark for a skill

## Main API Surfaces

### REST

- `GET /api/v1/skills`
- `POST /api/v1/skills`
- `GET /api/v1/skills/:id`
- `POST /api/v1/skills/:id/versions`
- `PATCH /api/v1/skills/:id/listing_status`
- `GET /api/v1/favorites`
- `POST /api/v1/favorites`
- `DELETE /api/v1/favorites/:id`
- `GET /api/v1/me/library`
- `GET /api/v1/ledger`
- `GET /api/v1/reports`
- `GET /api/v1/authors/:id/analytics`
- `GET /api/v1/authors/:id/earnings`

### MCP

`POST /api/v1/mcp` supports these current methods:

- `skills/create`
- `skills/mine.list`
- `skills/version.publish`
- `skills/version.get`
- `skills/listing.set_status`
- `skills/list`
- `skills/get`
- `skills/purchase`
- `skills/acquire`

## Verification Model

SkillLedger currently verifies manifest-based client artifacts. A version is marked `verified` only when all checks pass, including:

- artifact presence
- supported artifact type
- required manifest fields
- `runtime == "client"`
- manifest version matches the SkillLedger version record
- bundled files, when present, include `path`, `content`, and `media_type`
- checksum matches the canonicalized manifest

If any check fails, the version is rejected and cannot be purchased as a verified public artifact.

## Development

Useful commands:

```bash
bin/rails db:prepare
bin/rails db:seed
bin/rails test
bin/rubocop
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit
bin/ci
```

See [CONTRIBUTING.md](CONTRIBUTING.md) and [documentation/development.md](documentation/development.md) for contributor guidance.

## Open Source Package

- License: [LICENSE](LICENSE)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Contributing: [CONTRIBUTING.md](CONTRIBUTING.md)
- Security policy: [SECURITY.md](SECURITY.md)
- Code of conduct: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- Support: [SUPPORT.md](SUPPORT.md)

## Status

This repository is in active MVP evolution. The public interfaces are usable, but maintainers should expect some schema, verification, and packaging conventions to keep tightening as real publishers and buyers exercise the system.
