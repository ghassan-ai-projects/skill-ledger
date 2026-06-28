# Omnigent Learnings For SkillLedger

Date: 2026-06-14

Source reviewed: local checkout at `/Users/ghassan/external-projects/omnigent`.

## Executive Summary

Omnigent is an open-source meta-harness for running and governing agents across Claude Code, Codex, Pi, OpenAI Agents SDK, and custom YAML agents. Its runtime is far broader than SkillLedger's current product direction, but several design patterns are directly useful for SkillLedger's marketplace and entitlement layer.

The strongest transferable ideas are:

- treat published agent/skill artifacts as self-contained package images, not only inline JSON manifests
- split artifact ingestion into extraction, parsing, validation, verification, storage, and API serialization stages
- make policy and safety metadata first-class, versioned, and discoverable
- keep public catalog responses intentionally narrow while allowing purchased/acquired artifacts to expose full package contents
- add contract tests that catch OpenAPI drift and SDK/API mismatches
- improve developer confidence through examples that demonstrate real agent workflows, not only seed data

Omnigent should not pull SkillLedger toward hosted agent execution. The useful lesson is the packaging and governance layer around agent artifacts, not the server-runner-harness architecture.

## What Omnigent Is

Omnigent positions itself as a "meta-harness" for agent sessions. The repository combines:

- a Python/FastAPI server under `omnigent/server/`
- a runtime and harness adapter layer under `omnigent/runtime/`, `omnigent/inner/`, and related modules
- a declarative agent image/spec layer under `omnigent/spec/`
- a policy engine under `omnigent/policies/` and `omnigent/runtime/policies/`
- a React web UI under `ap-web/`
- SDKs under `sdks/`
- many deployment targets under `deploy/`

For SkillLedger, the most relevant areas are `omnigent/spec/`, `omnigent/policies/`, `omnigent/server/routes/`, `omnigent/stores/`, `sdks/python-client/`, and the matching tests.

## Transferable Pattern 1: Artifact Images, Not Only Manifests

Omnigent agents are loaded as directory-like images centered on `config.yaml`, with optional instructions, skills, tools, sub-agents, and policy declarations. The spec parser is pure filesystem code: it reads a bundle into typed structures before runtime behavior is involved.

SkillLedger currently stores `mcp_tool_manifest` JSON in `SkillArtifact#manifest`, verifies required fields, checks `runtime == "client"`, validates embedded `files`, and computes a checksum over canonical JSON.

Learning for SkillLedger:

- Keep the current manifest path for MVP compatibility.
- Add a future `skill_bundle` artifact type that represents a self-contained package with `skillledger.yaml` or `config.yaml`, `SKILL.md`, optional files, and optional policy metadata.
- Validate packages in layers:
  - extraction safety
  - package structure
  - manifest/schema parsing
  - SkillLedger-specific marketplace rules
  - checksum/provenance recording

Why it matters:

Inline JSON manifests are easy to post over REST/MCP, but real skills usually include instructions, reference files, helper scripts, examples, and policy expectations. Omnigent's package shape shows how to keep that portable without turning SkillLedger into a runtime.

## Transferable Pattern 2: Safe Bundle Extraction

Omnigent's `omnigent/spec/tar_utils.py` rejects path traversal, absolute paths, symlinks, hardlinks, special file types, decompression bombs, and entry-count bombs before extraction. `tests/spec/test_tar_utils.py` has regression tests for each case, including the subtle FIFO case where a `config.yaml` FIFO could hang a worker on read.

Learning for SkillLedger:

- If SkillLedger accepts tar/zip bundles, add a dedicated extraction service before any manifest parsing.
- Use an allow-list of regular files and directories rather than a deny-list of known bad types.
- Enforce byte and entry-count limits.
- Reject partial extraction on any unsafe member.
- Add focused tests before introducing bundle upload.

Candidate Rails services:

- `SkillBundleExtractionService`
- `SkillBundleParser`
- `SkillBundleVerificationService`

This is more urgent if artifacts move from DB-embedded files to uploaded package archives.

## Transferable Pattern 3: Parser And Validator Separation

Omnigent separates parsing from validation:

- `parser.py` turns a filesystem package into typed spec objects.
- `validator.py` checks domain rules and returns structured validation errors.
- tests cover both valid and invalid cases, including duplicate names, invalid modalities, missing sub-agent references, and reserved identifiers.

