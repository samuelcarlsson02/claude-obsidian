---
type: meta
title: "Hot Cache"
updated: 2026-06-05T12:00:00
tags:
  - meta
  - hot-cache
status: evergreen
related:
  - "[[index]]"
  - "[[log]]"
  - "[[Wiki Map]]"
  - "[[getting-started]]"
  - "[[DragonScale Memory]]"
---

# Recent Context

Navigation: [[index]] | [[log]] | [[overview]]

## Last Updated

2026-06-05 (latest): **Built the `/todo` quick-capture skill and saved [[2026-06-05-todo-skill-design]]** (decision, c-000010). `/todo [project] [id] <message>` appends Obsidian Tasks lines to one file per work item per project (`wiki/todos/<project>/WI-<id>.md`); queries read those files, `/todo done <fragment>` checks off. Multi-project via a registry (`wiki/todos/projects.md`: default `grantme`, `url_template` with `{id}`, aliases) chosen over per-project commands (`/todo-grantme`); `repo_path` reserved for future cwd auto-detect. Captures deliberately skip index/log/hot (a todo is not an ingest) and bypass the mode router (operational state, not knowledge). New skill #16; files: `.claude/skills/todo/SKILL.md`, `.claude/commands/todo.md`, `wiki/todos/` (filed under `.claude/` because the installed plugin loads from the upstream marketplace clone, not this working copy — root `skills/`/`commands/` placement only takes effect once merged upstream).

Earlier 2026-06-04: **Batch-ingested [[GrantMe Dev Database Snippets]]** (c-000009): 5 tiny `.raw/` snippets filed as ONE combined source page. Four T-SQL scripts for the local `[Grantme]` SQL Server DB (backup/drop/restore, drop-only, rename-aside to `[GrantmeOld]`, seed 50 reviewer users into org `A69C09C8-…`) plus the cmd npm nuke-and-pave (`rmdir node_modules` / `del package-lock.json` / `npm cache clean --force` / `npm install`). Common primitive: `WITH ROLLBACK IMMEDIATE` kills open connections before drop/rename. [[GrantMe]] runbook extended with DB management + test-data + npm recovery subsections. Manifest now tracks all 5 files; counter at 10.

Earlier 2026-06-04: **Updated [[GrantMe]] with a Local Development Commands runbook.** Backend `dotnet watch run --project Backend/Grantme.API`; four frontends via `npm start` (admin 3001, client, management 3003, www); `azurite` then `func start` in `Backend/Grantme.Functions`; trunk is `master` (`git pull origin master`, `git push -u origin HEAD`); recovery via `taskkill /F /IM dotnet.exe /T`. Repo root: `C:\Users\Samuel\Documents\Git Repositories\Grantme`.

Earlier 2026-06-04: **Saved [[Claude Code Permissions and Auto Mode]]** (concept, c-000008). Permission modes incl. the auto-mode classifier, deny > ask > allow precedence with cross-file merging, the three-tier git pattern (allow `git *`, ask on destructive prefixes, deny force push), secrets-first deny lists, prefix-matching caveats. Source: a live consolidation of the [[GrantMe]] settings.local.json allowlist into global user settings. Extends the Claude Code config-engineering thread from the [[GrantMe Claude Code Configuration]] ingest.

2026-06-01: **Ingested GrantMe Claude Code Configuration.** A complete real-world `.claude/` kit (root CLAUDE.md + 4 agents, 4 commands, 6 rules, 5 docs, 4 agent-memory stores) from the GrantMe SaaS (.NET 9 + React grant management for Swedish foundations, by LogicInjection). Created 4 pages: [[GrantMe]] (entity), [[Claude Code Project Configuration]], [[Claude Code Agent Memory Pattern]], [[Plan-Implement-Review Agent Workflow]]. Source summary at [[GrantMe Claude Code Configuration]]. This is the first source in the vault that is *about a different domain* yet directly exercises the vault's own theses: always-loaded rules vs on-demand docs mirrors [[Hot Cache]]; per-agent `MEMORY.md` mirrors [[Compounding Knowledge]].

Earlier 2026-06-01: KB-layer refresh reconciled hot/index/log with git history up to v1.9.2 (no code change).

## Environment Note

