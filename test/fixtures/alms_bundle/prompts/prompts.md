# ALMS Prompts — Agent ↔ ALMS Protocol

These prompts define the standard messages agents send to the ALMS MCP server and to LLMs for scoring.

## A. Store Prompt — "Record a new learning"

Use `learning.store` with:

```json
{
  "agent_id": "<your-agent-id>",
  "title": "Short, specific title",
  "body": "Full context and exact steps",
  "type": "pattern|failure|config|protocol|edge_case",
  "tags": ["alms", "project-tag"],
  "supersedes": ""
}
```

## B. Score Prompt — "Evaluate this learning"

The LLM scores reusability, specificity, accuracy, novelty, and clarity, then returns JSON with:

- `quality_score`
- `verdict`
- `scores`
- `suggested_tags`
- `duplicate_of`
- `supersedes`
- `explanation`

## C. Search Prompt — "Find fresh learnings"

1. Call `learning.sync`.
2. Process critical learnings first.
3. Call `learning.sync_ack` with all returned IDs.

## D. Score Update Prompt — "Record LLM scoring result"

Persist enrichment through `learning.update_enrichment`.

## E. Nudge Prompt — "Alert agent about high-priority learning"

Notify an agent when a critical or high-value learning is waiting and the agent has not synced recently.
