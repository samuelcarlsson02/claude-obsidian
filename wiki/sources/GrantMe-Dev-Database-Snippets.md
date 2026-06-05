---
type: source
title: "GrantMe Dev Database Snippets"
created: 2026-06-04
updated: 2026-06-04
address: c-000009
source_files:
  - ".raw/create backup, drop and restore db.txt"
  - ".raw/insert 50 org users.sql"
  - ".raw/kill con rename db.sql"
  - ".raw/kill con reset db.sql"
  - ".raw/reinstall npm dependencies.txt"
ingested: 2026-06-04
source_type: snippets
tags:
  - source
  - snippet
  - sql-server
  - grantme
  - runbook
status: current
related:
  - "[[GrantMe]]"
  - "[[GrantMe Claude Code Configuration]]"
---

# GrantMe Dev Database Snippets

Five small operational snippets for [[GrantMe]] local development on Windows: four T-SQL scripts for managing the local `[Grantme]` SQL Server database and one cmd sequence for resetting npm dependencies. Batch-ingested as one source page; the actionable commands are folded into the runbook on [[GrantMe]] §Local Development Commands.

## The common primitive: kill connections first

Three of the four SQL snippets share the same prerequisite: SQL Server refuses to drop or rename a database while connections are open (`dotnet watch`, SSMS, Azure Functions all hold them). The snippets solve it with `WITH ROLLBACK IMMEDIATE`, which kills open connections and rolls back their transactions:

- `SET OFFLINE WITH ROLLBACK IMMEDIATE` then `SET ONLINE` — a bounce that sheds all connections before `DROP DATABASE`
- `SET SINGLE_USER WITH ROLLBACK IMMEDIATE` — claims the only remaining connection before `MODIFY NAME`, then `SET MULTI_USER` restores normal access

## 1. Backup, drop, restore (`create backup, drop and restore db.txt`)

Full reset cycle with a safety net. Backup goes to `C:\Users\Samuel\Documents\Grantme\Dev\backups db\Grantme_backup.bak`.

```sql
-- Step 1: Backup first
BACKUP DATABASE [Grantme]
TO DISK = 'C:\Users\Samuel\Documents\Grantme\Dev\backups db\Grantme_backup.bak'
WITH FORMAT;

-- Step 2: Drop it
ALTER DATABASE [Grantme] SET OFFLINE WITH ROLLBACK IMMEDIATE;
ALTER DATABASE [Grantme] SET ONLINE;
DROP DATABASE [Grantme];

-- Step 3: When ready, restore it
RESTORE DATABASE [Grantme]
FROM DISK = 'C:\Users\Samuel\Documents\Grantme\Dev\backups db\Grantme_backup.bak';
```

`WITH FORMAT` overwrites the backup file in place, so this keeps exactly one restore point.

## 2. Drop without backup (`kill con reset db.sql`)

The destructive subset of the above; used when the DB will be recreated from migrations/seed instead of restored.

```sql
ALTER DATABASE [Grantme] SET OFFLINE WITH ROLLBACK IMMEDIATE;
ALTER DATABASE [Grantme] SET ONLINE;
DROP DATABASE [Grantme];
```

## 3. Rename aside (`kill con rename db.sql`)

Non-destructive alternative to dropping: shove the current DB aside as `[GrantmeOld]` so a fresh `[Grantme]` can be created while keeping the old data inspectable.

```sql
ALTER DATABASE [Grantme] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
ALTER DATABASE [Grantme] MODIFY NAME = [GrantmeOld];
ALTER DATABASE [GrantmeOld] SET MULTI_USER;
```

## 4. Seed 50 reviewer users (`insert 50 org users.sql`)

Test-data generator for reviewer-scaling scenarios (e.g. reviewer lists, review assignment UI). Inserts 50 users named `Granskare{i} Testsson{i}` (Swedish: "granskare" = reviewer) with emails `reviewer{i}@test.grantme.se`, each linked to the hardcoded organisation `A69C09C8-1451-4C7D-9417-49B70C2D6AAA` via `[OrganisationUsers]`.

Field choices worth knowing:
- `InvitationStatus = 2` (accepted) — users appear active without an invite flow
- `[OrganisationUsers].Role = 0` — the default/member role
- `AzureAdObjectId = NEWID()` — fake AAD identity; these users cannot actually log in via B2C
- Both notification flags (`IsReviewReminderEnabled`, `IsDecisionNotificationEnabled`) set to 1

This is a direct illustration of the **Organisation-as-tenant** model documented on [[GrantMe]]: a bare `[Users]` row is invisible to the app until an `[OrganisationUsers]` row scopes it to a tenant.

## 5. Reinstall npm dependencies (`reinstall npm dependencies.txt`)

The nuke-and-pave for a broken `node_modules` in any of the four frontend apps (cmd syntax):

```bat
rmdir /s /q node_modules
del package-lock.json
npm cache clean --force
npm install
```

Deleting `package-lock.json` means dependencies re-resolve to latest in-range versions, so this can surface (or fix) version drift; it is a reset, not a clean reinstall of the locked state.

## Cross-references

- [[GrantMe]] — runbook section updated with these commands
- [[GrantMe Claude Code Configuration]] — the `.claude/` kit these workflows live alongside; `taskkill /F /IM dotnet.exe /T` from that ingest is the process-level sibling of the connection-killing pattern here
