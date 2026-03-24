# Review Profile: `simplify`

Use this built-in profile when the review brief contains the exact line:

`Review profile: simplify`

This profile keeps review orchestration in the main session.

- The main orchestrator fans out three independent read-only reviewers.
- Each reviewer gets one lens only: `reuse`, `quality`, or `efficiency`.
- Reviewers do not spawn nested subagents.
- Reviewers do not patch directly.
- Reviewers write findings only to their assigned findings file.
- The main orchestrator forwards only status and file paths between phases, not the full findings text.

## Lenses

### `reuse`

- look for existing helpers, utilities, and adjacent code that can replace new logic
- flag duplicated functions or inline logic that should reuse existing code
- flag ad-hoc parsing, path handling, env checks, and similar reimplementations

### `quality`

- flag redundant state and derived state that should not be stored
- flag parameter sprawl, copy-paste variation, and leaky abstractions
- flag stringly-typed additions that should use existing constants or types
- flag unnecessary wrapper structure or comments that explain only what the code does

### `efficiency`

- flag redundant work, repeated reads, duplicate calls, and hot-path bloat
- flag missed concurrency for independent operations
- flag recurring no-op updates, unnecessary existence checks, and broad reads
- flag memory growth, listener leaks, and missing cleanup

## Findings File Contract

Write only to the assigned file path.

Use this shape:

```md
# <lens> review

## Findings
- <finding>
- <finding>

## Skipped
- <optional false positive or not-worth-fixing note>
```

If there are no findings, write:

```md
# <lens> review

No findings.
```

Reply to the orchestrator with only one line:

- `DONE <assigned-findings-path>`
- `NO_FINDINGS <assigned-findings-path>`
