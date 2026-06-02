---
type: concept
title: "Plan-Implement-Review Agent Workflow"
created: 2026-06-01
updated: 2026-06-01
address: c-000007
tags:
  - concept
  - claude-code
  - agents
  - workflow
status: developing
complexity: intermediate
domain: claude-code
aliases:
  - "planner-engineer-reviewer triad"
related:
  - "[[GrantMe Claude Code Configuration]]"
  - "[[GrantMe]]"
  - "[[Claude Code Project Configuration]]"
  - "[[Claude Code Agent Memory Pattern]]"
---

# Plan-Implement-Review Agent Workflow

A division-of-labor pattern for feature development with Claude Code: distinct sub-agents for planning, implementation, and review, orchestrated by slash commands that gate the transitions. Documented from the [[GrantMe]] configuration ([[GrantMe Claude Code Configuration]]).

## The agent triad

| Phase | Agent | Model | Mandate |
|---|---|---|---|
| Plan & scope | `planner` | Sonnet | Clarify requirements, scan code, produce a structured implementation plan. **Writes no code.** |
| Implement (backend) | `dotnet-backend-engineer` | Sonnet | C#/.NET/EF Core; verify-as-you-go (build + targeted tests) |
| Implement (frontend) | `frontend-engineer` | Sonnet | React/Mantine/TypeScript; verify-as-you-go (build + lint) |
| Review | `fullstack-code-reviewer` | Opus | Multi-dimensional review (security -> performance -> reliability -> maintainability -> standards) |

Model tiering is deliberate: cheaper Sonnet for planning and implementation, stronger Opus reserved for the review gate where catching a subtle bug pays for itself. Each agent carries project-scoped memory (see [[Claude Code Agent Memory Pattern]]), so the triad compounds.

## The planner contract

The planner is the highest-leverage piece. Its process: (1) understand the request, (2) **scan the codebase first** to avoid asking questions the code already answers, (3) ask 3-5 *specific* follow-up questions framed with options, (4) emit a structured plan (summary, approach, files to change, implementation order, reuse, which agent, risks, acceptance criteria, out-of-scope). A plan-quality checklist verifies every cited file path exists and that the order respects dependencies. Plan depth scales to task complexity; a one-file fix skips the questions.

Crucially, **the human confirms the plan before any code is written.** Planning is separated from doing so the cheap step (words) catches what the expensive step (code) would otherwise discover late.

## Commands gate the loop

Slash commands script the repetitive workflow so the human focuses on the problem:

- **`/start-work <id>`** — fetch the Azure DevOps work item + comments, assign and move to "Doing", create a `{id}/{type}/{desc}` branch from master, then launch the planner. Waits for plan confirmation.
- **`/finish-issue`** — an 8-phase gate, each phase a stop point on failure: (1) pre-flight build/lint/format, (2) `fullstack-code-reviewer` (stops if critical *or* recommended issues found), (3) update docs/rules if behavior changed, (4) confirm commit + PR preview with the user, (5) commit + push (conventional message, never amend), (6) create Azure DevOps PR with linked work item + auto-complete, (7) write Swedish manual-test instructions for a non-technical tester and post to the work item, (8) move to "Ready for test".
- **`/review`** — the review phase alone, no commit/PR, for a mid-work check.
- **`/generate-e2e-test <scenario>`** — explore the app with playwright-cli, generate a Playwright test, iterate until green.

## Why the gates matter

Each command phase is a checkpoint that *stops and reports* rather than plowing ahead: a failing build halts before review; critical or recommended review findings halt before commit; the human confirms before the PR is opened. The pattern trades a little autonomy for a lot of predictability, and it encodes the team's definition of "done" (reviewed, documented, tested-instructions-written, work-item-moved) into tooling instead of memory.

## Transferable shape

Plan (cheap, confirmed by a human) -> Implement (role- and stack-specialized, verifying as it goes) -> Review (strongest model, blocking) -> Ship (scripted, with human confirmation at the irreversible step). The slash commands are where a team's process becomes executable. See [[Claude Code Project Configuration]] for how the agents and commands sit in the `.claude/` layout.
