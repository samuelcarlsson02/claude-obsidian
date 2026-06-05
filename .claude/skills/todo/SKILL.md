---
name: todo
description: >
  Quick-capture todos into the wiki vault, tied to work items / issues across any
  registered project (GrantMe Azure DevOps, GitHub repos, Jira, ...). One todo file per
  work item per project makes "what do I have todo on work item 1000?" a single-file
  read. Triggers on: "/todo", "todo:", "add a todo",
  "what do I have todo on work item [id]", "what's left on [id]",
  "what do I have todo in [project]", "mark todo done", "show my todos", "open todos".
allowed-tools: Read Write Edit Glob Grep Bash
---

# todo: Quick Capture Tied to Project Work Items

Capture must be fast. One line in, one line out. No naming questions, no index ceremony, no log noise. The payoff comes at query time: every todo for a work item lives in one predictable file.

**Project registry:** `wiki/todos/projects.md` — YAML frontmatter maps project names/aliases to tracker URL templates and declares the **default project**. ALWAYS read it first; never hardcode a project. Currently the default is `grantme` ([[GrantMe]], Azure DevOps `logicinjection/Grantme`), but the registry is the source of truth.

---

## Argument Parsing

Input is everything after `/todo`. Resolve in this order:

1. **`done` keyword first?** → Done workflow (below); keep parsing the rest for project/id.
2. **First token matches a registry project key or alias?** → that project; consume the token. An explicit `@project` prefix also works and is never ambiguous.
3. **Otherwise** → the **default project** from the registry.
4. **Next token all digits?** → work item id; consume it.
5. **Everything left** → the todo message.

| Input | Resolution |
|---|---|
| `1000 add button in left corner` | default project, WI 1000, add |
| `myapp 42 fix login` | project `myapp`, WI 42, add |
| `myapp clean up readme` | project `myapp`, no id → project inbox |
| `buy coffee` | no project match, no id → **global inbox** |
| `1000` | default project, WI 1000 → **query** |
| `myapp` | project `myapp` → **query** all its open todos |
| *(empty)* | **query** overview, all projects |
| `done 1000 button` | default project, WI 1000, complete matching todo |
| `done myapp 42 login` | project `myapp`, WI 42, complete matching todo |

Natural-language triggers ("what do I have todo on work item 1000", "anything left in myapp?") map to the query forms. A bare work-item number with no project means the default project.

---

## File Layout

```
wiki/todos/
  projects.md           project registry (source of truth)
  _index.md             navigation — one section per project
  inbox.md              global todos belonging to no project
  grantme/
    WI-1000.md          all todos for GrantMe work item 1000
    inbox.md            GrantMe todos with no work item
  myapp/
    WI-42.md
    ...
```

This layout is **fixed** — the methodology-mode router (v1.8) is NOT consulted. Todos are operational state, not knowledge pages; they live in `wiki/todos/` in every mode.

---

## Capture Workflow (add a todo)

1. **Read the registry** (`wiki/todos/projects.md` frontmatter), then **parse** project, id, message.
2. **Resolve path**: `wiki/todos/<project>/WI-<id>.md`; no id → `wiki/todos/<project>/inbox.md`; no project → `wiki/todos/inbox.md`.
3. **Get today's date**: `date +%F` (never assume).
4. **Lock, append, release** (v1.7 concurrency rules apply to todos like any wiki page):

   ```bash
   NOTE_PATH="wiki/todos/grantme/WI-1000.md"
   bash scripts/wiki-lock.sh acquire "$NOTE_PATH" || { echo "locked by another writer, retry"; exit 0; }
   # … create-or-append via the transport-selected method …
   bash scripts/wiki-lock.sh release "$NOTE_PATH"
   ```

