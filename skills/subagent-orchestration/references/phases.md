# Phase Semantics

## Order

Run each task in this order:

1. `Plan`
2. `Execute`
3. `Review`
4. `Commit`

Do not skip `Review`. Do not merge `Commit` into any earlier phase.

## Plan

Purpose:

- turn one task into an executable brief
- identify validation and known risks

Exit condition:

- a concrete implementation brief exists
- acceptance checks are clear enough for execution

## Execute

Purpose:

- implement the task using the approved brief
- run requested checks

Exit condition:

- the task changes are applied
- validation results are reported
- open concerns are surfaced

## Review

Purpose:

- verify requirement fit and code quality
- patch directly when needed

Rules:

- reviewers may patch directly
- if a reviewer patches, they must note which files changed
- if a reviewer patches, they must rerun any affected validation

Exit condition:

- decision is either `approved` or `needs-more-work`

## Commit

Purpose:

- persist only reviewed, validated work
- mark the task complete

Rules:

- commit happens only in the main session
- commit requires review approval
- commit requires validation evidence from execution or review

## Interruptions And Recovery

Keep recovery simple.

- if the current phase is clear, continue from that phase
- if the current phase is unclear, step back one phase
- if planner output is unclear, re-plan the task
- if execution output is unclear, re-run review after refreshing the summary

Never guess across an ambiguous boundary just to keep momentum.
