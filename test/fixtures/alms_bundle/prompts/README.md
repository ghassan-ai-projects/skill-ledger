# ALMS Prompt Library

Standardized prompts that agents use to interact with the ALMS MCP server.

## Architecture Decision Record

- Prompts live inside the ALMS repo because they define the contract between agents and ALMS.
- One file, `prompts.md`, keeps the prompt contract easier to diff and maintain.
- The library covers Store, Score, Search, Score Update, and Nudge.
- The format is Markdown with embedded JSON examples for readability plus structure.
