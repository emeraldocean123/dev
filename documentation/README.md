# Documentation Folder

This folder houses meta-documentation, audits, and automation that keep the
`~/Documents/dev` tree organized. All files obey the global conventions:
kebab-case names, YYYY-MM-DD dates, and content that separates administrative
records from working project assets.

## Structure Overview

- **`audits/`** - Historical audit and cleanup reports that capture changes,
  verification steps, and findings.
  - **`audits/logs/`** - Raw console output generated while running cleanup
    scripts.
- **`audits/legacy/`** - Archived transcripts kept verbatim for reference (lint
  exempt).
- **`guides/`** – Reference notes or post-mortems that apply broadly across the
  environment.
- **`reports/`** – Time-boxed summaries (e.g., working sessions) that link back
  to the artifacts they produced.
- **`scripts/`** – PowerShell tooling used to audit, reorganize, or lint the dev
  folder.

## File Index

### Audits (`audits/`)

- `dev-folder-audit-2025-11-06.md` – Initial deep dive of the dev folder with a
  remediation plan.
- `dev-folder-cleanup-summary.md` - Executive summary of the November 6 cleanup
  wave.
- `legacy/dev-folder-cleanup-summary.md` - Archived raw transcript of the same
  cleanup (pre-formatting).
- `final-dev-folder-audit-2025-11-06.md` - Verification report after the first
  remediation pass.
- `legacy/final-dev-folder-audit-2025-11-06.md` - Archived raw transcript of the
  same verification pass.
- `naming-conventions-audit-2025-11-06.md` - Canonical naming rules and
  compliance status.
- `legacy/naming-conventions-audit-2025-11-06.md` - Archived raw capture of the
  same audit prior to reformatting.
- `powershell-scripts-audit-2025-11-06.md`
  - Inventory plus cleanup notes for PowerShell scripts (November 6).
- `legacy/powershell-scripts-cleanup-summary.md` - Raw cleanup log associated
  with the November 6 audit.
- `legacy/powershell-scripts-audit-2025-11-06.md` - Archived transcript of the
  November 6 script audit.
- `legacy/powershell-scripts-audit-2025-11-09.md` - Follow-up audit transcript
  after the drive-management cleanup.
- `legacy/powershell-scripts-audit-2025-11-09.md` - Raw transcript of that
  follow-up audit.
- `documentation-lint-report-2025-11-09.md` – Markdown lint sweep across all
  documents.
- `claude-md-lint-report-2025-11-09.md` – CLAUDE.md synchronization report.
- `memory-leak-audit-2025-11-11.md` - Investigation notes for LXC memory usage.
- `legacy/memory-leak-audit-2025-11-11.md` - Raw transcript of that investigation
  (pre-formatting).
- `script-refactor-summary-2025-11-11.md` - Summary of the script refactor
  session.
- `legacy/script-refactor-summary-2025-11-11.md` - Raw transcript of the same
  session.
- `dev-folder-audit-2025-11-13.md` – Second comprehensive audit.
- `cleanup-audit-2025-11-13.md` – Post-action summary for the November 13 pass.
- `audits/logs/cleanup-log-2025-11-13-113857.txt` – Raw console output captured
  during the 11:38 AM cleanup run.

### Guides (`guides/`)

- `windows-docker-port-exclusions.md` – Root cause analysis and mitigation
  guidance for Hyper-V/WSL2 port exclusion conflicts that block Docker.

### Reports (`reports/`)

- `legacy/session-summary-2025-11-16.md` - Cross-team troubleshooting recap
  covering Immich, DigiKam, Tailscale, and the Windows port exclusion notes that
  were filed afterward (retained as a raw transcript).

### Scripts (`scripts/`)

- `audit-dev-folder-comprehensive.ps1` – Automated audit across the dev tree
  (size checks, naming validation, orphan detection).
- `cleanup-dev-folder.ps1` – Applies the audit recommendations (moves, renames,
  archiving).
- `run-powershell-lint-check.ps1` – Invokes ScriptAnalyzer against the
  PowerShell sources referenced by this documentation set.

## Maintenance

- Categorize new documents immediately; do not leave files at the root of
  `documentation/`.
- Keep audit and summary pairs together and align their timestamps.
- Use `guides/` for reusable fixes/procedures and `reports/` for
  chronological narratives.
- Store automation under `scripts/` and note its usage in the associated
  report or audit.
- Run Markdown + PowerShell lint checks after major edits; capture sweeping
  lint results in `audits/` when the scan covers multiple files.
- Timestamp log filenames as `name-YYYYMMDD-HHMMSS.log` to keep each run
  isolated while maintaining chronological sorting.
- Leave raw transcripts in `audits/legacy/` and `reports/legacy/`; they remain
  lint-exempt on purpose and should not be reformatted.
