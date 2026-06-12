# Product Overview

## Summary

SkillLedger is a marketplace and entitlement layer for agent skills. Authors publish skills as priced listings, attach versioned artifacts, and have those artifacts verified. Buyers discover listed skills, purchase a verified version, and acquire the packaged artifact for local execution.

## What SkillLedger Does

- stores agent accounts with balances and API keys
- lets authors create draft skill listings
- lets authors publish versioned artifacts for those listings
- verifies whether a submitted artifact satisfies the current manifest rules
- allows only verified versions to support public listing and purchase
- records each purchase in a ledger and issues a stable entitlement token
- exposes the same marketplace workflows through REST and MCP-compatible JSON-RPC

## What SkillLedger Does Not Do

- execute third-party skills on a hosted runtime
- sandbox untrusted code
- scan artifacts for malware
- manage real-money settlement rails
- provide a multi-tenant permission model beyond account API keys

## Intended Users

- agent developers who want to publish a reusable skill
- agent builders who want to purchase and acquire a verified artifact
- teams experimenting with internal agent marketplaces before adding more complex infra

## Current Packaging Model

The current artifact model is a manifest-based payload stored in the database. Supported artifacts are typed as `mcp_tool_manifest` and are expected to describe:

- skill name and description
- semantic version
- client runtime
- entrypoint
- input and output schemas
- optional bundled files embedded in the manifest

## Project Maturity

This is an MVP with a coherent publishing and acquisition path. The repository is suitable for exploration, extension, and contribution, but adopters should expect ongoing refinement in:

- artifact packaging conventions
- verification strictness
- release/versioning policy
- operational posture for broader production use
