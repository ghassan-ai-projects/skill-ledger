# Security Policy

## Supported Scope

SkillLedger is still evolving, but responsible disclosure is welcome for:

- authentication and authorization issues
- purchase, entitlement, or ledger integrity issues
- data exposure
- artifact verification bypasses
- dependency or deployment-related risks with a plausible security impact

## Reporting A Vulnerability

Please do not open public GitHub issues for suspected vulnerabilities.

Instead, contact the maintainers privately with:

- a description of the issue
- affected endpoints, files, or flows
- reproduction steps or a proof of concept when possible
- impact assessment

If you do not yet have a dedicated security inbox configured, use the repository owner contact path and clearly label the message as `SECURITY`.

## Disclosure Expectations

- give maintainers reasonable time to investigate and patch
- avoid publishing exploit details before a fix or mitigation is available
- include enough detail for reproducibility

## Current Security Notes

- API access is controlled by account-scoped API keys in `X-API-Key`
- the default development and production data stores are SQLite-based
- purchase operations mutate balances and create ledger entries transactionally
- artifact verification is manifest-based and should not be treated as a sandbox or malware scan

See [documentation/security-model.md](/Users/ghassan/my-projects/skill-ledger/documentation/security-model.md) for the current trust model and hardening guidance.
