# Example Review Brief

```md
Review this task against the original brief.

Review profile: simplify

Artifact manifest: /absolute/path/to/<git-dir>/subagent-orchestration/reviews/task-123/manifest.json

Required checks:
- requirement fit
- unnecessary scope creep
- correctness risks
- code quality

If `Review profile: simplify` is present:
- the main orchestrator owns the fan-out and fixer dispatch
- each reviewer gets exactly one lens and one findings file
- reviewers do not patch directly
- reviewers return only `DONE <path>` or `NO_FINDINGS <path>`

Otherwise:
- you may patch directly if needed
- return `approved` or `needs-more-work`
- include findings or patch summary, patched files, and revalidation performed

Return:
- follow the profile-specific return rules above
```