SkillLedger's `SkillArtifactVerificationService` currently combines shape checks, domain checks, status transitions, and verification persistence in one service.

Learning for SkillLedger:

- Keep `SkillArtifactVerificationService` as the orchestrator.
- Extract reusable pure checks into small objects or modules:
  - `SkillManifestParser`
  - `SkillManifestValidator`
  - `SkillBundleValidator`
- Return structured errors with paths, e.g. `files[0].path`, `runtime`, `input_schema`.
- Persist those structured errors in `SkillVerification#checks` or a future richer `issues` field.

This would improve publisher feedback and make MCP/API errors more useful without changing the product model.

## Transferable Pattern 4: Policy Metadata As Marketplace Signal

Omnigent has a rich policy model:

- policy verdicts are `ALLOW`, `DENY`, or `ASK`
- policies can evaluate at multiple phases such as request, tool call, tool result, response, LLM request, and LLM response
- policies are composable at session, agent, and server levels
- builtins cover cost budgets, OS tool approval, skill blocking, sandbox enforcement, PII checks, routing, GitHub, and Google access
- policy factories are discoverable through registry metadata and JSON-schema-like parameter descriptions

SkillLedger should not run or enforce these policies today because it is not a hosted runtime. But it can verify and publish policy metadata attached to an artifact.

Learning for SkillLedger:

- Add optional manifest fields for declared runtime expectations:
  - `permissions`
  - `policies`
  - `sandbox`
  - `network`
  - `secrets`
  - `tool_access`
- Verify that these declarations are present and well formed.
- Show a safe subset in public listings so buyers can compare risk before purchase.
- Include the full declarations in acquired artifacts so client runtimes can enforce them locally.

This aligns with SkillLedger's "verified package for local execution" model: SkillLedger certifies what the package declares; clients enforce at execution time.

## Transferable Pattern 5: Narrow Public Catalog, Full Acquisition Payload

Omnigent's built-in agent listing route loads the package but exposes only safe summaries such as name, harness, MCP server summaries, skill names/descriptions, and terminal names. Skill bodies are intentionally not exposed in catalog responses.

SkillLedger already follows a similar pattern in `McpService#get_skill`, where public skill detail returns `manifest_summary` and checksum, while `SkillAcquisitionService` returns the artifact manifest and files after purchase.

Learning for SkillLedger:

- Preserve this separation as bundle support expands.
- Public listing should expose:
  - skill identity
  - version
  - checksum
  - artifact type
  - declared runtime
  - permission/policy summary
  - file count or package size
- Acquisition should expose the full verified package payload.

This is a strong current design choice in SkillLedger. Omnigent reinforces it.

## Transferable Pattern 6: Session-Scoped Resources Map To Entitlement-Scoped Artifacts

Omnigent scopes files under session resources instead of exposing a global file namespace. The API docs explicitly describe session-owned file upload/list/get/content/delete endpoints.

SkillLedger's equivalent concept is not a session; it is a purchase entitlement.

Learning for SkillLedger:

- Treat acquired artifact downloads as entitlement-scoped resources.
- Avoid global artifact file URLs unless they are signed and entitlement checked.
- Model future package file endpoints around purchase/version ownership, e.g.:
  - `GET /api/v1/purchases/:purchase_id/artifact`
  - `GET /api/v1/purchases/:purchase_id/artifact/files/:path`

This keeps authorization local to the buyer entitlement and reduces accidental leakage when artifacts become larger than a JSON payload.

## Transferable Pattern 7: Contract And Drift Tests

Omnigent has a strict OpenAPI drift test in `tests/server/test_openapi_drift.py`: it regenerates `openapi.json` from the live app and byte-compares it to the checked-in artifact. The failure message gives explicit regeneration instructions.

SkillLedger has `openapi.yaml`, but the source is hand-maintained. That is acceptable for now, but it creates drift risk whenever controllers or response shapes change.

Learning for SkillLedger:

- Add an OpenAPI coverage/drift check appropriate for Rails.
- If full generation is too much, start with request tests that assert documented endpoints and key response fields exist.
- Add CI guidance that API behavior changes must update `openapi.yaml`.

This matters more as MCP and REST surfaces grow.

## Transferable Pattern 8: SDK-Like Client Tests

