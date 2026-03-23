# subagent-orchestration

`subagent-orchestration` is a skill-first repository for task-based agent workflows that route each task through:

`Plan -> Execute -> Review -> Commit`

The canonical skill content lives in [`skills/subagent-orchestration`](skills/subagent-orchestration). Claude marketplace support is packaged separately under [`plugins/subagent-orchestration`](plugins/subagent-orchestration) so the repository structure stays agent-neutral.

## Install With skills.sh

List the available skill:

```bash
npx skills add will-kim-querypie/subagent-orchestration --list
```

Install globally for Codex:

```bash
npx skills add will-kim-querypie/subagent-orchestration -a codex -g
```

Install globally for Claude Code:

```bash
npx skills add will-kim-querypie/subagent-orchestration -a claude-code -g
```

Project-local install also works:

```bash
npx skills add will-kim-querypie/subagent-orchestration -a codex
```

## Install With Claude Marketplace

Add the marketplace:

```text
/plugin marketplace add will-kim-querypie/subagent-orchestration
```

Install the plugin:

```text
/plugin install subagent-orchestration@subagent-orchestration
```

Claude plugin skills are namespaced, so invoke the skill as:

```text
/subagent-orchestration:subagent-orchestration config
/subagent-orchestration:subagent-orchestration /absolute/path/to/plan.md
/subagent-orchestration:subagent-orchestration Implement the approved plan
```

## Use

Codex:

```text
$subagent-orchestration config
$subagent-orchestration /absolute/path/to/plan.md
$subagent-orchestration "Implement the approved plan in task order"
```

Claude Code via `skills.sh` install:

```text
/subagent-orchestration config
/subagent-orchestration /absolute/path/to/plan.md
/subagent-orchestration "Implement the approved plan in task order"
```

## Repository Layout

```text
.
├── .claude-plugin/                 # Marketplace catalog
├── plugins/
│   └── subagent-orchestration/     # Claude plugin wrapper
├── skills/
│   └── subagent-orchestration/     # Canonical skill source
├── scripts/
│   └── test.sh                     # Local integration checks
├── AGENTS.md
├── README.md
└── LICENSE
```

## Local Verification

Run the packaging and installation checks from the repository root:

```bash
bash scripts/test.sh
```

## License

MIT
