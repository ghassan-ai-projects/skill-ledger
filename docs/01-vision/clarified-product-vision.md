# Clarified Product Vision

## One-Sentence Vision

SkillLedger is a **verified skill acquisition and accountability protocol for agents**.

## Core Product Idea

Agents should be able to:
1. discover verified third-party skills
2. pay to acquire those skills
3. receive the skill artifact plus verification metadata
4. execute the skill locally
5. hold the author accountable if the published skill is faulty or misrepresented

## What SkillLedger Is

SkillLedger is:
- a registry of verified skills
- a payment and acquisition layer
- an accountability layer backed by author stake
- an agent-facing discovery and delivery protocol

## What SkillLedger Is Not

SkillLedger is not:
- the runtime where skills execute
- a hosted agent execution platform
- a generic compute marketplace
- a human marketplace UI first

## Primary User Flow

### Author side

1. Author publishes a skill artifact and manifest
2. SkillLedger verifies the skill before public listing
3. Skill becomes discoverable to buyer agents
4. Author earns revenue when agents purchase/acquire the skill

### Buyer side

1. Buyer agent discovers a skill
2. Buyer reviews metadata, verification, author, price, and terms
3. Buyer purchases or acquires the skill
4. Buyer receives artifact, manifest, version, checksum, and verification status
5. Buyer executes the skill locally

## Trust Model

Trust is built around:
- artifact verification before publication
- explicit author identity
- immutable purchase and ledger records
- financial accountability through stake
- dispute/reporting when published skills are bad or deceptive

Trust is **not** built around SkillLedger hosting the runtime itself.

## Scope Boundary

### In scope

- skill metadata and discovery
- artifact packaging and delivery
- author verification and stake
- publication checks
- purchase/acquisition flow
- auditability
- agent protocol integration via MCP or similar

### Out of scope

- executing third-party skills on SkillLedger servers
- general remote compute scheduling
- platform-side determination of every runtime success/failure outcome

## Product Promise

SkillLedger should let an agent say:

> "I can discover a skill, verify who published it, verify what I am getting, pay for it, acquire it, and run it on my own side with confidence about provenance and accountability."

## MVP Success Criteria

An MVP is successful if it can do the following clearly and reliably:

1. Authors can publish a versioned skill artifact
2. The platform verifies the artifact before listing
3. Buyers can discover listed skills programmatically
4. Buyers can pay to acquire a skill
5. Buyers receive the artifact plus manifest and verification metadata
6. The author gets rewarded for acquisition
7. The system keeps a durable accountability trail
