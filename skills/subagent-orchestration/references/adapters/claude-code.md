# Claude Code Adapter

Use this adapter when the current client is Claude Code.

## Model Mapping

As of 2026-03-20:

- `most-capable` -> `Opus 4.1`
- `general-executor` -> `Sonnet 4`

These are the default Claude Code values. The live mapping is stored in `config/providers.json` and surfaced by the model-mapping scripts.

## Invocation Syntax

- run skill: `/subagent-orchestration <plan-path-or-instructions>`
- configure models: `/subagent-orchestration config`

## Dispatch Guidance

- keep the main Claude Code session as the orchestrator
- dispatch fresh subagents per task phase when possible
- give each subagent the task brief, not the whole plan by default
- include only the files, docs, and constraints needed for the phase

## Review Guidance

- reviewers may patch directly
- reviewers should explicitly report patched files and rerun affected checks
- `Review profile: simplify` should stay as main-session fan-out: three read-only reviewers plus one fixer
- do not attempt nested subagent spawning for `simplify`
- pass findings file paths between phases instead of replaying full findings into the main context

## Commit Guidance

- commit stays in the main session
- do not treat review patching as implicit approval to skip the commit phase

## Notes

- Claude Code may auto-shift between available models depending on account limits; preserve the role mapping intent even if the exact model must degrade temporarily
- keep provider-specific slash commands or local workflow conventions out of the core skill
