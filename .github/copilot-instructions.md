# GitHub Copilot Instructions

For all coding, review, and generation tasks in this repository, please refer to the canonical agent instructions:

[AGENTS.md](../AGENTS.md)

Copilot should:

- Suggest Ruby code that complies with `.rubocop.yml`.
- Default to Minitest tests for new or changed production behavior.
- Keep Rails controllers thin and prefer service objects for business workflows.
- Avoid suggesting broad exception rescues or undocumented public API changes.