`flock` is NOT available in this Git Bash environment (Git for Windows / MSYS2 ships no util-linux flock). This previously broke both `scripts/allocate-address.sh` and `scripts/wiki-lock.sh`. **Fixed 2026-06-01**: both now prefer flock when present and fall back to an atomic `mkdir` spinlock (age-based stale reaper, EXIT-trap release) when it is absent. `VAULT_LOCK_NO_FLOCK=1` forces the fallback for CI. The allocator works again here (counter at 8); no manual address-reservation workaround is needed anymore. All three lock/concurrency test suites pass natively and with the fallback forced.

## Plugin State

- **Version**: 1.9.2, promoted to **public canonical** (commit `00213b7`, 2026-05-28). The public build `AgriciDaniel/claude-obsidian` is now the default install everywhere; AI Marketing Hub Pro repositioned as early-access to in-development features.
- **Working tree**: clean as of this refresh.
- **Install slug**: `claude-obsidian@agricidaniel-claude-obsidian` (public). Pro swap: `claude-obsidian@ai-marketing-hub-claude-obsidian`.
- **Org**: migrated `AgriciDaniel/AI-Marketing-Hub`; author attribution preserved as AgriciDaniel.
- **Skills**: 15. v1.8 added `wiki-mode` (#14); v1.9.0 added `think` (#15, the 10-principle loop).
- **Tests**: `make test` runs **9** hermetic suites green (~1234 assertions). Zero ollama / zero network dependency for core tests.

## What Shipped v1.8 → v1.9.2

- **v1.8.0** (2026-05-17): methodology modes. New `wiki-mode` skill + `scripts/wiki-mode.py` router + `bin/setup-mode.sh`. Four modes: generic (v1.7 default, byte-for-byte), LYT, PARA, Zettelkasten. Closes the 5th and final compass priority gap. #1 on 5/7 compass axes (up from 4/7).
- **v1.8.1 / v1.8.2** (2026-05-18): ship-gate + pre-push audit fixes. transport manual_override round-trips through `--force`; autoresearch web-egress hygiene section; save Step 0 destination decision; wiki-ingest mode awareness.
- **v1.9.0** (2026-05-18): audit closure + **10-principle thinking framework**. New `skills/think/SKILL.md`; a unique "How to think" appendix added to all 14 existing skills. First public-release hygiene: CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, issue/PR templates, GitHub Actions CI. Org URL migration across 20 files.
- **v1.9.1** (2026-05-18): single-tenant threat model in SECURITY.md (unconditional lock release, auto-commit opt-out via `.vault-meta/auto-commit.disabled`, filesystem-permission trust boundary). 6 HIGH/MEDIUM + 3 LOW closed; score 91.6 → ~94. Also a batch of hook/data hardening (atomic chunk writes, pathspec-scoped auto-commit, stale-lock reaper, symlink canon).
- **v1.9.2** (2026-05-27, public 2026-05-28): prompt-cache hardening in `scripts/contextual-prefix.py` (the only Anthropic API call site): `cache_control` only above the Haiku 4.5 floor (`HAIKU_CACHE_MIN_CHARS = 16384`), integer-only cache telemetry, sequential-loop invariant note. Path handling: missing path exits 3, out-of-vault exits 2. Plus SSS+ polish (CITATION.cff, PRIVACY.md, CODEOWNERS, FUNDING.yml) and a DataForSEO-backed SEO/GEO pass on the README.

## DragonScale Mechanisms (unchanged since v1.6)

All four shipped and opt-in: (1) fold operator, (2) deterministic addresses (counter at 3), (3) semantic tiling lint, (4) boundary-first autoresearch. Feature-gated by `[ -x script ] && [ -f state ]`.

## Style Preferences

- No em dashes (U+2014) or `--` as punctuation. Periods, commas, colons, or parentheses. Hyphens in compound words are fine.
- Short and direct responses. No trailing summaries.
- Parallel tool calls when independent.

## Active Threads

- KB layer current as of v1.9.2 / 2026-06-01. Next ingest or release should append to log.md and overwrite this cache.
- The vault tracks the plugin's own development plus the LLM Wiki pattern / Claude+Obsidian ecosystem. As of 2026-06-01 it also holds a Claude Code config-engineering thread (the [[GrantMe]] ingest): see the three new "Claude Code" concepts in [[concepts/_index]]. Future ingests of other teams' `.claude/` kits would deepen this thread.

## Repo Locations

- Public canonical: https://github.com/AgriciDaniel/claude-obsidian
- Pro / early-access: https://github.com/AI-Marketing-Hub/claude-obsidian
