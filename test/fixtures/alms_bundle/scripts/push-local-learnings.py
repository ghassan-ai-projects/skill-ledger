#!/usr/bin/env python3
"""Push local markdown learnings to ALMS using direct MCP JSON-RPC calls."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from alms_mcp import ALMSMCPClient

ALMS_URL = os.getenv("ALMS_URL", "http://localhost:8001/mcp")
ALMS_TOKEN = os.getenv("ALMS_AUTH_TOKEN", "")
AGENT_ID = os.getenv("AGENT_ID", "openclaw-orch")
LEARNINGS_DIR = Path(os.getenv("LEARNINGS_DIR", "learnings"))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Push local markdown learnings to ALMS.")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--agent-id", default=AGENT_ID)
    return parser.parse_args()


def extract_learnings(learnings_dir: Path) -> list[dict]:
    learnings = []
    if not learnings_dir.is_dir():
        return learnings
    for path in sorted(learnings_dir.glob("*.md")):
        if path.name == "README.md":
            continue
        learnings.append(
            {
                "title": path.stem,
                "body": path.read_text(encoding="utf-8")[:4000],
                "type": "pattern",
                "tags": ["alms"],
            }
        )
    return learnings


def main() -> None:
    args = parse_args()
    client = ALMSMCPClient(ALMS_URL, ALMS_TOKEN)
    learnings = extract_learnings(LEARNINGS_DIR)
    if not args.apply:
        print(json.dumps(learnings, indent=2))
        return
    for learning in learnings:
        client.call_tool(
            "learning.store",
            {
                "agent_id": args.agent_id,
                "title": learning["title"],
                "body": learning["body"],
                "type": learning["type"],
                "tags": learning["tags"],
            },
        )


if __name__ == "__main__":
    main()
