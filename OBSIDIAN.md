# zen-runbook — Obsidian notes (Windows / Fedora KDE / macOS / Android)

Companion to `APPS.md` — Obsidian itself is installed there (winget on Windows, Flatpak on Fedora KDE, cask on macOS). This file covers how the vault is organized, the daily flow, general best practices, and the Syncthing setup that keeps it in sync across devices.

Current machines: Windows PC + Android phone + Mac — Windows is the daily driver until the Fedora KDE migration happens, kept below for when it does.

---

## Vault structure

Three folders, flat inside each — no nesting by topic. The failure mode of category-based systems (Projects/Areas/Resources, folders per life domain, etc.) is a note that fits two categories at once: you hesitate, capture friction goes up, and eventually you stop capturing. This structure removes the decision at capture time instead of trying to design around it.

- **`0-Inbox`** — every new note lands here, no exceptions. One destination, no decision.
- **`1-Notas`** — flat pool of processed notes, no subfolders by topic. Organization is by **tag** (`#trabalho`, `#saude`, `#financas`, `#estudo`, ...), not folder — a note about learning SQL for work can carry both `#trabalho` and `#estudo` at once instead of forcing a single folder pick.
- **`2-Arquivo`** — cold storage for notes no longer relevant. Moved here occasionally, not a routine filing destination.

## Daily flow

1. **Capture** — anything that comes up during the day (a thought, a meeting note, a reminder) goes straight into today's Daily Note. No folder decision, no tag decision yet — just write.
2. **Process** (weekly) — go through `0-Inbox` and the week's Daily Notes: promote what's worth keeping into `1-Notas` with tags and links, discard or move the rest into `2-Arquivo`.
3. **Retrieve** — never browse folders to find an old note. Use full-text search, the tag panel, or backlinks/graph view — folders don't encode meaning here, links and tags do.

The one real trade-off of this system: it only works if the weekly Inbox review actually happens — skip it for a month and `0-Inbox` becomes a junk drawer. That's the cost of frictionless capture.

## Core plugins — no community plugins by design

- **Daily notes** (Settings → Core plugins) — the capture entry point above.
- **Bases** (Settings → Core plugins) — table/card/list views with filters over notes' properties. This is what replaces the "database" feature you'd reach for in Notion, and it ships with Obsidian itself, so it's zero extra trust — try it before reaching for anything else.

Community plugins (Dataview, Obsidian Git, etc.) run unsandboxed JS with full vault access, unlike the core plugins above — deliberately skipped here, core covers what's needed.

---

## Syncthing — keeps the vault synced across devices

Peer-to-peer, no cloud in between — each device talks directly to the others, nothing is stored on a third-party server. Install per platform below, then pair all devices once.

### Windows

```powershell
winget install -e --id Syncthing.Syncthing

```

This installs the official core binary only — no tray icon, no autostart, just `syncthing.exe` and the web UI at `localhost:8384` when it's running. Launch it manually, or set it to start with Windows via Task Scheduler (Settings → search "Task Scheduler" → Create Task → trigger "At log on" → action pointing at the installed `syncthing.exe`) if you don't want to open it by hand every time.

**SyncTrayzor** (a third-party, open-source tray wrapper around Syncthing — real tray icon, autostart built in) is the common convenience pick people reach for here — not included by default since it's not from the Syncthing project itself, same reasoning this repo already applies elsewhere (`HARDENING.md`'s extension-hygiene rule) to third-party wrappers around an official tool. Worth it if the manual-launch friction actually bothers you; skip it if `localhost:8384` open in a pinned browser tab is enough.

### Fedora KDE (once migrated)

Official Fedora package, no third-party repo:

```bash
sudo dnf install -y syncthing
systemctl --user enable --now syncthing.service

```

### macOS

```bash
brew install syncthing
brew services start syncthing

```

Syncthing is the Homebrew formula, not a cask — it's a background service, not a GUI app.

### Android

Install the official Syncthing app — published by the Syncthing Foundation itself, on the Play Store or F-Droid. Same pairing step as below, no separate config.

### Pairing

Open http://localhost:8384 on Fedora or the Mac (Syncthing's own web UI, local-only by default) to get that machine's device ID. Do the same on the phone, add each device's ID on the others and approve the pairing on both sides, then share the Obsidian vault folder once all three trust each other.

Sanity check (Fedora/Mac):

```bash
command -v syncthing >/dev/null && echo "OK      syncthing" || echo "MISSING syncthing"
systemctl --user is-active syncthing.service 2>/dev/null | grep -q active \
  && echo "OK      syncthing.service" \
  || echo "PENDING syncthing.service not running (macOS: check 'brew services list' instead)"

```