5. **If the file is new**, create it from the template below (URL from the registry's `url_template`, `{id}` substituted), then add one line under that project's section in `wiki/todos/_index.md` (also under lock): `- [[todos/grantme/WI-1000|WI-1000]] — <title or "untitled">`. New project folder → also add a `## <project>` section to `_index.md`.
6. **Append** the todo under `## Open` using Obsidian Tasks syntax:

   ```markdown
   - [ ] add button in left corner ➕ 2026-06-05
   ```

7. **Confirm in ONE line**: `Added to grantme WI-1000: "add button in left corner" (3 open)`.

**Deliberately skipped on capture**: `wiki/index.md`, `wiki/log.md`, `wiki/hot.md`. A todo is not an ingest; logging every capture would drown the signal. Only `wiki/todos/_index.md` is touched, and only when a new work-item file is born.

**Unknown project guard**: if the user explicitly wrote `@something` that isn't in the registry, don't silently file to default — ask once whether to add it to the registry or treat it as message text.

### Optional title enrichment (new files only, never blocking)

When creating a new `WI-<id>.md`, you MAY try once, with a short timeout, using the tracker-appropriate command:

| `tracker` | Command |
|---|---|
| `azure-devops` | `az boards work-item show --id <id> --org <org-url> --query "fields.\"System.Title\"" -o tsv` |
| `github` | `gh issue view <id> --repo <owner/repo> --json title -q .title` |
| `jira` / `none` | skip |

If the CLI is missing, unauthenticated, or slow — use `WI-<id>` as the title and move on. Capture speed beats metadata.

---

## File Template

```markdown
---
type: todo
title: "WI-1000 — <tracker title if known>"
project: grantme
work_item: 1000
tracker_url: "https://dev.azure.com/logicinjection/Grantme/_workitems/edit/1000"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - todo
  - grantme
status: open
related:
  - "[[GrantMe]]"
---

# WI-1000 — <title>

[Open in tracker](https://dev.azure.com/logicinjection/Grantme/_workitems/edit/1000)

## Open

- [ ] first todo ➕ YYYY-MM-DD

## Done

```

- `related:` gets the registry's `entity` link when present.
- Inbox files use the same shape minus `work_item`/`tracker_url`; titles `Todo Inbox — <project>` / `Todo Inbox` (global).
- On every append, bump `updated:` in frontmatter.

---

## Query Workflow

- **`/todo 1000`** or "what do I have todo on work item 1000": read `wiki/todos/<default>/WI-1000.md`. If absent, say so — don't create it. Show the `## Open` items; mention done count and the tracker link.
- **`/todo myapp`** or "what do I have todo in myapp": Glob `wiki/todos/myapp/*.md`, collect unchecked `- [ ]` lines grouped by work item, inbox last.
- **`/todo`** or "show my todos": same sweep across all of `wiki/todos/**/*.md` (skip `_index.md`, `projects.md`), grouped by project then work item, global inbox last. Fully-checked files are skipped.
- Answer from the files only. Do not call the tracker to answer a query unless asked.

## Done Workflow

`/todo done [project] [id] <text-fragment>`:

1. Resolve project/id as in capture; read the file, find the open todo best matching the fragment. Multiple plausible matches → ask which one. Zero → say so.
2. Under lock: move the line from `## Open` to `## Done`, flip to `- [x]`, append `✅ <today>`.
3. If `## Open` is now empty, set frontmatter `status: closed`.
4. Confirm in one line.

---

## How to think (10-principle mapping)

See [`skills/think/SKILL.md`](../think/SKILL.md) for the canonical framework.

| # | Principle | Application here |
|---|-----------|-------------------|
| 1 | OBSERVE (ext) | Read the registry before parsing — project names are data, not code. A leading token is only a project if the registry says so. |
| 2 | OBSERVE (int) | Resist the urge to enrich, categorize, or rephrase. Capture is transcription, not synthesis. |
| 3 | LISTEN | "/todo 1000" with no message is a question, not an empty todo. An explicit `@project` outranks the default. |
| 4 | THINK | One file per work item per project is the whole retrieval strategy — never scatter todos across session notes. |
| 5 | CONNECT (lat) | The registry's `entity` link and `tracker_url` tie each todo file into the entity graph. |
| 6 | CONNECT (sys) | Locks still apply — a todo append races with ingest like any other write. |
| 7 | FEEL | The one-line confirmation is the UX. Anything longer makes quick capture not quick. |
| 8 | ACCEPT | No tracker auth? Fine. WI-number titles are good enough; don't block capture on metadata. |
| 9 | CREATE | Append the task line, keep Tasks-plugin syntax so Obsidian can query it too. |
| 10 | GROW | Recurring inbox themes may deserve a registry entry or a real tracker item — surface that, don't auto-create it. |
