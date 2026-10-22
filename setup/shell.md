# Shell, prompt, and tool configuration (all platforms)

Run this after your platform file (`fedora.md` + `wsl.md`, `fedora.md` alone on KDE, or `macos.md`).

Every config file lives in `config/` and gets **linked** into your home, not copied. Editing `~/.zshrc` edits the file in the repo, so `git diff` shows every change, and nothing in this guide ever writes over a file you changed.

## 1. Link the configs

```bash
stow -d ~/repos/zen-runbook/config -t ~ --no-folding zsh git ssh mise topgrade lnav
stow -d ~/repos/zen-runbook/config -t ~ --no-folding ghostty   # Fedora KDE and macOS only, Ghostty doesn't run on WSL

```

Each folder in `config/` is one stow package, laid out the way it lands in `~`: `config/git/.config/git/config` becomes `~/.config/git/config`. `--no-folding` links each file on its own. Without it, stow links whole directories when it can, and then anything a tool writes next to its config (mise, git) would land in the repo too.

stow never overwrites. If a file is already there (a `~/.ssh/config` from before, a `~/.zshrc` some installer created), it stops with `existing target is not owned by stow` and changes nothing. Compare that file with the one in `config/`, move anything machine-specific into the matching local file below, delete it, and run the command again. Running it again when everything is linked does nothing.

| Linked from `config/` | Machine-specific part, never in the repo |
|---|---|
| `zsh/.zshrc` | `~/.zshrc.local`, loaded near the end |
| `git/.config/git/config` | `~/.gitconfig`: name, email, signing key (`git.md`) |
| `ssh/.ssh/config` | `~/.ssh/config.local`, loaded first so its values win |
| `mise/.config/mise/config.toml` | none, per-project pins go in the project's own `mise.toml` |
| `topgrade/.config/topgrade.toml` | none |
| `lnav/.lnav/formats/installed/custom-highlights.json` | none |
| `ghostty/.config/ghostty/config` | none |
| `systemd/.config/systemd/user/backup.{service,timer}`, linked by `../BACKUP.md` | `~/.config/restic/`: password, paths, repository |

To stop using one: `stow -d ~/repos/zen-runbook/config -t ~ -D <folder>` removes its links and leaves the repo alone.

## 2. mise: runtimes, plus the CLI tools dnf lacks

```bash
curl https://mise.run | sh
~/.local/bin/mise install

```

`mise install` reads the linked `~/.config/mise/config.toml`. `mise use -g <tool>@<version>` writes into that same file, so it shows up in the repo's `git diff` like any other config change.

`python` and `java` are pinned because PySpark and JVM build tooling take a while to support new releases. Bump them by hand once your usual stacks work on the new version. `node`, `rust` and `go` track `lts`/`latest` since their ecosystems keep up, and per-project pins (e.g. via `uv` for Python) override this global default anyway. `uv` itself comes from `dnf`/`brew`, and the `uv_venv_auto` setting makes mise create and activate a project's `.venv` when it finds a `uv.lock`.

`starship`, `lazygit`, `topgrade` and `duckdb` are marked `os = ["linux"]`: dnf doesn't have them, brew does, so mise installs them on Fedora only.

