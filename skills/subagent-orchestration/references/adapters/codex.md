# Codex Adapter

Use this adapter when the current client is Codex.

## Model Mapping

As of 2026-03-20:

- `most-capable` -> `gpt-5.3-codex`
- `general-executor` -> `gpt-5.2-codex`

These are the default Codex values. The live mapping is stored in `config/providers.json` and surfaced by the model-mapping scripts.

## Invocation Syntax

- run skill: `$subagent-orchestration <plan-path-or-instructions>`
- configure models: `$subagent-orchestration config`

## Dispatch Guidance

- keep the main Codex session as the orchestrator
- use fresh delegated workers for planning, execution, and review when available
- pass task-local context and concrete output expectations
- avoid making delegated workers rediscover repository context that the orchestrator already has

## Review Guidance

- reviewers may patch directly
- reviewers should state what they changed and what they revalidated
- `Review profile: simplify` should stay as main-session fan-out: three read-only reviewers plus one fixer
- do not rely on deeper nesting or `agents.max_depth` changes for `simplify`
- pass findings file paths between phases instead of replaying full findings into the main context

## Commit Guidance

- commit remains a final main-session phase
- require review approval and validation evidence before committing

## Notes

- adapters should track current Codex coding-model availability separately from the core skill
- keep Codex-specific tool names and harness details out of the core skill
