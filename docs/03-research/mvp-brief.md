# Project: SkillLedger — MVP
**Status:** Complete

## Scope
A Rails app that lets agent authors publish skills with a staked bond, and other agents discover, purchase, and verify execution. The "blockchain" is a local ledger (database-backed, not real crypto). Everything runs on one server. No external APIs.

## Constraints
- Ruby on Rails (no other frameworks)
- Private repo under gh-assan on GitHub
- No real blockchain, no crypto, no external integrations
- The "ledger" is a local DB table that records transactions
- Simplicity first — if you're deciding between two approaches, pick the simpler one
- Modular code — skills, ledger, verification, accounts should be separate Rails concerns/modules

## Anti-Scope (will NOT build)
- No real crypto/blockchain integration
- No TEE or ZK proofs
- No external API calls
- No payment processor integration
- No user authentication system (single-tenant MVP)
- No multi-tenant, no permissions, no roles

## What It Does

1. **Account** — each agent has an account with a balance (in-memory, seeded)
2. **Ledger** — every transfer (stake, payment, slash) is recorded as a ledger entry
3. **Skills** — authors create skills with a name, description, stake amount, and price per call
4. **Execute** — a buyer agent calls a skill; the ledger records the payment; the skill "runs" (stubbed — just logs)
5. **Trust** — if execution fails, the author's stake is slashed and the buyer is refunded
6. **Reports** — simple stats: total skills, total executions, total slashed, ledger balance

## Phases

### Phase 1: Core Data Model + Ledger
- Account model (name, balance)
- LedgerEntry model (from_account, to_account, amount, type, timestamp)
- Skill model (name, description, author, stake_amount, price_per_call)
- Execution model (skill, buyer, status, result, timestamp)
- Migration + seeds (seed 3-5 agents with balances)

### Phase 2: API + Execution Flow
- POST /skills — create a skill
- GET /skills — list all skills
- POST /skills/:id/execute — execute a skill (checks balance, stakes author, creates execution record)
- GET /executions — list executions
- GET /ledger — list ledger entries

### Phase 3: Trust/Verification
- If execution status is "failed" → slash author's stake, refund buyer
- GET /reports — summary stats (total skills, executions, slashed amounts)

### Phase 4: Polish
- Error handling
- Basic request logging
- README with setup instructions
- Simple test coverage

## Success Criteria
- [ ] Rails app starts with `rails s`
- [ ] Seed data creates 3-5 agents with balances
- [ ] Can create a skill via POST /skills
- [ ] Can execute a skill via POST /skills/:id/execute
- [ ] Execution failure triggers stake slash + buyer refund
- [ ] Ledger shows every transaction
- [ ] All tests pass
- [ ] README explains setup + API

## Handoff To
Agent: Qwen
Protocol: protocols/coding-project-protocol.md
Qwen rules: .qwenrules
GitHub: gh-assan org, private repo named "skill-ledger"


## Notes
Brief used to build skill-ledger project
