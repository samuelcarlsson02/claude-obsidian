---
type: meta
title: "Hot Cache"
updated: 2026-06-01T00:00:00
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

2026-06-01: **KB-layer refresh.** The wiki's own self-documentation had drifted: hot.md/index.md/log.md stopped tracking at v1.7.1 (2026-05-17) while the plugin shipped through v1.9.2. This pass reconciles them with git history. No code changed; only the meta layer (hot, index, log) was brought current.

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

- KB layer is now current as of v1.9.2 / 2026-06-01. Next ingest or release should append to log.md and overwrite this cache.
- The vault tracks the plugin's own development plus the LLM Wiki pattern / Claude+Obsidian ecosystem. No new subject-matter concept pages since v1.6; v1.8/v1.9 work lives in skills, scripts, docs, and audit records.

## Repo Locations

- Public canonical: https://github.com/AgriciDaniel/claude-obsidian
- Pro / early-access: https://github.com/AI-Marketing-Hub/claude-obsidian
