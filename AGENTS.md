# subagent-orchestration

This repository publishes the canonical source for the `subagent-orchestration` agent skill.

The top-level `skills/` directory is the source of truth.
Marketplace-specific packaging lives under `plugins/`.

## Installation

```bash
npx skills add will-kim-querypie/subagent-orchestration
```

For `skills.sh`, treat `skills/subagent-orchestration` as the repository source of truth.
For Codex, global installs keep the canonical copy under `~/.agents/skills/subagent-orchestration`.
For Claude Code, global installs materialize at `~/.claude/skills/subagent-orchestration`.
Project-local installs keep the canonical copy under `./.agents/skills/subagent-orchestration`.
Claude marketplace packaging remains separate under `plugins/`.

## Available Skills

<available_skills>
<skill>
<name>subagent-orchestration</name>
<description>Use when executing a written implementation plan in a subagent-capable client and the main session should orchestrate task-by-task delegation.</description>
<location>skills/subagent-orchestration</location>
<invoke>Read skills/subagent-orchestration/SKILL.md</invoke>
</skill>
</available_skills>