If the pinned Python patch has no prebuilt binary for your platform yet (they can lag a release by a few days), drop to the previous patch (`mise ls-remote python | grep '^3.13'` lists what's available), or build from source with `mise settings set python.compile true` and run `mise install` again.

## 3. starship (preset)

```bash
starship preset nerd-font-symbols --force -o ~/.config/starship.toml

```

This one isn't in `config/`: it's starship's own preset, and regenerating it picks up the preset's updates. Without `--force`, starship refuses to write over an existing file, so running this again would fail.

Now open zsh (`exec zsh`). From here on every shell loads the linked `~/.zshrc`.

---

## What each config does

### zsh (`config/zsh/.zshrc`)

Every tool here is installed by this guide, so nothing is wrapped in "if installed" checks: if one is missing, the shell prints an error on startup instead of failing silently. mise's shims aren't on `PATH` because `mise activate` already puts each tool's real directory there in an interactive shell. The shims only matter for programs that don't read `~/.zshrc`, and `../audit.sh` adds them itself.

`compinit` was most of the startup time: on every shell it scanned every completion file and ran `compaudit`, a permission check on those directories. Now the full run (scan, audit, rebuild `~/.zcompdump`) happens only when the dump is missing or more than 24 hours old, and every other shell loads the dump with `compinit -C`. The `touch` is there because `compinit` only rewrites the dump when the set of completion files changed. Without it, the file would stay old and every shell would do the full run again. A completion for a tool you just installed shows up within a day, or right away with `rm ~/.zcompdump && exec zsh`.

Out of the box, zsh doesn't save history to disk and has no suggestions or highlighting. The history block and the two plugins add those. The plugins come from `dnf`/`brew` and load with a plain `source`. I skipped plugin managers (Oh My Zsh, zinit) because they pull unpinned scripts from GitHub on every update, and two files don't need a manager.

### git (`config/git/.config/git/config`)

New repos start on `main`, `pull` rebases instead of creating merge commits, commits are signed with the SSH key from `git.md`, and `delta` is the pager for diffs and `git add -p`. git reads this file first and `~/.gitconfig` after it, so anything in `~/.gitconfig` wins.

### ssh (`config/ssh/.ssh/config`)

`IdentitiesOnly` stops ssh from offering every key in `~/.ssh/` to every host. `HashKnownHosts` stops `~/.ssh/known_hosts` from listing the servers you've connected to in plain text. ssh only refuses a config that other users can write to, and the linked file isn't one.

### lnav (`config/lnav/...`)

Regex highlighting for error, warning and success lines in DAG and pipeline run logs.

### topgrade (`config/topgrade/.config/topgrade.toml`)

`topgrade` updates what it detects (dnf/brew, flatpak, mise and its tools, git repos), then runs `../audit.sh` as a post command, so drift shows up on every upgrade without a separate habit. `topgrade --dry-run` lists every step it detected. It runs inside Fedora and macOS only. On the Windows host, Windows Update and each app's own updater do the job, and topgrade would fight them.

### Ghostty (`config/ghostty/.config/ghostty/config`)

The font was installed so starship's icons render, but Ghostty won't use it until the config says so.

### Neovim and tmux: no config

Neither one gets a config file. Servers you SSH into usually have both installed with stock settings, so learning the defaults here means the same keys work there. Editor roles: Zed for daily work, `nvim` when there's no GUI, `lazygit` for git.

tmux keys to learn first. Every shortcut starts with the prefix `Ctrl-b`: press it, release, then press the key.

| Keys | Action |
|---|---|
| `tmux new -s name` | Start a named session |
| `Ctrl-b d` | Detach, the session keeps running |
| `tmux ls` / `tmux a -t name` | List sessions / reattach to one |
| `Ctrl-b %` / `Ctrl-b "` | Split side by side / top and bottom |
| `Ctrl-b` + arrow | Move between panes |
| `Ctrl-b c` / `Ctrl-b n` | New window / next window |
| `Ctrl-b [` | Scroll mode (`q` to leave) |

---

## Performance: measure shell startup time

Everything the config loads (`compinit`, `mise activate`, `zoxide init`, `starship init`, `fzf --zsh`, the two plugins) runs every time a shell opens. To see how long that takes:

```bash
mkdir -p ~/.local/state
test -f ~/.local/state/zsh-startup-baseline.md \
  || hyperfine --warmup 3 --export-markdown ~/.local/state/zsh-startup-baseline.md 'zsh -i -c exit'
cat ~/.local/state/zsh-startup-baseline.md
hyperfine --warmup 3 'zsh -i -c exit'

```

The first run saves a baseline, and every run after that prints it next to the new measurement. Look at the mean: it's the delay you get every time you open a terminal. `hyperfine` runs the command many times and reports the spread too, so one slow run (cold disk cache, busy CPU) won't look like a regression the way it would with a single `time`. Run it after setup and again whenever you add something to `.zshrc.local`. If the mean jumps well past the baseline, comment out one integration at a time in `~/.zshrc` and re-run until you find which one did it. After a change you decide to keep, delete the baseline file so the next run records a new one.

---

Next: `git.md`.
