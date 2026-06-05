---
description: Quick-capture a todo for any registered project, optionally tied to a work item id.
---

Read the `todo` skill (`.claude/skills/todo/SKILL.md`) and the project registry (`wiki/todos/projects.md`). Then run the skill with these arguments: $ARGUMENTS

Usage:
- `/todo 1000 add button in left corner` — add to work item 1000 in the DEFAULT project
- `/todo myapp 42 fix login` — add to work item 42 in project `myapp`
- `/todo myapp clean up readme` — add to project `myapp`'s inbox (no work item)
- `/todo fix the deploy script` — add to the global inbox (no project, no work item)
- `/todo 1000` — list open todos for work item 1000 (default project)
- `/todo myapp` — list all open todos in project `myapp`
- `/todo` — overview of all open todos across projects
- `/todo done 1000 button` — mark the matching todo as done
- `/todo done myapp 42 login` — same, scoped to another project

Projects and the default are defined in `wiki/todos/projects.md` — adding a project there is the only setup step.

Capture must be fast: parse, lock, append, release, confirm in one line. No questions unless a `done` fragment is ambiguous or an explicit `@project` is unknown.
