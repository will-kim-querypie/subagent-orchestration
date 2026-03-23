# subagent-orchestration

`subagent-orchestration` is a single skill for task-based agent workflows that route each task through:

`Plan -> Execute -> Review -> Commit`

It is designed for subagent-capable clients where one main session stays in control and delegates task-local work in phases.

## Install

List the skill before installing:

```bash
npx skills add will-kim-querypie/subagent-orchestration --list
```

Recommended global install for Codex:

```bash
npx skills add will-kim-querypie/subagent-orchestration -a codex -g
```

Recommended global install for Claude Code:

```bash
npx skills add will-kim-querypie/subagent-orchestration -a claude-code -g
```

Project-local install also works:

```bash
npx skills add will-kim-querypie/subagent-orchestration -a codex
```

## Use

Codex:

```text
$subagent-orchestration config
$subagent-orchestration /absolute/path/to/plan.md
$subagent-orchestration "Implement the approved plan in task order"
```

Claude Code:

```text
/subagent-orchestration config
/subagent-orchestration /absolute/path/to/plan.md
/subagent-orchestration "Implement the approved plan in task order"
```

## What The Skill Does

- Resolves entry input as `config`, `plan_file`, `instructions`, or `conversation`
- Prints the active provider role mapping before task work
- Uses abstract model roles instead of hardcoding one provider into the core workflow
- Keeps commit as a final main-session phase after review approval

## Repository Layout

```text
.
├── SKILL.md
├── README.md
├── LICENSE
├── agents/
├── config/
├── references/
└── scripts/
```

The repository root is the skill root so `npx skills add owner/repo` works without pointing at a nested path.

## Local Verification

Run these from the repository root:

```bash
bash scripts/resolve-entry-input.sh
bash scripts/resolve-entry-input.sh config
bash scripts/print-model-mapping.sh codex
bash scripts/print-model-mapping.sh claude-code
```

## License

MIT
