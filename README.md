# subagent-orchestration

`subagent-orchestration` is a skill-first repository for task-based agent workflows that route each task through:

`Plan -> Execute -> Review -> Commit`

The canonical skill content lives in [`skills/subagent-orchestration`](skills/subagent-orchestration). Claude marketplace support is packaged separately under [`plugins/subagent-orchestration`](plugins/subagent-orchestration) so the repository structure stays agent-neutral.

## Install With skills.sh

List the available skill:

```bash
npx skills add will-kim-querypie/subagent-orchestration --list
```

### Global install

Install for Codex:

```bash
npx skills add will-kim-querypie/subagent-orchestration -a codex -g
```

Install for Claude Code:

```bash
npx skills add will-kim-querypie/subagent-orchestration -a claude-code -g
```

Verified `skills.sh` behavior:

- For Codex, global installs keep the canonical copy under `~/.agents/skills/subagent-orchestration`.
- For Claude Code, global installs materialize at `~/.claude/skills/subagent-orchestration`.
- Project-local installs keep the canonical copy under `./.agents/skills/subagent-orchestration`.
- For Codex, treat the canonical `.agents` path as the source of truth. Do not rely on a mirrored `~/.codex/skills/subagent-orchestration` directory being created.
- In local verification, Claude Code global installs produced a materialized directory at `~/.claude/skills/subagent-orchestration` for both the default mode and `--copy`. Rely on the install path rather than symlink semantics.

If `~/.claude/skills` does not exist yet, create it before reinstalling:

```bash
mkdir -p ~/.claude/skills
npx skills add will-kim-querypie/subagent-orchestration -a claude-code -g
```

Install an independent Claude Code copy:

```bash
npx skills add will-kim-querypie/subagent-orchestration -a claude-code -g --copy
```

### Project-local install

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

Claude Code via `skills.sh --copy` uses the same invocation and the same install path. Treat `~/.claude/skills/subagent-orchestration` as the runtime location regardless of whether `skills.sh` materializes it via copy or another internal strategy.

## Built-in Review Profile

This skill includes one bundled review profile:

- `Review profile: simplify`

When a task brief includes `Review profile: simplify`, the main orchestrator keeps review orchestration in the main session:

- it resolves the bundled profile from the installed skill path
- it creates file-backed review artifacts under the current repo's `.git/subagent-orchestration/reviews/`
- it fans out three read-only reviewers for `reuse`, `quality`, and `efficiency`
- it dispatches one fixer only when one or more findings files contain issues

Outside a git repository, review artifacts fall back to `${TMPDIR:-/tmp}/subagent-orchestration/`.

`simplify` is a built-in profile, not an external runtime file path. Do not depend on `/tmp/simplify_skill.md` being present at execution time.

## Troubleshooting

If a global Claude Code install finishes but `~/.claude/skills/subagent-orchestration` is missing, create the agent directory and reinstall:

```bash
mkdir -p ~/.claude/skills
npx skills add will-kim-querypie/subagent-orchestration -a claude-code -g
```

If you want to request an explicit Claude Code copy install:

```bash
npx skills add will-kim-querypie/subagent-orchestration -a claude-code -g --copy
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
