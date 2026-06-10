# Future API Direction

## Purpose

This document describes the intended API direction after the scope clarification.

The current API still reflects hosted-execution assumptions in several places. Those endpoints are part of the current implementation history, not the preferred long-term shape.

## REST Direction

### Discovery

- `GET /api/v1/skills`
- `GET /api/v1/skills/:id`
- `GET /api/v1/skills/:id/versions`
- `GET /api/v1/skills/:id/verification`

### Publication

- `POST /api/v1/skills`
- `POST /api/v1/skills/:id/versions`
- `POST /api/v1/skills/:id/artifacts`
- `POST /api/v1/skills/:id/verify`

### Acquisition

- `POST /api/v1/skills/:id/purchase`
- `GET /api/v1/purchases/:id`
- `POST /api/v1/purchases/:id/acquire`

### Accountability

- `POST /api/v1/purchases/:id/report`
- `POST /api/v1/purchases/:id/dispute`
- `GET /api/v1/authors/:id/reputation`

## MCP Direction

Current MCP should eventually evolve from generic `tools/list` and `tools/call` into protocol messages more directly aligned to skill acquisition.

### Preferred MCP Methods

- `skills/list`
- `skills/get`
- `skills/versions/list`
- `skills/purchase`
- `skills/acquire`
- `skills/verify`

### Why

These methods match the intended product:
- discovery
- verification
- purchase
- delivery

They avoid implying that SkillLedger is the place where the skill runs.

## Artifact Delivery Model

The buyer should receive:
- skill manifest
- version metadata
- checksum or content hash
- verification summary
- artifact payload or retrieval link
- optional usage terms

## Transitional Note

The current API contains execution-oriented endpoints because the repository first evolved as a hosted execution simulation.

Those endpoints should be treated as:
- implementation history
- temporary mechanics
- likely refactor targets

not as the canonical long-term API direction.
