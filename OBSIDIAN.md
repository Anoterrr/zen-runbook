# zen-runbook - Obsidian notes (Windows / Fedora KDE / macOS / Android)

Companion to `APPS.md`, which installs Obsidian and Syncthing on every platform from the lists in `packages/`. This file covers how the vault is organized, the daily flow, the Syncthing setup that keeps it in sync across devices, and the backup to a private GitHub repo.

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
- **`Attachments`**: every pasted or dragged-in file (image, PDF, anything) goes here. The setting that points there is in the table below.

Three settings make the folders work. Without them, Obsidian drops files in the vault root or next to whatever note is open:

| Setting | Value |
|---|---|
| Files and links → Default location for new notes | In the folder specified below → `0-Inbox` |
| Files and links → Default location for new attachments | In the folder specified below → `Attachments` |
| Core plugins → Daily notes → New file location / Date format | `Journal` / `YYYY-MM-DD` |

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
- **File recovery** (on by default): local snapshots of each note, per device. It's the first place to look after a bad edit.
- **Sync: off.** That's the paid Obsidian Sync. Syncthing already does the job, and leaving it on only makes Obsidian offer it.

Community plugins (Dataview, Obsidian Git, etc.) run JavaScript with no sandbox and full access to the vault. Core plugins cover what I need, so I skip them.

---

## Syncthing: keeps the vault synced across devices

Peer-to-peer: devices talk directly to each other, and nothing is stored on a third-party server. `APPS.md` installs it on each computer. Below is how to start it on each one, then pair all devices once and set up the vault folder as described in "Vault folder settings".

### Windows

`Syncthing.Syncthing` is the official core binary (publisher: The Syncthing Authors): no tray icon, no autostart, just `syncthing.exe` and its web UI at `localhost:8384` while it runs. To start it with Windows: Start menu → Task Scheduler → Create Task, trigger "At log on", action pointing at the installed `syncthing.exe` with the arguments `--no-console --no-browser`.

**SyncTrayzor** is a third-party, open-source tray wrapper for Syncthing with a tray icon and autostart built in. The original project is archived. The maintained one (as of 2026-09) is the GermanCoding fork (`winget install -e --id GermanCoding.SyncTrayzor`). Don't install `SyncTrayzor.SyncTrayzor`, that's the old, dead one. I don't install it by default because it doesn't come from the Syncthing project, the same rule as the extension advice in `HARDENING.md`. Worth it if starting Syncthing by hand gets annoying.

### Fedora KDE (after the move)

Official Fedora package, no third-party repo. Start it with the user session:

```bash
systemctl --user enable --now syncthing.service

```

The firewall step in `HARDENING.md` opens Syncthing's ports. Without it, devices still connect through Syncthing's relays, only slower.

### macOS

```bash
brew services start syncthing

```

### Android

The official Syncthing Android app was discontinued in December 2024. The maintained replacement is **Syncthing-Fork**, open source, same protocol, and it works with official Syncthing on the other devices. It's now maintained at `researchxxl/syncthing-android` (as of 2026-09, the old Catfriend1 repo redirects there).

Where I get it matters:

- **F-Droid** (`com.github.catfriend1.syncthingfork`): built from the maintained repo's source. The F-Droid app has to be allowed to install apps once, and F-Droid updates it after that. This is the one I use.
- **Play Store** (`com.github.catfriend1.syncthingandroid`): published from a separate account (`nel0x`). The fork's maintainer said in its issue tracker (issues #243 and #351, 2026) that the Play builds are made privately on that person's computer, not from the repo's CI, and lag behind or break (the August 2026 Play update caused "Failed to create configuration" errors). Avoid it.

The two have different package IDs, so switching from the Play version is a fresh install. The phone gets a new device ID and has to be paired again. Pairing works the same as below.

### Pairing

Open http://localhost:8384 on each computer (Syncthing's web UI, local only by default) to get its device ID, and check the phone app for its ID. Add each device's ID on the others and approve on both sides. Once all of them trust each other, share the Obsidian vault folder.

