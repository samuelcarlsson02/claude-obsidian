---
type: concept
title: "Claude Code Agent Memory Pattern"
created: 2026-06-01
updated: 2026-06-01
address: c-000006
tags:
  - concept
  - claude-code
  - memory
  - compounding-knowledge
status: developing
complexity: intermediate
domain: claude-code
aliases:
  - "agent-memory"
  - "per-agent MEMORY.md"
related:
  - "[[GrantMe Claude Code Configuration]]"
  - "[[Claude Code Project Configuration]]"
  - "[[Compounding Knowledge]]"
  - "[[Hot Cache]]"
  - "[[Persistent Wiki Artifact]]"
---

# Claude Code Agent Memory Pattern

A persistent, file-based memory each sub-agent owns and maintains across conversations: `.claude/agent-memory/<agent-name>/MEMORY.md` plus topic files it links from there. Documented from the [[GrantMe]] configuration ([[GrantMe Claude Code Configuration]]), where all four agents declare `memory: project` in frontmatter.

## How it works

- Each agent has a directory: `agent-memory/planner/`, `agent-memory/dotnet-backend-engineer/`, etc.
- `MEMORY.md` is **always loaded into that agent's system prompt** (GrantMe caps it: "lines after 200 will be truncated, so keep it concise"). It is the agent's hot layer, analogous to this vault's [[Hot Cache]].
- Detail spills into **topic files** (`signalr.md`, `project_sbs_import.md`, `feedback_ttag_update.md`) linked from `MEMORY.md`. The index-plus-topic shape keeps the always-loaded file small while detail stays one read away.
- Agents are instructed to **organize memory semantically by topic, not chronologically**, and to **update or remove memories that turn out to be wrong**. Memory is curated, not append-only.
- Memory is **project-scoped and gitignored** (per-developer). It is the personal counterpart to the shared rules/docs in [[Claude Code Project Configuration]].

## What actually accumulates

The value is the knowledge that no quick code-read would surface. From GrantMe:

- **The reviewer's memory** is a living defect register: recurring `DateTime.Parse` culture bugs, a flawed reversal-amount sum, an aggregation bug where SBS-imported requisitions double-count unless filtered by `Type == Application`, and a SignalR topic file cataloging production-readiness gaps (no backplane, global TLS bypass, `[AllowAnonymous]` notify endpoint).
- **The backend engineer's memory** holds EF Core migration recipes (the org-per-default-template pattern for adding non-nullable template FK columns) and DI/queue wiring conventions.
- **The frontend engineer's memory** holds Mantine/Orval gotchas (generated types that disagree with backend responses, the `customFetch` binary-download limitation) and the ttag quirk where new admin files need manual `en.po` entries.
- **The planner's memory** holds task-to-codebase mappings and reuse opportunities (canonical confirm-modal helpers, the agreement-wizard pattern to clone), so it stops re-asking questions the codebase already answers.

## Why it compounds (and the failure mode it avoids)

Without persistent memory, every session re-discovers the same gotchas, and hard-won findings evaporate when the context window resets. With it, the agent gets sharper at *this* project over time, exactly the [[Compounding Knowledge]] thesis applied at the agent level. The reviewer that already knows where the IDOR-prone aggregations live reviews faster and catches more.

The discipline that makes it work is the same one that makes a wiki work: curate, don't hoard. An always-loaded `MEMORY.md` that grows unbounded becomes pure context cost; the 200-line cap and the "update or remove wrong memories" instruction are what keep signal density high. This is the agent analogue of a [[Persistent Wiki Artifact]].

## Relationship to this vault's own memory

This pattern and the vault's `memory/` + `MEMORY.md` index are the same idea in two settings: a small always-loaded index, topic files behind it, semantic (not chronological) organization, and active pruning. The agent-memory layer is essentially a per-agent hot cache.
