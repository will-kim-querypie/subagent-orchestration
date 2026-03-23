# Role And Handoff Contracts

## Entry Input Contract

Run `scripts/resolve-entry-input.sh` before the task loop.

The resolver may return one of three modes:

- `config`
- `plan_file`
- `instructions`
- `conversation`

### `config`

- the caller asked to edit provider model mappings
- no task orchestration should start
- the interactive config script becomes the whole execution path

### `plan_file`

- the path was found
- the file is readable
- the file is non-empty
- the resolver returns both the absolute path and the file content

### `instructions`

- the input was treated as free-form user instructions
- the orchestrator must normalize it into an explicit working plan before dispatching task phases

### `conversation`

- no explicit skill input was provided
- the orchestrator must use current conversation context as the source of instructions
- if no execution-ready plan exists, stop and ask for clarification or a plan

If the resolver fails, do not continue into planning or execution.

## Orchestrator

Owns:

- task selection
- task-local context gathering
- subagent dispatch
- final commit

Must provide each subagent only the context needed for the current task.

For non-`config` runs, the orchestrator must print the current provider's role mapping and configuration command before starting task work.
That startup display must preserve the exact configured model strings verbatim.

## Planner Contract

### Planner input

- task title or id
- task goal
- resolved plan source
- in-scope and out-of-scope
- acceptance checks
- relevant files and docs
- adapter-specific notes for the current client

### Planner output

- implementation brief
- file targets or likely edit areas
- validation checklist
- key assumptions or risks

## Executor Contract

### Executor input

- approved implementation brief
- relevant files and docs
- validation checklist

### Executor output

- concise change summary
- changed files
- validation run and result
- remaining concerns

## Reviewer Contract

### Reviewer input

- original task requirements
- planner output
- executor output
- changed files
- validation results

### Reviewer output

- decision: `approved` or `needs-more-work`
- findings or patch summary
- patched files, if any
- revalidation performed, if any
- final summary for commit

## Commit Contract

### Commit input

- approved review result
- final change summary
- validation evidence

### Commit output

- persisted change
- task marked complete

## Context Discipline

- do not forward the full implementation plan when one task brief is enough
- do not make subagents rediscover obvious context that the orchestrator already has
- do not hide critical constraints to save tokens

Use the example briefs in `references/examples/` when a compact handoff template helps.
