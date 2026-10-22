# zen-runbook - backup (Fedora WSL2 / Fedora KDE)

The main machine only. The work Mac holds work, which is the company's to back up, and my notes, which come from the vault below.

## What's covered, and where its copy lives

| Data | Copy | Where it's set up |
|---|---|---|
| Personal folders (Desktop, Documents, Pictures, Videos, Music) | restic, encrypted, on Google Drive, daily | this file |
| `~/.ssh` and `~/.gitconfig` | same | this file |
| Obsidian vault | private GitHub repo with full history, and restic too (it's inside Documents) | `OBSIDIAN.md` |
| Code | each repo's remote on GitHub. Unpushed work isn't covered, so I push | `GIT.md` |
| Anki | AnkiWeb (cards, media and review history) plus Anki's own local backups | `APPS.md` |

Not covered, on purpose: Downloads (installers I can download again), installed apps (the lists in `packages/` reinstall them), and raw OBS recordings (deleted once the video is out). Video masters don't fit in Google Drive's free 15 GB, so they wait for an external disk (last section).

## How it works

`restic` takes deduplicated snapshots: the first one uploads everything, and later ones only what changed. It encrypts on my machine before anything leaves, so Google only stores unreadable blocks. `rclone` is the connection to Google Drive. Both come from Fedora's repos (`packages/fedora.txt`). A systemd timer in `config/systemd/` runs it once a day.

Everything machine-specific lives in `~/.config/restic/`, never in the repo: the password, which paths to back up, and where the repository is.

## 1. Connect Google Drive

```bash
rclone config create gdrive drive scope=drive.file

```

It prints a link. Open it in Brave (on WSL2 it doesn't open by itself), sign in to Google and allow access. `scope=drive.file` lets rclone see only the files it creates itself, not the rest of the Drive. Running it again re-authorizes the same remote.

## 2. Password and settings

```bash
mkdir -p ~/.config/restic && chmod 700 ~/.config/restic
test -s ~/.config/restic/password || (umask 077; head -c 32 /dev/urandom | base64 > ~/.config/restic/password)
printf 'RESTIC_REPOSITORY=rclone:gdrive:restic\nRESTIC_PASSWORD_FILE=%s/.config/restic/password\n' "$HOME" > ~/.config/restic/env

```

**Copy the password into Bitwarden now** (`cat ~/.config/restic/password`, new item "restic backup"). The backup exists for the day this machine is gone, and without that password nobody, me included, can open it.

Paths, one per line. On WSL2 the personal folders are on the Windows side:

```bash
win="/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r')"
printf '%s\n' "$win"/{Desktop,Documents,Pictures,Videos,Music} ~/.ssh ~/.gitconfig > ~/.config/restic/paths

```

On Fedora KDE they're in my home:

```bash
printf '%s\n' ~/{Desktop,Documents,Pictures,Videos,Music} ~/.ssh ~/.gitconfig > ~/.config/restic/paths

```

## 3. Create the repository and turn on the timer

```bash
set -a; . ~/.config/restic/env; set +a      # loads the settings into this shell, for any restic command
restic cat config >/dev/null 2>&1 || restic init

stow -d ~/repos/zen-runbook/config -t ~ --no-folding systemd
systemctl --user daemon-reload
systemctl --user enable --now backup.timer
systemctl --user start backup.service      # first backup now instead of tomorrow
journalctl --user -u backup.service -n 20  # should end with "snapshot ... saved"

```

After each backup, `restic forget --prune` keeps the last 7 daily, 4 weekly and 12 monthly snapshots and deletes the rest. On WSL2 the timer runs while Fedora is open, which is every day I work. If it was closed at that time, `Persistent=true` runs it at the next start.

`../audit.sh` checks the timer, the settings and that the last backup didn't fail. A backup that broke silently months ago is the usual way to lose everything, so that last check matters most.

Space used: `rclone about gdrive:`. The 15 GB is shared with Gmail and Google Photos.

## Restore

```bash
set -a; . ~/.config/restic/env; set +a
restic snapshots                                             # list them
restic restore latest --target ~/restore                     # everything, into a new folder
restic restore latest --target ~/restore --include ~/.ssh    # just one path

```

`restic restore` never writes over the originals with `--target` pointing somewhere new. Look through `~/restore`, copy back what I need, delete the folder.

On a new machine: install `restic` and `rclone`, do step 1, and put the password from Bitwarden into `~/.config/restic/password`. Then the commands above work.

**Test it every few months.** A backup that was never restored is a guess. Restore one file and compare it, then let restic verify a sample of the stored data:

```bash
restic restore latest --target /tmp/restore-test --include ~/.gitconfig && diff ~/.gitconfig /tmp/restore-test"$HOME"/.gitconfig && echo OK
restic check --read-data-subset=10%

```

## Later: masters on an external disk

When the first video master exists, an external disk gets its own restic repository with the masters and everything above, since Google Drive's free tier can't hold video. Until then, OBS records to a folder outside the list above (`APPS.md`), so raw gameplay never fills the Drive.
