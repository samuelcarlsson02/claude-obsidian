---
type: decision
title: "Todo Skill Design"
created: 2026-06-05
updated: 2026-06-05
address: c-000010
decision_date: 2026-06-05
tags:
  - decision
  - skill-design
  - todo
  - quick-capture
status: active
related:
  - "[[GrantMe]]"
  - "[[Todo Projects Registry]]"
  - "[[Claude Code Project Configuration]]"
  - "[[Plan-Implement-Review Agent Workflow]]"
---

# Todo Skill Design

The vault now ships a `/todo` skill for quick-capturing todos tied to tracker work items. Built 2026-06-05; three design decisions were made along the way, each with rationale worth keeping.

## What it is

`/todo [project] [id] <message>` appends an Obsidian Tasks line (`- [ ] msg ➕ date`) to one file per work item per project: `wiki/todos/<project>/WI-<id>.md`. Queries (`/todo 1000`, `/todo myapp`, `/todo`, or natural language: "what do I have todo on work item 1000") read those files; `/todo done <fragment>` checks items off with `✅ date`. Files: `.claude/skills/todo/SKILL.md`, `.claude/commands/todo.md`, `wiki/todos/projects.md`, `wiki/todos/_index.md`. (Originally placed at repo-root `skills/`/`commands/`, but the installed plugin loads from the upstream marketplace clone — local additions only register via project `.claude/`. Moved 2026-06-05.)

## Decision 1: Skill + command, not command alone

A command (`commands/todo.md`) fires only when literally typed. A skill's description sits in context, so Claude self-triggers it from natural language. Capture works with the command alone; the query half ("what's left on work item 1000?" asked mid-conversation) requires the skill, because without it nothing in context says the `wiki/todos/` layout exists. The split also matches the repo convention: every command (save, autoresearch, canvas, wiki) is a thin wrapper over a skill, and slash-command files are injected verbatim per use while skills load on demand, so the bulky workflow belongs in the skill.

## Decision 2: One file per work item per project

`wiki/todos/grantme/WI-1000.md` makes "what's on 1000?" a single predictable read, no search needed. Todos are operational state, not knowledge pages: the methodology-mode router (v1.8) is deliberately NOT consulted, and captures deliberately skip `index.md` / `log.md` / `hot.md` (a todo is not an ingest; logging every capture would drown the signal). Only `wiki/todos/_index.md` is touched, and only when a new work-item file is born. Locks still apply like any wiki write.

## Decision 3: Single `/todo` + project registry, not per-project commands

Three options were weighed for multi-project support:

1. **Single `/todo` + registry** (chosen): `wiki/todos/projects.md` frontmatter maps project keys/aliases to `tracker` + `url_template` (`{id}` substituted) and declares a default project. `/todo 1000 msg` hits the default (grantme); `/todo myapp 42 msg` routes by first-token match; new project = one YAML block, no restart.
2. **Per-project commands** (`/todo-grantme`, `/todo-myapp`): zero parsing ambiguity and per-project autocomplete, but a new command file + session restart per project, more typing for the most-frequent project, and a registry is needed anyway for natural-language queries to know which projects exist.
3. **cwd auto-detect**: infer project from the working directory when the plugin is installed globally. Useless when capturing for project B while sitting in project A, so it can only ever be an enhancement, not the design. A `repo_path` field is reserved in the registry for this later.

Parsing ambiguity (message starting with a project name) is accepted as rare; `@project` is the unambiguous escape hatch, and an unknown `@project` asks once instead of silently filing to default.

## Current registry state

Default project: `grantme` ([[GrantMe]], Azure DevOps `logicinjection/Grantme`, work-item URL template `https://dev.azure.com/logicinjection/Grantme/_workitems/edit/{id}`). Title enrichment on new files is tracker-aware (az boards / gh issue view), tried once, never blocking.
