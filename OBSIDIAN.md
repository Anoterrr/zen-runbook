# zen-runbook - Obsidian notes (Windows / Fedora KDE / macOS / Android)

Companion to `APPS.md`, which installs Obsidian itself (winget on Windows, Flatpak on Fedora KDE, cask on macOS). This file covers how the vault is organized, the daily flow, and the Syncthing setup that keeps it in sync across devices.

Current machines: Windows PC, Android phone and Mac. Windows is the daily driver until I move to Fedora KDE, so the Fedora steps are here for when that happens.

## What this vault is for

To get things out of my head, not to track them. Keeping every open thread in working memory was giving me real headaches, and writing something down here means I can stop carrying it. So capture has to be quick, finding things has to take one search, and nothing in here is a deadline I'm behind on.

That changes how I read checkboxes. `- [ ]` marks *something that exists and where it lives*, not something overdue. A plan with forty open boxes and none checked is fully mapped and waiting until I have time for it. The notes are references I check to see if I'm doing something right. They're not trackers.

---

## Vault structure

Five folders, all named in English, flat inside, with no subfolders by topic. Category systems (Projects/Areas/Resources, a folder per life area, etc.) break down when a note fits two categories: I hesitate, capturing gets slower, and eventually I stop capturing. With this structure there's no decision to make when capturing.

`0-Inbox`, `1-Notes` and `2-Archive` are numbered because notes move between them as I process them (Inbox → Notes or Archive). `Journal` and `Attachments` have no number because nothing in them moves: a journal entry stays where I wrote it, and an attachment stays where it was pasted. Numbering them would suggest a step they don't have. The cost is that `Journal`, the folder I open most, sorts below the numbered ones and `Attachments` in the file explorer. I'm fine with that, because I never look for notes through the file explorer (see Retrieve below).

- **`Journal`**: the Daily Notes core plugin writes here (`YYYY-MM-DD.md`), one file per day I actually write, not every day. Mostly it's where I dump a thought that keeps circling and won't let me sleep, so it stops circling. The vault's `Plano - Sono` note counts it as part of the sleep routine, not as a journaling habit. There's no streak: a two-week gap means nothing needed dumping, not that I fell off. Entries stay here forever. If something in one is worth keeping, I copy it into `1-Notes` (tagged `#journal`, linked back to the date), and the entry itself stays put as the record. It's separate from `0-Inbox` because a folder full of dated files reads as a journal, not as a to-process pile.
- **`0-Inbox`**: quick capture for raw material that still needs shaping (a plan, a guide, a reference, a link worth its own note). One place, no decision. Unlike `Journal`, this folder is supposed to empty out: everything here either becomes a proper note in `1-Notes` or goes to `2-Archive`. I keep it thin on purpose. The bar is "will I actually look at this again", not "capture everything". A nearly empty inbox means that filter is working.
- **`1-Notes`**: all processed notes in one flat folder, with no subfolders by topic. Notes are organized by **tag** (see below). A note about learning SQL for work can have both `#work` and `#study` without me picking one folder. These are references: I write something down once so I don't have to think it through again, then look it up when it comes up. A note nobody opened for months isn't stale, it just hasn't been needed yet. A note can be doing its job with nothing in it checked off, and that's normal for the hobby and study notes here.
- **`2-Archive`**: notes that don't matter anymore. I move things here now and then, not as part of a routine.
- **`Attachments`**: every pasted or dragged-in file (image, PDF, anything) goes here. It's set in Settings → Files and links → "Default location for new attachments". Like `Journal`, the folder only works if the setting points to it. Otherwise Obsidian drops files next to whatever note you pasted them into.

Obsidian handles thousands of files in one folder without slowing down, and I don't use the file explorer to find notes, so a flat folder isn't a performance problem. The real risk is tags. Once notes cover several areas (work, college, health, journal), a messy tag set brings back the same "which bucket does this go in" problem the flat structure was meant to avoid. The fixed tag list below is there to stop that early.

## Tags

The fixed set. I apply tags when processing (`0-Inbox` → `1-Notes`), not when capturing. A note can and should have more than one when it covers more than one area.

- **`#work`**: carreira, projetos profissionais, reuniões
- **`#college`**: matérias, provas, trabalhos de curso
- **`#study`**: aprendizado autodirigido fora da faculdade (cursos, livros técnicos, etc.), combina com `#work` quando o estudo é pra aplicação profissional
- **`#health`**: treino, nutrição, sono, saúde mental
- **`#finance`**: dinheiro, investimentos
- **`#journal`**: reflexões pessoais promovidas de uma entrada do `Journal` pra `1-Notes` (a entrada em si já é o diário do dia a dia e nunca sai do `Journal`; a tag marca o que vale manter além da data)
- **`#personal`**: o que não se encaixa nas outras

