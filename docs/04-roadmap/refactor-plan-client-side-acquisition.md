# Refactor Plan — Client-Side Skill Acquisition Model

## Objective

Refactor SkillLedger from a hosted-execution simulation into a verified skill acquisition and accountability platform.

## Preservation Strategy

The current implementation is preserved here:
- branch: `codex/hosted-exec-baseline`
- commit: `13aef09`

## Keep / Rewrite / Remove

### Keep

- Rails API skeleton
- authentication via API key
- `Account`
- `Skill`
- ledger and balance mechanics
- tests and CI
- docs structure
- MCP endpoint as a protocol entrypoint

### Rewrite

- skill publication flow
- MCP semantics
- pricing and stake semantics around acquisition
- README and API docs
- reports and analytics to reflect purchases instead of hosted executions

### Remove Or Demote

- hosted-execution-first product story
- runtime-centered `complete` / `fail` semantics as core product behavior
- built-in skill runtime as the primary product direction

## Refactor Sequence

### Phase 1: Documentation Alignment

- [ ] make clarified docs canonical
- [ ] mark old hosted-execution assumptions as historical
- [ ] update README summary

### Phase 2: Domain Model Alignment

- [ ] introduce `SkillVersion`
- [ ] introduce `SkillArtifact`
- [ ] introduce `SkillVerification`
- [ ] introduce `Purchase`
- [ ] decide fate of `Execution`

### Phase 3: Protocol Alignment

- [ ] redesign MCP around skill acquisition
- [ ] define acquisition payload shape
- [ ] define verification metadata shape

### Phase 4: Behavioral Alignment

- [ ] publication verification flow
- [ ] purchase flow
- [ ] acquisition/delivery flow
- [ ] author accountability flow

## Hard Design Questions

These need explicit answers before deeper code refactor:

1. What exactly is a “skill artifact” in MVP terms?
2. How is publication verification performed?
3. What does a buyer receive after purchase?
4. Is the artifact stored directly or referenced externally?
5. What causes a slash in the clarified model?
6. What is the first useful MVP artifact type?

## Recommended First Refactor Target

The first real refactor target should be:

> Replace “execute a skill on our system” with “purchase and acquire a verified skill artifact.”

That is the central move that will pull the rest of the architecture into alignment.