Omnigent's Python SDK includes tests that verify high-level client arguments are threaded into session/request internals. These are small tests, but they protect public client ergonomics.

SkillLedger does not currently ship SDKs. If it adds a Ruby, Python, TypeScript, or MCP client helper, copy this approach:

- test the public convenience method
- verify it calls the lower-level API with the expected method name and payload
- use concrete fakes rather than broad mocks where possible
- cover omitted optional fields as well as provided fields

This would be especially useful for MCP helpers around `skills/version.publish`, `skills/purchase`, and `skills/acquire`.

## Transferable Pattern 9: Examples As Product Proof

Omnigent's examples, especially Polly and Debby, show complete opinionated agent workflows rather than only API primitives. SkillLedger's seeded demo data proves the Rails flow works, but it does not yet prove why a real agent developer would publish or acquire a package.

Learning for SkillLedger:

- Add one or two complete example skill packages under a public examples directory.
- Each example should include:
  - package manifest
  - `SKILL.md`
  - files/scripts if applicable
  - publish command/API example
  - purchase/acquire example
  - local execution notes for the client runtime

Good candidates:

- deterministic code review skill
- ALMS learning bundle
- compliance checklist skill

This would make the marketplace model more concrete without adding runtime hosting.

## Transferable Pattern 10: Deployment Docs Menu

Omnigent has deployment documentation for Docker, Render, Railway, Fly.io, Hugging Face Spaces, Modal, and Daytona. SkillLedger already has SQLite local development and Docker Compose with PostgreSQL. Given SkillLedger's simpler architecture, one or two high-quality deployment guides are enough.

Learning for SkillLedger:

- Keep Docker Compose as the canonical production-like local path.
- Add a single hosted deployment guide only after the API and persistence model stabilize.
- Avoid copying Omnigent's broad deploy matrix until there is user demand.

## What Not To Copy

Do not copy these Omnigent choices into SkillLedger right now:

- hosted agent execution
- per-session runner subprocesses
- real-time collaboration server
- multi-harness orchestration
- mobile chat UI
- policy enforcement at runtime
- large deployment matrix

Those are coherent for Omnigent but would dilute SkillLedger's positioning. SkillLedger's sharper value is marketplace, verification, purchase, ledger, and acquisition of client-side packages.

## Recommended SkillLedger Backlog

### P0: Keep Current Direction

No immediate architecture pivot is needed. SkillLedger's "verified artifacts are acquired for local execution" model remains sound.

### P1: Improve Artifact Verification Feedback

Extract pure parser/validator layers from `SkillArtifactVerificationService`, keep the service as the persistence/status orchestrator, and persist structured validation issues.

Suggested tests:

- invalid manifest type
- missing required field with path
- invalid runtime
- version mismatch
- bad bundled file path/content/media type
- checksum mismatch

### P1: Add Policy And Permission Declarations To Manifest

Introduce optional manifest metadata for client-enforced safety:

```yaml
permissions:
  filesystem:
    read: []
    write: []
  network:
    allow: []
  secrets: []
policies:
  - name: ask_on_shell
    phase: tool_call
    action: ask
sandbox:
  runtime: client
  required: false
```

Start by validating shape only. Do not enforce execution.

### P2: Design `skill_bundle` Artifact Type

Create a roadmap document for package artifacts:

```text
skillledger.yaml
SKILL.md
files/
examples/
README.md
```

Add extraction safety before accepting uploads.

### P2: Add Public Catalog Risk Summaries

Expose package risk summaries in REST and MCP detail responses:

- declared permissions
- network/secrets requirement summary
- bundled file count
- package size
- verification issue count

Do not expose full skill content until acquisition.

### P2: Add OpenAPI Drift Or Coverage Gate

Add a test or CI step that protects `openapi.yaml` from falling behind controller behavior. Full generation can come later; endpoint/field coverage is enough to start.

### P3: Add Example Packages

Build at least one full example skill package and document publish, purchase, and acquire flows end to end.

## Bottom Line

Omnigent validates that agent artifacts need packaging, governance metadata, safe extraction, and contract tests. SkillLedger can borrow those layers without adopting Omnigent's hosted runtime.

The practical next move is to strengthen SkillLedger's artifact contract: make validation more structured, add declared permission/policy metadata, and plan a safe bundle format. That improves marketplace trust while preserving the client-side acquisition model.
