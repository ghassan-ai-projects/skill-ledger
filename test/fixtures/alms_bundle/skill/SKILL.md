---
name: alms-agent
description: "ALMS learning lifecycle for agents: store discoveries, sync fresh knowledge, score quality, stay nudged."
version: "1.0.0"
author: "openclaw-alms"
tags: [alms, learning, knowledge-management, protocol, agent-sync]
provides: ["alms-store", "alms-sync", "alms-score", "alms-medicate"]
---

# ALMS Agent Learning Skill v1.0

This skill wraps the ALMS prompt categories into repeatable agent workflows.

## Dependencies

- ALMS MCP server with learning tools
- Prompts library at `alms/prompts/prompts.md`
- Existing ALMS tags registry
- DeepSeek and Gemini access for high-severity multi-model scoring

## Workflow 1: Store

1. Compose the learning title, body, type, tags, and severity.
2. Call `learning.store`.
3. If severity is high or critical, score it immediately.
4. Notify a human if severity is critical.

## Workflow 2: Sync

1. Read local sync state.
2. Call `learning.sync`.
3. Process critical learnings first.
4. Acknowledge all returned learning IDs with `learning.sync_ack`.

## Workflow 3: Evaluate

1. Read the learning with `learning.get`.
2. Build the scoring prompt from the prompt library.
3. Score with the appropriate model.
4. Update enrichment and tags.

## Workflow 4: Background Check

Run a low-frequency sync for failures and protocols, then batch-score pending learnings.

## Prompts Reference

- Store: `prompts/prompts.md` Section A
- Score: `prompts/prompts.md` Section B
- Search: `prompts/prompts.md` Section C
- Score Update: `prompts/prompts.md` Section D
- Nudge: `prompts/prompts.md` Section E
