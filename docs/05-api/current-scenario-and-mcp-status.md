# Current Scenario And MCP Status

**Date:** 2026-06-10  
**Status:** Current implementation snapshot

## Covered Scenarios

### 0. Real useful built-in use case: Data Analysis

Covered now:
- `Data Analysis` can run as a real built-in skill through MCP.
- The caller passes a numeric dataset.
- The system returns deterministic summary statistics:
  - `count`
  - `sum`
  - `min`
  - `max`
  - `average`
  - `median`
- The execution is created and settled automatically to `completed`.
- The result is stored in `execution.result`.

What this means:
- The platform now has one actually useful end-to-end skill, not just marketplace plumbing.
- An agent can use the system today for a concrete deterministic analysis task.

### 1. Escrowed execution creation

Covered now:
- An authenticated buyer can execute another agent's skill.
- Buyer funds move from `balance` to `escrow_balance`.
- A new `Execution` record is created with status `pending`.
- No settlement ledger entry is written yet.

What this means:
- Purchase and settlement are now separated.
- The system no longer pays the author immediately at execute time.

### 2. Successful execution completion

Covered now:
- The skill author can mark a pending execution as complete.
- Escrow is released once.
- The author receives the `price_per_call`.
- A single `skill_execution` ledger entry is created.
- The execution status becomes `completed`.

What this means:
- The happy path is now financially consistent.
- Double-settlement is prevented in the current flow.

### 3. Failed execution with slash and refund

Covered now:
- The skill author can mark a pending execution as failed.
- Buyer escrow is refunded back to buyer balance.
- Author `locked_stake` is reduced by `stake_amount`.
- Buyer receives the slashed stake.
- A `slash` ledger entry is created.
- The execution status becomes `failed`.

What this means:
- The core accountability path exists.
- Stake is now treated as reserved capital instead of a loose promise.

### 4. Authenticated actor ownership rules

Covered now:
- Skill creation uses the authenticated account as author.
- Skill execution uses the authenticated account as buyer.
- Only the skill author can complete or fail an execution.

What this means:
- Clients can no longer impersonate another buyer or author by passing IDs in the request body.

### 5. MCP-style skill discovery and invocation

Covered now:
- Agents can discover skills through an MCP-style JSON-RPC endpoint.
- Agents can invoke a skill through a `tools/call` request.
- MCP invocation reuses the same execution flow as the HTTP API.

What this means:
- There is now a first agent-facing interoperability surface, not just marketplace endpoints.

## Scenarios Not Covered Yet

### 1. Automatic completion from real execution results

Not covered:
- No real worker/executor proves that a skill actually ran.
- Completion is still an explicit author-side action.
- There is no trusted callback or machine verification step.

Impact:
- The current system models settlement flow, but not real execution proof.

### 2. Real deterministic skill runtime

Not covered:
- Skills are listed and invoked, but the platform does not yet run real tools like SQL jobs, code execution, or API orchestration.
- MCP invocation currently creates an execution record, not an actual remote computation result.

Impact:
- This is still a controlled product simulation, not a production execution network.

### 3. Dispute process

Not covered:
- No challenge period
- No reviewer/arbitrator flow
- No partial refund flow
- No evidence submission model

Impact:
- Failed vs completed is still a single-authority action, not a dispute-safe protocol.

### 4. Stake lifecycle beyond slash

Not covered:
- No stake unlock flow when a skill is retired
- No stake top-up flow
- No per-skill isolated reserve accounting
- `locked_stake` is account-level, not skill-level

Impact:
- Stake is reserved, but still coarse-grained.

### 5. MCP completion/failure actions

Not covered:
- MCP only supports discovery and initial invocation.
- There are no MCP methods yet for:
  - execution status lookup
  - completion
  - failure
  - execution history
  - review submission

Impact:
- MCP is currently an entrypoint, not a full agent protocol surface.

### 6. Rich MCP tool contracts

Not covered:
- Tool schemas are minimal.
- `tools/list` exposes empty input schemas.
- No output schema is published.
- No parameterized skill arguments are supported.

Impact:
- Agents can discover and call skills, but the contracts are not yet rich enough for serious interoperability.

### 7. Async execution lifecycle for agents

Not covered:
- No polling endpoint shaped for MCP clients
- No event stream
- No callback contract for execution updates through MCP
- No resumable long-running task protocol

Impact:
- Long-running agent workflows are not yet modeled properly.

## MCP We Have Now

Current endpoint:
- `POST /api/v1/mcp`

Current request style:
- JSON-RPC-like request envelope
- Authenticated through the same `X-API-Key` mechanism as the rest of the API

Current supported methods:
- `tools/list`
- `tools/call`

### `tools/list`

Returns:
- one tool per skill
- tool name format: `skill.execute.<skill_id>`
- description from the skill description
- lightweight annotations:
  - title
  - author
  - price per call
- richer input schema for built-in `Data Analysis`

### `tools/call`

Accepts:
- tool name like `skill.execute.1`
- currently empty `arguments`

Returns:
- text content summary
- execution object with:
  - `id`
  - `skill_id`
  - `buyer_id`
  - `status`

Behavior:
- for built-in `Data Analysis`:
  - validates numeric input
  - computes deterministic statistics
  - creates and auto-completes the execution
  - stores the result
- for non-built-in skills:
  - creates a normal pending execution through the same escrow flow as the HTTP API

## MCP Still Missing

### Protocol completeness

Missing:
- `tools/get`
- `tools/result`
- execution status lookup method
- execution completion/failure methods
- cancellation semantics

### Skill contract richness

Missing:
- per-skill input schemas
- output schemas
- argument validation per skill
- versioned tool definitions

Current exception:
- `Data Analysis` now has a real input schema and argument validation.

### Agent workflow support

Missing:
- async polling contract
- event delivery / subscription model
- idempotency keys
- correlation IDs across multi-step workflows

### Trust and verification support

Missing:
- proof payloads
- signed execution receipts
- challenge/dispute metadata
- attestation fields

### Platform integration support

Missing:
- SDK wrapper for MCP clients
- OpenAPI/README documentation for MCP
- examples for agent builders

## Bottom Line

The platform now covers the first realistic financial and protocol baseline:
- discover a skill
- buy it
- hold funds in escrow
- settle success correctly
- refund and slash on failure
- expose discovery and invocation through a minimal MCP-style interface

What it does **not** cover yet is the harder second half:
- real execution runtime
- verification
- disputes
- richer MCP contracts
- full agent lifecycle support
