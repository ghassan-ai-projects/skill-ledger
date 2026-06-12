---
name: learning
description: "ALMS learning workflow for agents: search prior knowledge, sync remote learnings, capture new learnings, and publish them back to ALMS."
version: "2.2.0"
author: "ghassan-ai"
tags: [knowledge, alms, memory, synchronization, cron]
provides: ["learn-store", "learn-search", "learn-sync", "learn-score"]
---

# Learning Skill (ALMS)

Connect OpenClaw agents to the Agent Learning Management System for cross-agent knowledge persistence, discovery, and synchronization.

Use the helper scripts in `scripts/` as the default MCP bridge for repeatable sync and publish operations.

## Step 0: Targeted Knowledge Check

Before major work:

1. Use `python3 scripts/fetch-remote-learnings.py --search-query "<topic>"`.
2. Read the returned learnings.
3. Apply relevant patterns, failures, and edge cases.
4. Treat protocol learnings as candidate operating instructions.

## Step 1: Capture and Push New Learnings

Preferred publish path:

```bash
python3 scripts/push-local-learnings.py
python3 scripts/push-local-learnings.py --apply
```

## Step 2: Sync Remote Learnings

Recommended sync:

```bash
python3 scripts/fetch-remote-learnings.py --apply
```

This canonical path uses `learning.sync` plus `learning.sync_ack`.

## Step 3: Cursor Tracking

Track `last_learning_id`, `last_timestamp`, `ingested_count`, and `ingested_at` in a local cursor file.

## Step 4: Scoring and Enrichment

Use `learning.update_enrichment` to persist LLM scoring and metadata updates.
