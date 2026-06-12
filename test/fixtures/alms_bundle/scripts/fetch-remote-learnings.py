#!/usr/bin/env python3
"""Fetch remote learnings from ALMS and ingest them into a local learnings folder."""

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
    parser = argparse.ArgumentParser(description="Fetch remote learnings from ALMS.")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--search-query")
    parser.add_argument("--agent-id", default=AGENT_ID)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    client = ALMSMCPClient(ALMS_URL, ALMS_TOKEN)
    if args.search_query:
        payload = client.call_tool(
            "learning.search",
            {
                "query": args.search_query,
                "limit": 100,
                "status": "all",
                "include_rejected": False,
            },
        )
    else:
        payload = client.call_tool(
            "learning.sync",
            {
                "agent_id": args.agent_id,
                "since": "1970-01-01T00:00:00Z",
                "type": "",
                "tags": [],
            },
        )
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
