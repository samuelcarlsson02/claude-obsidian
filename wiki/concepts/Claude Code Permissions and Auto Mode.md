---
type: concept
title: "Claude Code Permissions and Auto Mode"
created: 2026-06-04
updated: 2026-06-04
address: c-000008
tags:
  - concept
  - claude-code
  - permissions
  - security
  - configuration
status: developing
complexity: intermediate
domain: claude-code
aliases:
  - "auto mode"
  - "permission modes"
  - "allow ask deny"
related:
  - "[[Claude Code Project Configuration]]"
  - "[[GrantMe Claude Code Configuration]]"
  - "[[GrantMe]]"
---

# Claude Code Permissions and Auto Mode

How Claude Code decides whether a tool call runs, prompts, or is blocked: a layered system of permission modes, rule lists (`allow` / `ask` / `deny`), and (in auto mode) a background safety classifier. Documented from official docs (code.claude.com, 2026-06) plus a real consolidation of per-repo allowlists into one global config.

## Permission modes

| Mode | Behavior |
|------|----------|
| `default` | Prompts on first use of each tool |
| `acceptEdits` | Auto-accepts file edits and common filesystem commands in the working directory |
| `plan` | Read-only; no edits |
| `auto` | Auto-approves via a background safety classifier; blocks destructive or outward-facing actions (research preview) |
| `dontAsk` | Auto-denies unless pre-approved by rules |
| `bypassPermissions` | Skips all checks; only for isolated environments |

Switch with Shift+Tab in a session, `claude --permission-mode <mode>`, or `"defaultMode"` in settings.

## Auto mode: the classifier as a second gate

Auto mode sits between `acceptEdits` and `bypassPermissions`. Every tool call follows a fixed decision order:

1. `permissions.deny` and `permissions.allow` rules resolve immediately (deny first).
2. Read-only actions auto-approve without classifier review: Grep/Read/Glob, read-only Bash (`ls`, `cat`, `grep`, `find`, `head`, `tail`, `wc`, `which`, `diff`, read-only `git`), working-directory edits, and the `acceptEdits` filesystem set (`mkdir`, `touch`, `mv`, `cp`, `sed`).
3. Everything else routes to the classifier: builds, tests, installs, network calls, pushes, anything outside the working directory.
4. Blocked by default regardless: `curl | bash` patterns, force push / push to main, production deploys, sending sensitive data externally, destroying pre-session files, IAM grants.

Key behaviors:

- **Blanket allow rules are stripped in auto mode**: `Bash(*)`, wildcarded interpreters like `Bash(python*)`, package-manager run commands, and `Agent` rules are ignored. Narrow rules like `Bash(npm test)` survive and short-circuit the classifier.
- The `autoMode` config block (environment / allow / soft_deny / hard_deny) is read from user settings, `settings.local.json`, or managed settings, but **not** from the shared project `settings.json`. A cloned repo cannot inject its own auto-mode rules.
- When an action is genuinely ambiguous the classifier blocks rather than asks.
- Inspect with `claude auto-mode config | defaults | critique`.

## Rule precedence and settings layering

Precedence within the rule lists: **`deny` > `ask` > `allow`**. The `allow`/`ask`/`deny` arrays from all settings files **merge** (user + project + local); they do not override each other. A deny anywhere beats an allow anywhere.

Practical consequences:

- Rules in `~/.claude/settings.json` apply in every repo and folder. This is the right home for generic allows (read-only shell tools, git, build runners) and for the secrets deny list.
- Per-repo `settings.local.json` files are self-maintaining: "Yes, don't ask again" approvals append there. They regrow on top of the global base and need no manual curation.
- Local allow rules cannot be revoked by the global file; only a global `deny`/`ask` overrides them. A leftover `Bash(rm *)` in a repo's local file stays active until that file is cleaned.

## The three-tier git pattern

Listing every safe git subcommand causes prompt fatigue; a blanket `git *` silently allows `reset --hard`, `clean -fd`, `checkout -- .`. The `ask` tier resolves the tension:

| Tier | Rules | Effect |
|------|-------|--------|
| allow | `Bash(git *)`, `PowerShell(git *)` | Daily git work runs silently |
| ask | `git reset --hard*`, `git clean*`, `git restore*`, `git checkout -- *`, `git branch -D*`, `git push --delete*` | Destructive prefixes always prompt, even though `git *` allows |
| deny | `git push --force*`, `git push -f*` | Cannot run at all, even with a yes click |

This preserves the user veto exactly where data loss is possible. `git checkout -- .` prompts while `git checkout feature-branch` does not, a distinction a narrow allow list cannot express.

## Caveats and design rules

- **Bash rules are prefix-matched, not a security boundary.** `git push origin +main` is a force push that evades a `git push --force*` deny. Treat command denies as guardrails against accident, not against adversaries. File rules (`Read(...)`) are more reliable.
- **Mirror rules across shells.** On Windows both `Bash(...)` and `PowerShell(...)` rules are live; a deny written only for Bash leaves the PowerShell path open.
- **Watch generic escape hatches.** `az devops invoke *` can call any Azure DevOps API including DELETEs, bypassing subcommand-level denies. Prefer narrow subcommand allows (`az repos pr create *`) and let the escape hatch prompt.
- **Scope CLI allows below the dangerous verbs**: `gh pr *` / `gh release create *` rather than `gh *` (which would cover `gh repo delete`).
- **Deny means fully blocked with no prompt option.** Reserve it for things never wanted (force push, secrets reads); use `ask` for things sometimes wanted.
- **Highest-value denies target secrets, not commands**: `Read(**/.env)`, `Read(**/.env.*)`, `Read(**/*.pem)`, `Read(**/*.pfx)`, `Read(**/*.key)`, `Read(~/.ssh/**)`, `Read(~/.azure/**)` (az CLI token cache). Trade-off: debugging an `.env` issue requires temporarily lifting the rule.
- The biggest residual trust grants in a typical dev allowlist are `git *` (working-tree destruction, mitigated by the ask tier) and `npx *` (downloads and executes arbitrary npm code).

## Relation to project configuration

[[Claude Code Project Configuration]] covers the version-control boundary: `settings.local.json` is gitignored and per-developer. This page adds the vertical dimension: which rules belong at the user level (generic tools, secrets denies, the ask tier) versus accumulating per-repo. The [[GrantMe Claude Code Configuration]] allowlist served as the source material for the consolidation.
