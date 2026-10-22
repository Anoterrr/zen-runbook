# zen-runbook - environment baseline (Fedora WSL2 / Fedora KDE / macOS)

No install scripts. Every command is in a markdown file you read before you run it. The configs live in `config/` and get linked into your home, the package lists live in `packages/`, and `audit.sh` checks the machine against both without changing anything.

## Purpose

My personal environment baseline. It takes a fresh Fedora or macOS install to a working shell in one read-through, and every choice in it has a reason written next to it.

## Pillars

In priority order: when two conflict, the higher one wins.

1. **Provenance**: the OS package manager first, in its own list format where it has one (`Brewfile`, winget's JSON). Then the vendor's own channel. A third party only where the vendor has no channel, or where the vendor's only channel is one more `curl | sh` outside any package manager, and the guide always names who. Anything downloaded by hand is pinned to a version and checked against the vendor's published SHA-256. The full list is in "Sources and owners".
2. **Transparent**: no install scripts, no hidden logic. You can read every command before you run it. The one script, `audit.sh`, only reads: it never installs, changes or asks for `sudo`.
3. **Declarative**: the repo describes the machine. Packages are listed in `packages/` and configs live in `config/`, linked into `~`, each fact in one place. Pin a version when the ecosystem around the tool lags (Python, Java, fonts, kubectl). Let it float when it doesn't (Node, Rust, Go).
4. **Verified**: what the repo says, I check. `audit.sh` checks that everything listed is installed and configured, and only that: something I'm trying out for a day isn't an error. `topgrade` updates Fedora and macOS and runs the audit after. Windows is left to Windows Update and each app's own updater, because a second updater there fights the first. Shell startup time has a measured baseline (`setup/shell.md`, last section).
5. **Minimal**: every tool has a written reason and real use. What I stop using gets removed. One tool per job. Tiebreaker: if something costs nothing (reusing a tool already installed, turning off default noise), take it.
6. **Close to vanilla**: presets over deep customization. Stock defaults wherever I'll meet the same tool on a server: Neovim and tmux run with no config, distribution or framework on top.
7. **Rerunnable**: every step can be run again without breaking or duplicating anything. Machine-specific settings go in local files the repo never touches (`~/.zshrc.local`, `~/.gitconfig`, `~/.ssh/config.local`).

## Layout and reading order

```
README.md            this file: pillars, sources, tool index
setup/wsl.md         1. Fedora WSL2 only: create the instance (then fedora.md, then back here for the Windows side)
setup/fedora.md      2. Fedora, shared by WSL2 and KDE, plus the KDE-only part
setup/macos.md       2. macOS, instead of fedora.md
setup/shell.md       3. link the configs, install mise, what each config does, startup time
setup/git.md         4. identity, SSH key, signing, gh
audit.sh             any time: checks the machine against packages/ and config/
.pre-commit-config.yaml  checks run on every commit to this repo
packages/            one list per platform, in the package manager's own format where it has one
config/              one folder per tool, linked into ~ with stow
APPS.md              desktop apps per machine role, one reason each
HARDENING.md         internet and machine hardening
GIT.md               day-to-day git and gh commands, safe vs DANGER
OBSIDIAN.md          notes vault structure, Syncthing and backup
BACKUP.md            personal files to Google Drive, encrypted, daily (main machine)
```

Later steps assume the earlier ones are done.

## Facts that age

Some statements are true today and won't stay true: a driver bug, a project's maintenance status, a package that doesn't exist yet. Those are marked **(as of YYYY-MM)**, the month they were last checked. When one is more than about six months old and I'm relying on it, I check it again before acting on it, and update the date. To list them all: `rg -n 'as of 20' --glob '*.md' ~/repos/zen-runbook`.

## Sources and owners

Where every download comes from, and who controls it.

| Source | Owner | Vendor or third party | Used for |
|---|---|---|---|
| Fedora repos (`dnf`) | Fedora Project | OS package manager, builds from upstream source and signs | Most CLI tools on Fedora |
| Homebrew | Homebrew maintainers | OS package manager on macOS. Formulae are built from upstream source; casks download the vendor's own binary | CLI tools (formulae), Zed, Ghostty and the font (casks) on macOS |
| `mise.run` | jdx (mise's author) | Vendor | mise itself |
| mise, `aqua` backend | Each tool's own GitHub releases (starship/starship, jesseduffield/lazygit, topgrade-rs/topgrade, duckdb/duckdb), checksums from the aqua registry | Vendor | starship, lazygit, topgrade, duckdb on Fedora |
| mise runtimes | nodejs.org, rust-lang, go.dev, Adoptium (Temurin) | Vendor | node, rust, go, java |
| mise Python | Astral (`python-build-standalone`) | **Third party**: CPython builds made by Astral, not python.org | python |
| ryanoasis/nerd-fonts releases | Nerd Fonts project | Vendor, pinned version + SHA-256 | JetBrainsMono Nerd Font on Fedora KDE and Windows |
| Terra | Fyra Labs | **Third party**: repackages vendor releases | Ghostty and Zed on Fedora KDE, DBeaver (`APPS.md`). Ghostty publishes no Linux binary and its docs point to Terra or COPR. Zed does have its own `zed.dev/install.sh`, but that's another `curl \| sh` outside dnf, so Zed comes from Terra and `topgrade` updates it with everything else |
| winget | Microsoft's community manifest repo, pointing at the vendor's installer | Vendor binary, third-party manifest | Zed and the `APPS.md` apps on Windows |

Three steps accept a known risk:

- **`curl | sh` installers** (`mise`, Homebrew). Each is the project's official install command, and neither publishes a checksum to verify against. I accept it because both are widely audited, served over HTTPS from their own domains, and this is how most of the ecosystem bootstraps.
- **Terra repo** (Fedora KDE only). The first `terra-release` install uses `--nogpgcheck`, as Terra's docs say, because that package is the one that installs the GPG key used to verify everything else. Terra is limited to the packages this repo needs from it (see `setup/fedora.md`). The rest of its ~3,000 packages (as of 2026-09) stay invisible to dnf, including a few that share names with Fedora packages and could otherwise replace them on upgrade.
- **Vendor downloads with no checksum** (NVIDIA App and Neural Amp Modeler on Windows, DaVinci Resolve on Windows and Fedora KDE, `APPS.md`). None has a winget package that tracks the vendor's own install, and none of the vendors publishes a hash. They come from the vendor's site over HTTPS.

## Tool index

| Tool | Role |
|---|---|
| `mise` | Runtimes, plus fallback package manager for what `dnf`/`brew` lack |
| `stow` | Links each folder in `config/` into `~`, and refuses to overwrite a file that's already there |
| `zsh` | Login shell. POSIX-compatible, same language as the bash/zsh people I work with |
| `zsh-autosuggestions` / `zsh-syntax-highlighting` | Suggestions from history and live syntax coloring, which zsh lacks by default |
| `starship` | Prompt |
| `fzf` | Fuzzy finder (Ctrl-T / Ctrl-R / Alt-C) |
| `zoxide` | `cd` that remembers where you go |
| `eza` | `ls` replacement |
| `bat` | `cat` and pager with syntax highlighting |
| `ripgrep` (`rg`) | Fast recursive grep |
| `fd` | Simpler, faster `find` |
| `git-delta` | Syntax-highlighted pager for git diffs |
| `gh` | GitHub CLI for repos, PRs and issues |
| `podman` | Rootless container runtime with a Docker-compatible CLI. On the work Mac, Rancher Desktop instead |
| `neovim` | Terminal editor, stock config, for when there's no GUI |
| `tmux` | Terminal multiplexer. Sessions survive a closed window or a dropped SSH connection |
| `lazygit` | Terminal UI for git |
| `topgrade` | One command to upgrade Fedora or macOS (dnf/brew/mise/flatpak), then runs `audit.sh` |
| `lnav` | Log viewer with regex highlighting, for DAG and pipeline run logs |
| `jq` | JSON processor for API responses and pipeline output |
| `duckdb` | SQL straight on CSV, Parquet and JSON files, no server. Checks an extract or a pipeline output the way the warehouse would |
| `miller` (`mlr`) | awk/cut/sort by column name for CSV/TSV/JSON. Quick look at a data extract without opening Python |
| `yq` | `jq` syntax for YAML (Kubernetes manifests, DAG and pipeline configs) |
| `hyperfine` | Benchmarks a command over many runs. Used for the shell startup measurement |
| `pre-commit` | Runs git hooks per repo (linters, formatters, secret scans) |
| `shellcheck` | Lints shell scripts. Runs on `audit.sh` through this repo's pre-commit |
| `btop` | Resource monitor |
| `restic` | Encrypted, deduplicated backups of personal files (`BACKUP.md`) |
| `rclone` | restic's connection to Google Drive |
| `kubectl` | Kubernetes CLI. On the work Mac it comes with Rancher Desktop |
| `k9s` | Terminal UI for Kubernetes clusters |
| `kind` | Throwaway local Kubernetes cluster on Podman, for testing and learning (Fedora). Rancher Desktop does this on the work Mac |
| `wl-clipboard` | Clipboard on Fedora (Wayland) |
| `libnotify` / `terminal-notifier` | Desktop notifications on Fedora KDE / macOS. None on WSL2 |
| `uv` | Python packages and venvs, per project |
| `Zed` | Main GUI editor |
| `Ghostty` | Main terminal (Windows Terminal on WSL) |

## Installation priority: native package manager first, mise as fallback

Try `dnf` (Fedora) or `brew` (macOS) first. `mise` only installs what the official repos don't have. On Fedora that's `starship`, `lazygit`, `topgrade` and `duckdb`, marked Linux-only in `config/mise/.config/mise/config.toml`.

On macOS, `brew` has all of these. There, `mise` only handles language runtimes (`node`/`python`/`rust`/`go`/`java`).

Two things can't come from mise at all. The **login shell** (`zsh`) needs a real binary path registered in `/etc/shells`, and a shim won't do. **GUI apps** (`Zed`, `Ghostty`) need desktop integration.

## Audit

```bash
~/repos/zen-runbook/audit.sh

```

One check covers every package in `packages/` for this platform, every link from `config/`, and the settings a file check can't see (git identity and signing key, `gh` login, Podman rootless, login shell, plus the WSL2 interop, shared mount and Windows font, or the KDE font, Terra limit and snapper, plus the backup timer and its last run). On WSL2 it also checks the Windows apps through `winget.exe`. It only checks what's listed: anything else on the machine is ignored, so removing what I no longer use is on me (Minimal), not on the audit. It prints `OK`, `MISSING` or `MISMATCH` per line and exits 1 if anything isn't OK, so `topgrade` runs it after every upgrade.

It doesn't cover `HARDENING.md` (those checks need `sudo`) or the Steam/NVIDIA section of `APPS.md` (hardware-specific). Each keeps its own checks.

## Editing this repo

```bash
cd ~/repos/zen-runbook && pre-commit install

```

Once per clone. After that every commit runs `.pre-commit-config.yaml`: the JSON, TOML and YAML files must parse, and `shellcheck` must pass on `audit.sh`. A broken list or script then fails the commit instead of failing on the next machine.
