---
type: source
title: "GrantMe Claude Code Configuration"
created: 2026-06-01
updated: 2026-06-01
address: c-000003
tags:
  - source
  - claude-code
  - configuration
  - dotnet
  - react
status: current
source_type: data
author: "LogicInjection"
confidence: high
key_claims:
  - "A mature .claude/ directory layers always-loaded rules, on-demand docs, role-specialized agents, slash commands, and persistent per-agent memory."
  - "GrantMe runs a planner -> engineer -> reviewer agent workflow gated by /start-work and /finish-issue slash commands."
  - "Version-controlled config (agents, commands, rules, docs) is shared; agent-memory and settings.local.json are per-developer and gitignored."
related:
  - "[[GrantMe]]"
  - "[[Claude Code Project Configuration]]"
  - "[[Claude Code Agent Memory Pattern]]"
  - "[[Plan-Implement-Review Agent Workflow]]"
  - "[[Compounding Knowledge]]"
sources:
  - "[[.raw/Grantme claude files/CLAUDE.md]]"
---

# Source: GrantMe Claude Code Configuration

**Type**: Real-world `.claude/` project kit (configuration export)
**Origin**: GrantMe codebase by LogicInjection (`dev.azure.com/logicinjection/Grantme`)
**Ingested**: 2026-06-01
**Files**: 1 root `CLAUDE.md` + a complete `.claude/` tree (4 agents, 4 commands, 6 rules, 5 docs, 4 agent-memory stores, settings, developer guide)

## Summary

A full Claude Code configuration exported from a production .NET 9 + React grant-management SaaS. It is a working reference for how a sophisticated team operationalizes Claude Code: a layered context strategy (always-loaded rules vs read-on-demand docs), three role-specialized sub-agents plus a code reviewer, slash commands that script the daily Azure DevOps workflow end to end, and a persistent per-agent memory layer that accumulates project gotchas across sessions.

Distinct from the rest of this vault (which documents the claude-obsidian plugin and the LLM Wiki ecosystem), this source is valuable as a concrete, battle-tested instance of the same compounding-knowledge ideas applied to a different domain. The agent-memory layer in particular is a direct parallel to this vault's own [[Hot Cache]] and [[Compounding Knowledge]] thesis.

## Pages Created from This Source

- [[GrantMe]] — entity page for the platform, its domain model, and conventions
- [[Claude Code Project Configuration]] — concept: the layered `.claude/` blueprint
- [[Claude Code Agent Memory Pattern]] — concept: persistent per-agent memory
- [[Plan-Implement-Review Agent Workflow]] — concept: the planner/engineer/reviewer triad

## Key Findings

1. **Context budgeting is explicit.** `CLAUDE.md` + `.claude/rules/*.md` are always in context; `.claude/docs/*.md` (entities, API surface, workflows, dark mode, e2e) are read only on demand. The split keeps the always-loaded footprint small while large reference material stays one Read away.
2. **Agents are role-specialized with model tiers.** `planner` (Sonnet, no code), `dotnet-backend-engineer` (Sonnet), `frontend-engineer` (Sonnet), `fullstack-code-reviewer` (Opus). Each carries `memory: project`.
3. **Commands script the whole loop.** `/start-work <id>` fetches the Azure DevOps item, branches, and launches the planner; `/finish-issue` runs an 8-phase gate (build/lint -> review -> docs -> confirm -> commit -> PR -> Swedish test instructions -> move to Ready for test).
4. **Agent memory accumulates gotchas.** The four `agent-memory/*/MEMORY.md` files plus topic files record hard-won, project-specific knowledge (SignalR production gaps, EF Core migration patterns for template FKs, ttag/i18n quirks, IDOR aggregation bugs) that no amount of code-reading would surface quickly.
5. **Conventions encode the team's bug history.** Rules read as a catalog of "the most common bugs found in this codebase": IDOR via missing `OrganisationId` filter, Mantine v8 DatePicker `string` vs `Date`, React hooks after early return, `DateTime.Now` vs `UtcNow`, hardcoded colors breaking dark mode.
6. **Sharing boundary is deliberate.** Version-controlled: agents, commands, rules, docs, `CLAUDE.md`. Gitignored per-developer: `agent-memory/`, `settings.local.json`.

## Raw Files

`.raw/Grantme claude files/` — root `CLAUDE.md`, `.claude/DEVELOPER-GUIDE.md`, and the `agents/`, `commands/`, `rules/`, `docs/`, `agent-memory/`, `settings.local.json` tree.
