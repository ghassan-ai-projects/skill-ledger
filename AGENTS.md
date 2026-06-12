# AGENTS.md - SkillLedger

This is the canonical operating guide for coding agents working in this repository.

## What This Project Is

SkillLedger is a Rails 8.1 API-only application for publishing, verifying, listing, purchasing, and locally acquiring agent skill artifacts. It exposes both REST endpoints and an MCP-style JSON-RPC endpoint, uses API-key authentication, stores marketplace and ledger data in Rails models, and treats verified skill artifacts as client-side acquisition packages rather than hosted runtime executions.

The repository currently supports two local development modes:

- default SQLite-backed Rails development
- Docker Compose development with PostgreSQL via `docker-compose.yml`

## For Coding Agents

Before editing:

1. Read this file and [README.md](README.md).
2. Check the worktree with `git status --short`; never overwrite user changes.
3. Read the relevant docs in `documentation/` when behavior, setup, or public interfaces are involved.
4. Run the narrowest useful validation before and after changes. Use `bin/ci` when feasible.

During work:

- Prefer small, reviewable changes over broad rewrites.
- Keep controllers thin and push business rules into services and models.
- Preserve the current product model: verified artifacts are acquired for local execution, not run on a hosted SkillLedger runtime.
- Update docs when setup, behavior, APIs, or contributor workflow changes.
- If human instructions conflict with this file, follow the human and then align the docs.

Default workflow:

1. Think: restate the goal, constraints, relevant files, and risks.
2. Plan: outline the smallest safe change and the checks that should prove it works.
3. Review plan: pause for review when the change is broad, ambiguous, destructive, dependency-changing, or security-sensitive.
4. Write or update tests for production behavior changes.
5. Implement the smallest cohesive change.
6. Validate with the best available local checks.
7. Handoff with changed files, checks run, skipped checks, and residual risk.

## Definition Of Done

- The requested scope is complete without unrelated refactors.
- Production-code changes include or update meaningful Minitest coverage.
- `bin/ci` is preferred when feasible; otherwise run the narrowest relevant checks and say what was skipped.
- Run `git diff --check` for edited code or documentation when feasible.
- Update `README.md`, `documentation/`, `openapi.yaml`, or contributor docs when public behavior or setup changes.
- Do not add secrets or credentials to the repository.
- Final handoff must include validation performed, skipped checks with reasons, and any follow-up risks.

## Project Identity

| Field | Value |
|-------|-------|
| Project name | `skill-ledger` |
| Purpose | Marketplace and entitlement layer for verified agent skill artifacts |
| Language | Ruby 3.3.11 |
| Framework | Rails 8.1 API-only |
| Runtime | Puma, SQLite by default, optional PostgreSQL for Compose development |
| Test framework | Minitest |
| License | MIT |

## Repository Conventions

### Architecture

- `app/controllers/api/v1/`: request parsing, auth, response shaping
- `app/services/`: business workflows and domain rules
- `app/models/`: persistence, validations, associations, small helper methods
- `documentation/`: canonical public docs
- `docs/`: historical planning and research material, not the main public doc set
- `test/`: Minitest coverage for controllers, models, services, and end-to-end flows

### Layer Rules

- Controllers should authenticate, validate params, delegate, and render.
- Services should hold business workflows such as creation, purchase, acquisition, verification, and listing transitions.
- Models should not perform external network calls.
- Artifact verification rules belong in verification services, not controllers.
- Public API changes should stay aligned with `openapi.yaml`.

### Database And Environment

- Default local development uses SQLite.
- PostgreSQL support is enabled when `DATABASE_URL` is present.
- Docker Compose development uses PostgreSQL 16 and should remain documented in `README.md` and `documentation/`.

### Testing Expectations

- Use Minitest, not RSpec.
- Add or update tests for changed production behavior.
- Prefer the smallest targeted test file when the change is scoped.
- For API surface changes, cover success and failure paths.
- For service changes, cover the public method and important domain constraints.

## Quality Gates

Preferred validation commands:

- `bin/rails test`
- `bin/rubocop`
- `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`
- `bin/bundler-audit`
- `bin/ci`

For Compose-based PostgreSQL work, useful commands include:

- `docker compose up --build`
- `docker compose exec app bin/rails test`
- `docker compose down`

If an environment limitation prevents a check, say so explicitly.

## Documentation Rules

- `README.md` is the primary entry point.
- `documentation/` is the detailed public reference set.
- `docs/` contains older project history and should not be repurposed as the canonical public docs directory.
- Keep setup instructions, API descriptions, and container workflows aligned across prose and config.

## Agent Configuration Strategy

- `AGENTS.md` is the cross-agent source of truth.
- `CLAUDE.md`, `GEMINI.md`, and `.github/copilot-instructions.md` should point back here instead of duplicating rules.
- Keep durable repository conventions in files, not chat history.
- Never store secrets, local machine paths, or private data in agent instruction files.
