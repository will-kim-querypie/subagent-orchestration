---
name: subagent-orchestration
description: Use when executing a written implementation plan in a subagent-capable client and the main session should orchestrate task-by-task delegation.
---

# Subagent Orchestration

## Overview

Use one main session as the orchestrator for each task in an approved implementation plan.

Run every task through:

`Plan -> Execute -> Review -> Commit`

This skill is for subagent-capable clients only.

## Core Rules

- The main session owns long-lived context.
- Delegate planning to `most-capable`.
- Delegate implementation to `general-executor`.
- Delegate default review to `most-capable`.
- Default reviewers may patch directly.
- If the brief contains `Review profile: simplify`, keep review orchestration in the main session: fan out three read-only `most-capable` reviewers and, when findings exist, dispatch one `general-executor` fixer.
- Commit is always a separate final phase in the main session.
- Pass task-local context by default, not the full repository history.
- If interruption makes state unclear, step back one phase instead of guessing.

## Entry Input

This skill accepts one optional input:

- `config`
- a plan file path
- user instructions

Before doing anything else, resolve the entry input with:

```bash
bash scripts/resolve-entry-input.sh "<optional input>"
```

If no explicit input was supplied when invoking the skill, run the script with no argument.

Interpret the result like this:

- `INPUT_MODE=config`: launch the interactive provider and role-mapping editor, then stop
- `INPUT_MODE=plan_file`: use the validated file content as the plan source, then review it critically before starting the task loop
- `INPUT_MODE=instructions`: treat the supplied text as the execution source, normalize it into an explicit working plan in the main session, then review it critically before starting the task loop
- `INPUT_MODE=conversation`: use the current conversation as the instruction source, and do not start the task loop until an explicit working plan exists

If the resolver exits non-zero, stop and fix the input instead of guessing.

If the resolved mode is `config`, run:

```bash
bash scripts/config-model-mapping.sh
```

and stop after the configuration flow completes.

For every non-`config` run, print the current provider's role mapping before doing any task work:

```bash
bash scripts/print-model-mapping.sh "<current-provider>"
```

Use `claude-code` when running in Claude Code and `codex` when running in Codex.

Print that startup banner verbatim.
Do not paraphrase model names or collapse them to family names like `opus` or `sonnet`.
Always preserve the exact configured string, including version numbers and any effort/speed suffixes.

## Required References

Read these first:

- `references/phases.md`
- `references/contracts.md`
- `references/models.md`

Then read the adapter for the current client:

- `references/adapters/claude-code.md`
- `references/adapters/codex.md`

Use examples only when you need a compact template:

- `references/examples/task-brief.md`
- `references/examples/review-brief.md`
- `references/examples/commit-brief.md`
- `references/review-profiles/simplify.md`

Read the helper script when you need the exact input-resolution behavior:

- `scripts/resolve-entry-input.sh`
- `scripts/print-model-mapping.sh`
- `scripts/config-model-mapping.sh`
- `scripts/model-mapping.py`
- `scripts/resolve-review-profile.sh`
- `scripts/init-review-artifacts.sh`
- `scripts/cleanup-review-artifacts.sh`

## Review Profiles

Built-in review profiles are opt-in.

- Trigger them only when the task brief contains an explicit `Review profile: ...` line.
- The only built-in profile in this skill is `Review profile: simplify`.
- Resolve that profile with `bash scripts/resolve-review-profile.sh simplify`.
- Initialize scratch artifacts with `bash scripts/init-review-artifacts.sh "<task-id>" simplify`.
- Treat the returned `manifest.json` as the handoff anchor for the review fan-out and any follow-up fixer.

## Task Loop

After the entry input has been resolved and reviewed into an explicit plan, for each task in that plan:

1. Create or refresh the task brief.
2. Dispatch task planning.
3. Dispatch task execution.
4. Dispatch task review. If the brief contains `Review profile: simplify`, resolve the profile, initialize review artifacts, fan out three read-only reviewers, then dispatch a fixer from the findings manifest only when one or more reviewers found issues.
5. If review approves, commit in the main session.

## Do Not Use This Skill When

- the client cannot delegate to subagents
- there is no explicit plan source yet and you cannot derive one from the supplied input
- the work is a one-off edit that does not benefit from task-by-task orchestration
