---
type: concept
title: "Claude Code Project Configuration"
created: 2026-06-01
updated: 2026-06-01
address: c-000005
tags:
  - concept
  - claude-code
  - context-engineering
  - configuration
status: developing
complexity: intermediate
domain: claude-code
aliases:
  - ".claude directory"
  - "CLAUDE.md layering"
related:
  - "[[GrantMe Claude Code Configuration]]"
  - "[[GrantMe]]"
  - "[[Claude Code Agent Memory Pattern]]"
  - "[[Plan-Implement-Review Agent Workflow]]"
  - "[[Hot Cache]]"
---

# Claude Code Project Configuration

The blueprint a mature team uses to make Claude Code reliably follow a codebase's conventions: a layered `.claude/` directory that separates **what is always in context** from **what is read on demand**, plus role-specialized agents, scripted commands, and persistent memory. Documented from the [[GrantMe]] configuration ([[GrantMe Claude Code Configuration]]).

## The core idea: budget the always-loaded context

Every token in the always-loaded layer is paid on every turn. So the layering rule is:

| Layer | Loaded | Holds |
|---|---|---|
| `CLAUDE.md` | Always | Project overview, quick-reference commands, architecture map, key conventions, pointers to everything else |
| `.claude/rules/*.md` | Always | Short, imperative rules that prevent the codebase's recurring bugs |
| `.claude/docs/*.md` | On demand (Claude reads when relevant) | Large reference material: full entity model, API surface, business workflows, dark-mode reference, e2e setup |
| `.claude/agents/*.md` | When the agent is invoked | Role-specialized system prompts |
| `.claude/commands/*.md` | When the slash command runs | Scripted multi-phase workflows |
| `.claude/agent-memory/*/MEMORY.md` | Always (per agent) | Accumulated project gotchas — see [[Claude Code Agent Memory Pattern]] |

The discipline mirrors this vault's own [[Hot Cache]]: keep the hot, always-present layer small and curated; push everything else behind an explicit fetch.

## Rules as a bug catalog, not a style guide

GrantMe's rules are written as "these rules prevent the most common bugs found in this codebase." Each rule is concrete and testable, often with a CORRECT/WRONG code pair. Examples: always filter queries by `OrganisationId` (IDOR), Mantine v8 DatePicker uses `string` not `Date`, no React hooks after an early return, `DateTime.UtcNow` not `.Now`. This makes rules earn their always-loaded cost: each one buys back a class of regressions.

A useful corollary: a rule belongs in the always-loaded layer only if violating it is both common and expensive. Everything explanatory goes in `docs/` (read on demand) instead.

## The version-control boundary

A deliberate split governs what is shared vs personal:

- **Version-controlled (shared with the team)**: `CLAUDE.md`, `agents/`, `commands/`, `rules/`, `docs/`. These are the team's collective operating manual.
- **Gitignored (per-developer)**: `agent-memory/` and `settings.local.json`. Memory builds up per person; permissions are per machine.

GrantMe's `DEVELOPER-GUIDE.md` documents the recommended `settings.local.json` allowlist (git, build tools, Azure DevOps CLI, context7) and a `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50` tip to compact context earlier and preserve working memory on long sessions.

## Why it compounds

The configuration is not static documentation. Rules and docs are updated as part of `/finish-issue` whenever behavior changes; agent memory is updated continuously by the agents themselves. The setup gets better at the project the more it is used. This is the same compounding thesis as [[Compounding Knowledge]], applied to project tooling rather than a wiki.

## Transferable checklist

1. Keep `CLAUDE.md` a thin index; push reference detail to on-demand `docs/`.
2. Promote a convention to an always-loaded rule only when its violation is common and costly; write it as a CORRECT/WRONG pair.
3. Specialize agents by role and assign model tiers (cheap model for implementation, strong model for review).
4. Script the repetitive workflow (start work, finish/PR) as commands so the human focuses on the actual problem. See [[Plan-Implement-Review Agent Workflow]].
5. Separate shared config (committed) from personal memory and permissions (gitignored).
6. Update docs/rules/memory as a phase of finishing work, not as an afterthought.
