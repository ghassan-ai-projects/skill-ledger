# SkillLedger Implementation Tracker

**Status:** Phase 1 Complete  
**Date:** 2026-06-10  
**Owner:** Codex

## Goal

Make SkillLedger work for a few realistic agent-to-agent scenarios, using test-driven development, while keeping a restartable progress log in this file.

## Constraints

- Build on the current Rails API rather than redesigning the entire system at once.
- Prefer end-to-end scenarios over abstract refactors.
- Use tests first for each scenario.
- Keep notes here so work can resume cleanly after interruption.

## Target Scenarios

### Scenario 1: Escrowed skill execution completes successfully

**Story:**  
An agent buyer purchases a deterministic skill from another agent. Funds move into escrow first. After successful completion, escrow is released to the author, the ledger records settlement once, and execution state becomes `completed`.

**Why this matters:**  
This is the minimum credible happy path for the product thesis.

**TDD slices:**
- [x] Add tests for pending execution creation with escrow debit
- [x] Add tests for successful execution completion
- [x] Fix service/controller/routes to support the completion path
- [x] Verify ledger/account balances are correct and not double-settled

### Scenario 2: Failed execution refunds buyer and slashes author stake safely

**Story:**  
An agent buyer purchases a skill, execution fails, buyer gets escrow refunded, author stake is slashed from reserved stake, execution becomes `failed`, and balances never go negative.

**Why this matters:**  
This is the core trust and accountability mechanism.

**TDD slices:**
- [x] Add tests for failing only pending executions
- [x] Add tests for refund + slash behavior from escrow and locked stake
- [x] Add account invariants for `escrow_balance` and `locked_stake`
- [x] Verify ledger entries and state transitions

### Scenario 3: Agents discover and invoke skills through an MCP-style interface

**Story:**  
An agent can discover available skills as callable tools and invoke a skill using an MCP-style request/response contract instead of ad hoc marketplace-only endpoints.

**Why this matters:**  
This is the most direct path to agent interoperability.

**TDD slices:**
- [x] Define minimal MCP-style JSON-RPC contract for tool discovery and invocation
- [x] Add request tests for listing tools
- [x] Add request tests for invoking a tool
- [x] Route invocation into the execution flow

## Current Findings

- Execution flow now supports `pending -> completed` and `pending -> failed`.
- Completion and failure are restricted to the skill author at the controller layer.
- A minimal MCP-style endpoint now exposes skill discovery and skill invocation.
- Toolchain execution still requires explicit use of Ruby 3.3.11 / Bundler 4.0.12 in this environment.

## Progress Log

### 2026-06-10

- [x] Inspected current execution, routing, and test baseline
- [x] Identified that the current escrow implementation is incomplete
- [x] Created this tracker
- [x] Stabilized a working Rails test command under Ruby 3.3.11 / Bundler 4.0.12
- [x] Wrote failing tests for Scenario 1 and Scenario 2
- [x] Implemented escrow creation, completion, and failure flows
- [x] Added account invariants for `locked_stake` and `escrow_balance`
- [x] Added an MCP-style JSON-RPC endpoint for tool discovery and invocation
- [x] Updated stale tests to match current authenticated actor semantics
- [x] Verified the full test suite passes: `RAILS_ENV=test PARALLEL_WORKERS=1 ~/.rbenv/versions/3.3.11/bin/ruby -S bundle _4.0.12_ exec ~/.rbenv/versions/3.3.11/bin/ruby bin/rails test`

## Remaining Follow-Ups

- Document the MCP endpoint contract in the API docs / README.
- Decide whether refunds should also create an explicit ledger entry in addition to slash events.
- Resolve the Bundler stderr noise caused by the local shell environment leaking the system Ruby while tests still complete successfully.

## Resume From Here

If work stops unexpectedly, resume with:

1. Extend the MCP contract beyond `tools/list` and `tools/call`.
2. Decide whether execution completion/failure should be driven by webhooks, worker callbacks, or explicit author actions only.
3. Document the new lifecycle and wire it into public API docs.
