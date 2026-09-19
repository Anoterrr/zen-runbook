# zen-runbook — Obsidian notes (Windows / Fedora KDE / macOS / Android)

Companion to `APPS.md` — Obsidian itself is installed there (winget on Windows, Flatpak on Fedora KDE, cask on macOS). This file covers how the vault is organized, the daily flow, general best practices, and the Syncthing setup that keeps it in sync across devices.

Current machines: Windows PC + Android phone + Mac — Windows is the daily driver until the Fedora KDE migration happens, kept below for when it does.

---

## Vault structure

Five folders, flat inside each, all named in English — no nesting by topic. The failure mode of category-based systems (Projects/Areas/Resources, folders per life domain, etc.) is a note that fits two categories at once: you hesitate, capture friction goes up, and eventually you stop capturing. This structure removes the decision at capture time instead of trying to design around it.

`0-Inbox`, `1-Notes`, and `2-Archive` are numbered because the number means something specific: a note in this trio actually migrates between folders as it gets processed (Inbox → Notes or Archive). `Journal` and `Attachments` get no number at all, on purpose: nothing in either ever migrates that way — a journal entry stays where it was written, an attachment stays where it was pasted, forever. Numbering them like the other three would claim a stage-transition that doesn't happen. The trade-off is that `Journal` — the folder actually opened every single day — sorts below the numbered trio and `Attachments` in the file explorer instead of at the top; accepted deliberately, because a folder's *meaning* shouldn't bend to make it sort first, and retrieval here never goes through the file explorer anyway (see Retrieve below).

- **`Journal`** — the Daily Notes core plugin writes here (`YYYY-MM-DD.md`), one file per day. It's born here and it dies here: weekly processing mines a day's entry for what's worth keeping and copies that into `1-Notes` (tagged `#journal`, linked back to the date) — the entry itself never moves or gets archived, it's the permanent record. Split out from `0-Inbox` on purpose, too: a folder full of dated files reads as a journal, not as "stuff to process," and mixing the two made the inbox harder to scan at a glance during weekly review.
- **`0-Inbox`** — anything that's the seed of its own note lands here (a plan, a guide, a reference, a link worth a full note) — one destination, no decision. Unlike `Journal`, this one is meant to empty out: everything here either gets promoted to `1-Notes` or moved to `2-Archive`.
- **`1-Notes`** — flat pool of processed notes, no subfolders by topic. Organization is by **tag** (see below), not folder — a note about learning SQL for work can carry both `#work` and `#study` at once instead of forcing a single folder pick.
- **`2-Archive`** — cold storage for notes no longer relevant. Moved here occasionally, not a routine filing destination.
- **`Attachments`** — every pasted/dragged-in file (image, PDF, whatever) lands here, set as the attachment folder in Settings → Files and links → "Default location for new attachments". Same wiring principle as `Journal`: an attachment folder that exists but isn't set there is just a folder, Obsidian still scatters files next to whatever note you pasted them into.

Flat + tag scales fine technically — Obsidian handles thousands of files in one folder without slowdown, and retrieval never goes through the file explorer (see Retrieve below). The actual scaling risk is tag discipline, not folder size: once notes span multiple life domains (work, college, health, journal), an undisciplined tag set turns back into the same "which bucket does this go in" friction the flat structure was built to avoid. The canonical tag list below exists to prevent that before it happens, not after.

## Tags

Canonical set — apply during weekly processing (`0-Inbox` → `1-Notes`), not at capture time. A note can and should carry more than one when it genuinely spans domains.

- **`#work`** — carreira, projetos profissionais, reuniões
- **`#college`** — matérias, provas, trabalhos de curso
- **`#study`** — aprendizado autodirigido fora da faculdade (cursos, livros técnicos, etc.) — combina com `#work` quando o estudo é pra aplicação profissional
- **`#health`** — treino, nutrição, sono, saúde mental
- **`#finance`** — dinheiro, investimentos
- **`#journal`** — reflexões pessoais promovidas de uma entrada do `Journal` pra `1-Notes` (a entrada em si já é o diário do dia a dia e nunca sai do `Journal`; a tag marca o que vale manter além da data)
- **`#personal`** — catch-all pro que não se encaixa nas acima

Sub-tags de assunto específico combinam livremente com o conjunto canônico acima, sem hierarquia — ex: `#college` + `#compiladores`, `#college` + `#redes`. Nomes de matérias ficam no idioma da faculdade (português), o resto das tags em inglês. O teste é reutilização: se a tag vai aparecer em várias notas ao longo do tempo (uma matéria inteira, um projeto contínuo), é legítima; se é pra uma nota só, não crie tag — deixe a busca full-text achar pelo conteúdo.

Não crie uma tag nova por impulso — se uma nota não cabe nesse conjunto, é sinal de que ela é `#personal` ou que o conjunto precisa de revisão deliberada, não de uma tag ad-hoc de uso único.

## Daily flow

1. **Capture** — one question decides where: is this the seed of its own note, or just noise/a thought about today that probably won't become one? The first goes into a new note in `0-Inbox`; the second goes into today's Daily Note in `Journal`. Either way, no tag decision yet — just write.
2. **Process** (weekly) — go through `0-Inbox`: promote what's worth keeping into `1-Notes` with tags (canonical set above) and links, discard or move the rest into `2-Archive`. Separately, go through the week's entries in `Journal`: copy what's worth keeping into `1-Notes` — the journal entries themselves stay put.
3. **Retrieve** — never browse folders to find an old note. Use full-text search, the tag panel, or backlinks/graph view — folders don't encode meaning here, links and tags do.

The one real trade-off of this system: it only works if the weekly review actually happens — skip it for a month and `0-Inbox` becomes a junk drawer (`Journal` just keeps accumulating either way, which is fine, that's what a journal is for). That's the cost of frictionless capture.

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

The official Syncthing app was pulled from the Play Store — install **Syncthing-Fork** (`com.github.catfriend1.syncthingandroid`) instead, available on the Play Store. Community-maintained fork, open-source, same protocol, fully interoperable with official Syncthing on the other devices; trust shifts from the Syncthing Foundation to the fork's maintainer, but it avoids sideloading and the "allow unknown sources" permission entirely. Same pairing step as below, no separate config.

### Pairing

Open http://localhost:8384 on Fedora or the Mac (Syncthing's own web UI, local-only by default) to get that machine's device ID. Do the same on the phone, add each device's ID on the others and approve the pairing on both sides, then share the Obsidian vault folder once all three trust each other.

Sanity check (Fedora/Mac):

```bash
command -v syncthing >/dev/null && echo "OK      syncthing" || echo "MISSING syncthing"
systemctl --user is-active syncthing.service 2>/dev/null | grep -q active \
  && echo "OK      syncthing.service" \
  || echo "PENDING syncthing.service not running (macOS: check 'brew services list' instead)"

```
