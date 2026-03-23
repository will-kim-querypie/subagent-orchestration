# Model Classes

The core skill uses only two abstract model classes.

## `most-capable`

Use for:

- planning
- review
- scope judgment
- ambiguity resolution

This class is for tasks where quality depends on strong reasoning, tradeoff judgment, or broad context synthesis.

## `general-executor`

Use for:

- implementation
- bounded refactors
- mechanical follow-through
- running the requested checks

This class is for task execution when the planner has already narrowed the scope.

## Mapping Rules

- `planner` -> `most-capable`
- `executor` -> `general-executor`
- `reviewer` -> `most-capable`

## Adapter Rule

Adapters map these classes to current provider model names.

The core skill must not hardcode provider-specific model identifiers.

If a provider has only one suitable model, the adapter may map both classes to the same model.