### Vault folder settings (on every device)

In the web UI (or the phone app), edit the vault folder:

- **Ignore Patterns**: add the two files Obsidian rewrites every time I switch notes or resize a pane. If they sync, every device fights over them and Syncthing creates conflict copies. They only hold window layout, so each device keeps its own:

  ```
  .obsidian/workspace.json
  .obsidian/workspace-mobile.json
  .git
  ```

  Ignore patterns don't sync between devices. Add them on each one. `.git` is the backup below: only the main machine has it, and a git folder synced half-written to another device corrupts it.
- **File Versioning**: "Staggered", at least on the desktop. Syncthing isn't a backup: a deleted or broken note gets deleted or broken on every device. With versioning, the old copies stay in `.stversions` inside the vault. The real backup is the next section.

**Conflicts.** When two devices change the same file before syncing, Syncthing keeps both and names one `*.sync-conflict-*`. They don't go away by themselves. Every now and then:

```bash
fd -H sync-conflict ~/path/to/vault   # compare each one with the original, keep what's right, delete the copy

```

Sanity check (Fedora):

```bash
command -v syncthing >/dev/null && echo "OK      syncthing" || echo "MISSING syncthing"
systemctl --user is-active --quiet syncthing.service \
  && echo "OK      syncthing.service" || echo "MISSING syncthing.service not running"

```

Sanity check (macOS):

```bash
brew services list | grep -q "^syncthing.*started" \
  && echo "OK      syncthing service" || echo "MISSING run 'brew services start syncthing'"

```

Sanity check (Windows, PowerShell):

```powershell
if (Get-Process syncthing -ErrorAction SilentlyContinue) { Write-Host "OK      syncthing running" } else { Write-Host "MISSING syncthing not running" }

```

---

## Backup: private GitHub repo

Syncthing copies mistakes to every device, and `.stversions` lives on the same disks. The backup is a git repo of the vault, pushed to a private GitHub repo: off my machines, with the full history of every note. It runs on the main machine only (Windows through WSL2 today, Fedora KDE after the move). The vault is also in the daily restic backup (`BACKUP.md`), since it lives inside Documents. The other devices get the notes through Syncthing as before.

One time, on the main machine:

```bash
vault="/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r')/Documents/Obsidian Vault"   # Fedora KDE: the vault's path there
cd "$vault"
git init -b main
git config core.fileMode false   # WSL2: every file on /mnt/c looks executable
printf '%s\n' .obsidian/workspace.json .obsidian/workspace-mobile.json .trash/ .stfolder .stversions/ '*.sync-conflict-*' > .gitignore
git add -A && git commit -m "Vault snapshot $(date +%F)"
gh repo create obsidian-vault --private --source . --push

```

`.gitignore` leaves out what's per device or already a copy: window layout, Obsidian's trash, Syncthing's own files and conflict copies.

Then, whenever I've written something worth keeping, and at least weekly (with `vault` set as above):

```bash
git -C "$vault" add -A && git -C "$vault" commit -qm "Vault snapshot $(date +%F)"; git -C "$vault" push -q

```

The commit fails harmlessly when nothing changed, and the push still runs. Commits are signed like any other (`setup/git.md`).

Private means private to my account, not encrypted: GitHub can read it, and so can anyone who gets into the account. That's why 2FA on GitHub matters here (`HARDENING.md`), and why nothing like a password or a document number goes in a note. GitHub rejects files over 100 MB, which only a video would hit, and videos don't go in the vault.

After the move to Fedora KDE, the vault arrives through Syncthing without `.git`. Clone the repo anywhere, move its `.git` folder into the vault, and `git status` should show nothing changed. Then delete `.git` from the old machine's vault, so only one machine ever has it.

Sanity check (main machine):

```bash
git -C "$vault" remote get-url origin && git -C "$vault" log -1 --format='last snapshot: %cr'

```
