---
type: meta
title: "Todo Projects Registry"
updated: 2026-06-05
tags:
  - meta
  - todo
  - config
status: evergreen
default: grantme
projects:
  grantme:
    tracker: azure-devops
    url_template: "https://dev.azure.com/logicinjection/Grantme/_workitems/edit/{id}"
    aliases:
      - gm
    entity: "[[GrantMe]]"
    # repo_path: reserved for future cwd auto-detect (plugin installed globally)
---

# Todo Projects Registry

Consumed by the `/todo` skill. The YAML frontmatter above is the source of truth — the skill reads it to resolve project names, build work-item URLs, and pick the default.

## How resolution works

- `/todo 1000 message` → **default** project (`grantme`)
- `/todo <project> 42 message` → that project, if the first token matches a key or alias here
- First token matches nothing here and isn't a number → the whole input is an inbox todo

## Adding a project

Add a block under `projects:`:

```yaml
  myapp:
    tracker: github            # azure-devops | github | jira | none
    url_template: "https://github.com/you/myapp/issues/{id}"
    aliases: [ma]
```

That's all — no new skill or command files. The skill creates `wiki/todos/myapp/` on first capture.

`tracker: none` is valid for projects without an issue tracker; ids are then optional free-form labels and no URL is generated.