Tags de assunto específico combinam com qualquer uma das acima, sem hierarquia, ex: `#college` + `#compiladores`, `#college` + `#redes`. Nomes de matérias ficam em português, como na faculdade, e o resto das tags em inglês. Regra: se a tag vai aparecer em várias notas ao longo do tempo (uma matéria inteira, um projeto que continua), ela vale. Se é pra uma nota só, não crio tag e deixo a busca achar pelo texto.

Não crio tag nova por impulso. Se uma nota não cabe nesse conjunto, ou ela é `#personal` ou o conjunto precisa ser revisto com calma, e uma tag avulsa de uso único não resolve nenhum dos dois.

## Daily flow

1. **Capture.** One question decides where it goes: is this raw material for its own note, or a thought about today that I need to get out of my head? The first goes into a new note in `0-Inbox`, the second into today's Daily Note in `Journal`. No tags yet, just write.
2. **Process**, when there's something in the inbox *and* I have the time, not on a fixed weekly schedule. Go through `0-Inbox`: turn what's worth keeping into notes in `1-Notes` with tags (from the set above) and links, and delete or archive the rest. Same for anything in `Journal` worth pulling out, while the entries stay where they are. In a busy stretch this step doesn't happen, and that's fine. An inbox with three items in it costs nothing.
3. **Retrieve.** This is the step I do all the time and the reason the other two exist. I never browse folders to find an old note. I use full-text search, the tag panel, or backlinks and the graph view. Folders don't carry meaning here, links and tags do.

The weak spot: quick capture pushes the shaping work to later, so `0-Inbox` only stays useful if I keep the bar high for what goes in. The risk isn't a slow week. It's throwing everything in and planning to sort it later, until the inbox is a junk drawer that takes more time to clear than it ever saved. Keeping it thin is what lets me process it only when I have time.

## Core plugins only, no community plugins

- **Daily notes** (Settings → Core plugins): where capture starts, see above.
- **Bases** (Settings → Core plugins): table, card and list views filtered by note properties. This replaces Notion's databases, and it ships with Obsidian, so there's nothing extra to trust. Try it before looking for a plugin.

Community plugins (Dataview, Obsidian Git, etc.) run JavaScript with no sandbox and full access to the vault. Core plugins cover what I need, so I skip them.

---

## Syncthing: keeps the vault synced across devices

Peer-to-peer: devices talk directly to each other, and nothing is stored on a third-party server. Install it on each platform below, then pair all devices once.

### Windows

```powershell
winget install -e --id Syncthing.Syncthing

```

This installs only the official core binary: no tray icon, no autostart, just `syncthing.exe` and its web UI at `localhost:8384` while it runs. Start it by hand, or make it start with Windows through Task Scheduler (search "Task Scheduler" → Create Task → trigger "At log on" → action pointing at the installed `syncthing.exe`).

**SyncTrayzor** is a third-party, open-source tray wrapper for Syncthing with a tray icon and autostart built in, and it's what most people use here. I don't install it by default because it doesn't come from the Syncthing project, the same rule as the extension advice in `HARDENING.md`. Worth it if starting Syncthing by hand gets annoying. If a pinned browser tab on `localhost:8384` is enough, skip it.

### Fedora KDE (after the move)

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

On macOS Syncthing is a Homebrew formula, not a cask, because it's a background service and not a GUI app.

### Android

The official Syncthing app was removed from the Play Store. Install **Syncthing-Fork** (`com.github.catfriend1.syncthingandroid`) from the Play Store instead. It's a community-maintained, open-source fork that uses the same protocol and works with official Syncthing on the other devices. You're trusting the fork's maintainer instead of the Syncthing Foundation, but you don't have to sideload or allow unknown sources. Pairing works the same as below.

### Pairing

Open http://localhost:8384 on Fedora or the Mac (Syncthing's web UI, local only by default) to get that machine's device ID. Do the same on the phone. Add each device's ID on the others and approve on both sides. Once all three trust each other, share the Obsidian vault folder.

Sanity check (Fedora/Mac):

```bash
command -v syncthing >/dev/null && echo "OK      syncthing" || echo "MISSING syncthing"
systemctl --user is-active syncthing.service 2>/dev/null | grep -q active \
  && echo "OK      syncthing.service" \
  || echo "PENDING syncthing.service not running (macOS: check 'brew services list' instead)"

```
