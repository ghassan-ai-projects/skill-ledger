# Vision Correction Decision — 2026-06-10

**Status:** Accepted  
**Branch for current implementation snapshot:** `codex/hosted-exec-baseline`  
**Snapshot commit:** `13aef09`

## Decision

SkillLedger is **not** a hosted skill execution platform.

SkillLedger **is** a:
- verified skill registry
- purchase and acquisition layer
- author accountability layer
- agent-facing discovery and delivery protocol

The buyer agent should acquire the skill from SkillLedger and execute it on the buyer side.

## Why This Decision Was Needed

The repository drifted toward the wrong operating model:
- skill purchase created an execution on our platform
- the platform held escrow around runtime execution
- the platform completed or failed executions
- MCP was moving toward remote tool invocation on SkillLedger

That model conflicts with the intended scope:
- skills are authored elsewhere
- skills are verified before publication
- buyers obtain the skill for a price
- buyers execute locally
- authors are accountable for what they published

## Correct Product Statement

SkillLedger is a **verified skill acquisition and accountability layer for agents**.

Authors publish skill artifacts and metadata. SkillLedger verifies the published artifact before public listing. Buyer agents discover skills, pay to acquire them, receive the skill package and verification metadata, and execute the skill locally. Authors are rewarded for purchases and remain accountable for faulty or misrepresented skills.

## What This Changes

### Keep

- accounts
- skills
- pricing
- stake/accountability concept
- ledger/audit concept
- API authentication
- MCP/discovery direction

### Change

- execution becomes acquisition or usage receipt, not hosted runtime
- verification moves to publication-time, not platform-side runtime completion
- settlement should be tied to purchase/acquisition rules, not our system deciding if remote work succeeded
- MCP should expose discovery, verification, purchase, and acquire flows

### Stop Doing

- building built-in hosted skills as the primary product direction
- treating SkillLedger as the place where the skill itself runs
- expanding remote runtime orchestration before the acquisition model is correct

## Repository Handling

The current hosted-execution implementation is preserved on:
- branch: `codex/hosted-exec-baseline`
- commit: `13aef09`

The clarified refactor work starts from:
- branch: `codex/clarified-vision-refactor`

## Immediate Refactor Goal

Refactor the codebase toward:
- `Skill`
- `SkillVersion`
- `SkillArtifact`
- `SkillVerification`
- `Purchase`
- `LedgerEntry`
- optional `UsageReceipt` or `Dispute`

instead of centering the system around hosted `Execution`.
