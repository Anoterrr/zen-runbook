# zen-runbook - setup guide (Fedora WSL2 / Fedora KDE / macOS)

No executable scripts. Install `mise` first, then follow the section for your platform in order. Fedora WSL2 and Fedora KDE share one setup section in the middle. Later steps assume the earlier ones are done.

## Purpose

My personal environment baseline. It takes a fresh Fedora or macOS install to a working shell in one read-through, and every choice in it has a reason written next to it.

## Pillars

- **Simplicity**: no scripts, no hidden logic. You can read every command before you run it.
- **Organic**: native package manager first. Anything vendored or frozen says so.
- **Reproducibility**: pin a version when the ecosystem around the tool lags (Python, Java, fonts). Let it float when it doesn't (Node, Rust, Go).
- **Minimalism**: every tool has a stated reason to be here.
- **Performance**: shell startup time gets measured as one number (see the end of the shell configuration section). I don't benchmark each tool, because that would need redoing on every version bump. If the total jumps, that's when I go find the culprit.
- **Close to vanilla**: presets over deep customization. Neovim and tmux run on their stock defaults, with no distribution or framework on top.
- **Flexibility**: `~/.zshrc.local` holds machine-specific tweaks and survives reruns.
- **Scalability**: shared steps live in one place. Platform sections only hold what differs.
- **Free wins**: if something costs nothing (reusing a tool already installed, turning off default noise), take it.
- **Security**: every download comes from the vendor's own domain over HTTPS. A version pin also works as an integrity check, since a git commit hash is content-addressed. Where some trust has to be taken on faith (like installing a repo's signing key before it can verify anything), the guide says so.

## Trust boundaries

Two steps in this guide accept a known risk:

- **`curl | sh` installers** (`mise`, Homebrew). Each is the project's official install command, and neither publishes a checksum to verify against. I accept it because both are widely audited, served over HTTPS from their own domains, and this is how most of the ecosystem bootstraps.
- **Terra repo** (Fedora KDE only). The first `terra-release` install uses `--nogpgcheck`, as Terra's docs say, because that package is the one that installs the GPG key used to verify everything else. Terra is a third-party repo run by Fyra Labs, so it's limited to the packages this repo needs from it (see the Ghostty and Zed step). The rest of its ~3,000 packages stay invisible to dnf, including a few that share names with Fedora packages and could otherwise replace them on upgrade.

## Tool index

| Tool | Role |
|---|---|
| `mise` | Runtimes, plus fallback package manager for what `dnf`/`brew` lack |
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
| `podman` | Rootless container runtime with a Docker-compatible CLI |
| `neovim` | Terminal editor, stock config, for when there's no GUI |
| `tmux` | Terminal multiplexer. Sessions survive a closed window or a dropped SSH connection |
| `lazygit` | Terminal UI for git |
| `topgrade` | One command to upgrade everything (dnf/brew/mise/flatpak) |
| `lnav` | Log viewer with regex highlighting, for DAG and pipeline run logs |
| `jq` | JSON processor for API responses and pipeline output |
| `miller` (`mlr`) | awk/cut/sort by column name for CSV/TSV/JSON. Quick look at a data extract without opening Python |
| `yq` | `jq` syntax for YAML (Kubernetes manifests, DAG and pipeline configs) |
| `hyperfine` | Benchmarks a command over many runs. Used for the shell startup measurement |
| `pre-commit` | Runs git hooks per repo (linters, formatters, secret scans) |
| `btop` | Resource monitor |
| `kubectl` | Kubernetes CLI |
| `k9s` | Terminal UI for Kubernetes clusters |
| `wl-clipboard` / `terminal-notifier` / `wsl-notify-send` | Clipboard and desktop notifications, one per platform |
| `uv` | Python packages and venvs, per project |
| `Zed` | Main GUI editor |
| `Ghostty` | Main terminal (Windows Terminal on WSL) |

## Installation priority: native package manager first, mise as fallback

Try `dnf` (Fedora) or `brew` (macOS) first. `mise` only installs what the official repos don't have. On Fedora that's `starship`, `lazygit` and `topgrade`. `eza` and `lnav` have come and gone from Fedora's repos, so the guide tries `dnf` and falls back to `mise` if it fails.

On macOS, `brew` has all of these. There, `mise` only handles language runtimes (`node`/`python`/`rust`/`go`/`java`).

Two things can't come from mise at all. The **login shell** (`zsh`) needs a real binary path registered in `/etc/shells`, and a shim won't do. **GUI apps** (`Zed`, `Ghostty`) need desktop integration.

---

## mise: install first

Every section below uses `mise` as a fallback, so it goes in before anything else:

```bash
curl https://mise.run | sh
mkdir -p ~/.config/mise
echo '[tools]
node = "lts"
python = "3.13.15"
rust = "latest"
go = "latest"
java = "temurin-17"
uv = "latest"

[settings]
experimental = true
python.uv_venv_auto = "create|source"' > ~/.config/mise/config.toml
~/.local/bin/mise install

```

`python` and `java` are pinned because PySpark and JVM build tooling take a while to support new releases. Bump them by hand once your usual stacks work on the new version. `node`, `rust` and `go` track `lts`/`latest` since their ecosystems keep up, and per-project pins (e.g. via `uv` for Python) override this global default anyway.

If that exact patch has no prebuilt binary for your platform yet (they can lag a release by a few days), drop to the previous patch (`mise ls-remote python | grep '^3.13'` lists what's available), or build from source with `mise settings set python.compile false` and run `mise install` again.

Sanity check:

```bash
~/.local/bin/mise --version || echo "MISSING mise"
~/.local/bin/mise ls || echo "MISMATCH one or more [tools] failed to install, see output above"

```

---

## Fedora WSL2: prerequisite

```powershell
wsl --list --online
wsl --install FedoraLinux-44

```

Then do the shared Fedora setup below, and come back to "Fedora WSL2: after the shared setup" when it's done.

---

## Fedora: shared setup (WSL2 & KDE)

Same steps whether you just installed Fedora through WSL or you're on bare-metal or a VM with Fedora KDE.

### 1. System packages + build toolchain (equivalent to Arch base-devel)

Fedora has no single meta-package for build tools. They come as a DNF group. Use the lowercase group ID, because the display name (`"Development Tools"`) fails with `No match for argument`:

```bash
sudo dnf upgrade --refresh -y
sudo dnf group install -y development-tools
sudo dnf install -y git gh curl wget unzip zsh zsh-autosuggestions zsh-syntax-highlighting \
  fzf man-db less openssh-clients wl-clipboard fontconfig libnotify

```

Sanity check:

```bash
for bin in git gh curl wget unzip zsh fzf man ssh wl-copy fc-cache notify-send; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    test -r /usr/share/$plugin/$plugin.zsh && echo "OK      $plugin" || echo "MISSING $plugin"
done

```

### 2. CLI tools

```bash
sudo dnf install -y bat ripgrep fd-find zoxide git-delta neovim tmux jq yq miller btop \
  kubernetes-client k9s hyperfine pre-commit

sudo dnf install -y eza || mise use -g eza
sudo dnf install -y lnav || mise use -g lnav

mise use -g starship lazygit topgrade

```

A few notes on this list:

- `kubernetes-client` (kubectl) and `k9s` are here because I run workloads on Kubernetes. Both are in the official Fedora repos.
- `yq` is the mikefarah Go version. It uses the same query syntax as `jq`, for YAML.
- `hyperfine` runs the shell startup measurement at the end of the configuration section.
- `pre-commit` is installed globally but does nothing in a repo until that repo has a `.pre-commit-config.yaml` and you run `pre-commit install`.
- `miller` (binary `mlr`) reads CSV by header name. `mlr --icsv --opprint head -n 5 file.csv` is a quick look at an extract without opening a Python REPL.

Sanity check:

```bash
for bin in bat rg fd zoxide delta nvim tmux eza lnav jq yq mlr btop kubectl k9s hyperfine pre-commit; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done
for bin in starship lazygit topgrade; do
    test -x ~/.local/share/mise/shims/$bin && echo "OK      $bin" || echo "MISSING $bin"
done

```

### 3. Podman: container runtime

```bash
sudo dnf install -y podman podman-compose podman-docker

```

`podman-docker` adds a `docker` command that wraps Podman, so existing `docker` and `docker-compose` commands and scripts work unchanged. Podman runs rootless by default. There's no root daemon, no `usermod -aG docker`, and no third-party repo or GPG key to import like Docker's `docker-ce.repo` needs. This step also applies on WSL2: Podman is a CLI tool, so the "GUI apps go on the Windows host" rule doesn't apply to it.

Sanity check:

```bash
for bin in podman podman-compose docker; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done
podman info --format '{{.Host.Security.Rootless}}'   # should print true

```

### 4. Default shell → zsh

```bash
chsh -s /usr/bin/zsh
touch ~/.zshrc

```

Fedora's `zsh` package adds itself to `/etc/shells` when installed. The empty `~/.zshrc` stops zsh's first-run wizard (`zsh-newuser-install`) from opening. The real config gets written in the "Shell, prompt, and tool configuration" section below.

`chsh` applies from the next login. To switch the current shell right away:

```bash
exec zsh

```

zsh will have no aliases or integrations until that section is done. Run `exec zsh` again after it.

Sanity check:

```bash
getent passwd "$USER" | grep -q /usr/bin/zsh \
  && echo "OK      login shell is zsh" \
  || echo "PENDING chsh only applies at next login, run 'exec zsh' now, or log out and back in"

```

---

## Fedora WSL2: after the shared setup

### Notifications (Windows Toast integration)

The zsh config below already aliases `notify-send` to `wsl-notify-send.exe` when `$WSL_DISTRO_NAME` is set. All this step does is get the binary:

```bash
mkdir -p ~/.local/bin
# download wsl-notify-send.exe: https://github.com/stuartleeks/wsl-notify-send/releases

```

Sanity check:

```bash
command -v wsl-notify-send.exe >/dev/null \
  && echo "OK      wsl-notify-send.exe on PATH" \
  || echo "MISSING place wsl-notify-send.exe in ~/.local/bin"

```

### Zed, Ghostty, Fonts: installed on host Windows side

Ghostty doesn't run on Windows, so WSL uses Windows Terminal. Zed gets installed on Windows and connects to the Fedora WSL instance as a remote target, the same way VS Code Remote-WSL works. `git` isn't installed here because it's already inside Fedora WSL2 from the shared setup, and that's where the dev work happens:

```powershell
winget install -e --id ZedIndustries.Zed

```

Fonts also go on Windows directly. Use the same JetBrainsMono Nerd Font release as the Fedora KDE section below.

Sanity check:

```powershell
if (winget list -e --id ZedIndustries.Zed 2>$null | Select-String -SimpleMatch ZedIndustries.Zed) {
    Write-Host "OK      Zed"
} else {
    Write-Host "MISSING Zed"
}

```

---

## Fedora KDE: after the shared setup

### Fonts

```bash
mkdir -p ~/.local/share/fonts
curl -Lo /tmp/jbmono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.zip"
unzip -oq /tmp/jbmono.zip -d ~/.local/share/fonts && rm -f /tmp/jbmono.zip
fc-cache -f ~/.local/share/fonts

```

Pinned to `v3.5.1` rather than `/latest/download/`. To upgrade, change the tag by hand (releases: https://github.com/ryanoasis/nerd-fonts/releases).

Sanity check:

```bash
fc-list | grep -qi "JetBrainsMono Nerd Font" \
  && echo "OK      JetBrainsMono Nerd Font installed" \
  || echo "MISSING JetBrainsMono Nerd Font not found by fontconfig"

```

### Ghostty and Zed: via Terra repository

Neither is in the official Fedora repos.

```bash
sudo dnf install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra$(rpm -E %fedora)" -y terra-release
sudo dnf config-manager setopt terra.includepkgs="terra-release,ghostty*,zed*,dbeaver-bin"
sudo dnf install -y ghostty zed

```

The `setopt` line makes dnf ignore every Terra package except these (`dbeaver-bin` is for `APPS.md`). It's saved in `/etc/dnf/repos.override.d/`, so it survives `terra-release` updates rewriting `terra.repo`. To take something else from Terra later, add it to that list first.

Sanity check:

```bash
for bin in ghostty zed; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done
test "$(dnf repoquery -q --repo=terra --qf '%{name}\n' | grep -cvE '^(terra-release|ghostty|zed|dbeaver-bin)')" = 0 \
  && echo "OK      terra limited to includepkgs" \
  || echo "MISMATCH terra exposes more than ghostty/zed/dbeaver-bin"

```

### Notifications

Handled by `libnotify` from the shared setup.

---

## macOS

### 1. Homebrew for CLI tools, mise for runtimes only

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install git gh curl fzf openssh eza bat ripgrep fd zoxide git-delta \
  starship lazygit neovim tmux topgrade lnav terminal-notifier jq yq miller btop kubectl k9s \
  hyperfine pre-commit zsh-autosuggestions zsh-syntax-highlighting
brew install --cask zed ghostty font-jetbrains-mono-nerd-font

```

Sanity check:

```bash
for bin in git gh curl fzf ssh eza bat rg fd zoxide delta starship lazygit nvim tmux topgrade lnav terminal-notifier jq yq mlr btop kubectl k9s hyperfine pre-commit; do
    command -v $bin >/dev/null && echo "OK      $bin" || echo "MISSING $bin"
done
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    test -r /opt/homebrew/share/$plugin/$plugin.zsh && echo "OK      $plugin" || echo "MISSING $plugin"
done
for app in Zed Ghostty; do
    test -d "/Applications/$app.app" && echo "OK      $app.app" || echo "MISSING $app.app"
done

```

### 2. Default shell: zsh

macOS has used `/bin/zsh` as the default login shell since Catalina, so there's nothing to install or `chsh`. I use Apple's build instead of Homebrew's to have one less thing to upgrade. Only the plugins come from Homebrew (Step 1).

Sanity check:

```bash
dscl . -read "/Users/$USER" UserShell 2>/dev/null | grep -q /bin/zsh \
  && echo "OK      login shell is zsh" \
  || echo "MISMATCH run 'chsh -s /bin/zsh', applies at next login"

```

### 3. Notifications

`terminal-notifier` from Step 1. The `notify` function in `~/.zshrc` picks it up automatically.

---

## Git identity, SSH key, and commit signing

Basic setup. Needs `git` and `openssh` from your platform section.

### Git: identity and defaults

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase true

```

Sets your name and email for every commit. New repos start on `main`, and `pull` rebases instead of creating merge commits.

Sanity check:

```bash
git config --global user.name >/dev/null && git config --global user.email >/dev/null \
  && echo "OK      git identity set" \
  || echo "MISSING run 'git config --global user.name/user.email'"

```

### SSH key: skip this block if `~/.ssh/id_ed25519.pub` already exists

```bash
ssh-keygen -t ed25519 -C "you@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

```

Copy `~/.ssh/id_ed25519.pub` and add it on GitHub/GitLab under Settings → SSH keys as an **Authentication key**. That lets `git clone git@github.com:...` and `git push` work without a password.

Sanity check:

```bash
ssh -T git@github.com

```

If you see "Hi \<username\>! You've successfully authenticated", it worked. GitHub always exits 1 here and refuses a shell. That's normal.

### SSH config: two hardening lines

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo 'Host *
    IdentitiesOnly yes
    HashKnownHosts yes' >> ~/.ssh/config
chmod 600 ~/.ssh/config

```

`IdentitiesOnly` stops ssh from offering every key in `~/.ssh/` to every host. `HashKnownHosts` stops `~/.ssh/known_hosts` from listing the servers you've connected to in plain text.

Sanity check:

```bash
grep -q IdentitiesOnly ~/.ssh/config 2>/dev/null && grep -q HashKnownHosts ~/.ssh/config 2>/dev/null \
  && echo "OK      ~/.ssh/config hardened" \
  || echo "MISSING run the block above"

```

### Commit signing with the same SSH key

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true

```

Add the same public key to GitHub again, this time as a **Signing key**, on the same Settings → SSH keys page. Otherwise commits get signed locally but still show as unverified on GitHub.

Sanity check:

```bash
test "$(git config --global --get commit.gpgsign)" = true \
  && echo "OK      commits sign automatically" \
  || echo "MISMATCH commit.gpgsign is not true"

```

### GitHub CLI (`gh`)

`gh` was installed in your platform section. It authenticates with its own token, separate from the SSH key. `git push` and `git clone` use SSH, and `gh` uses the token to talk to GitHub's API (`gh repo create`, `gh pr create`, `gh issue list`, ...):

```bash
gh auth login --hostname github.com --git-protocol ssh --web

```

It prints a one-time code and a `github.com/login/device` URL. Open the URL, paste the code and approve. `--git-protocol ssh` makes `gh` clone over SSH with the key above instead of switching to HTTPS.

Sanity check:

```bash
gh auth status

```

Day-to-day commands and the rules for destructive ones (force-push, history rewrite, repo delete) are in `GIT.md`.

---

## Shell, prompt, and tool configuration

Run this after your platform section. It needs `zsh`, `starship`, `git-delta`, `lnav`, `topgrade`, `hyperfine` and `git` installed.

### zsh: ~/.zshrc

```bash
cat > ~/.zshrc <<'EOF'
# --- PATH -------------------------------------------------------------------
typeset -U path
path=($HOME/.local/bin $HOME/.local/share/mise/shims $path)
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# --- history: zsh keeps none on disk until told where -----------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space

# --- completion ---------------------------------------------------------------
autoload -Uz compinit && compinit

# --- vi keybinds (starship vi-mode indicator) -------------------------------
bindkey -v
bindkey -M viins '^?' backward-delete-char   # backspace past the point insert mode started

# --- man pages through bat: already installed, no new dependency -----------
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export PAGER="bat --plain"

# --- runtimes / tools / navigation (each executes only if binary exists) ----
(( $+commands[mise] ))     && eval "$(mise activate zsh)"
(( $+commands[zoxide] ))   && eval "$(zoxide init zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

# --- fzf (Ctrl-T, Ctrl-R, Alt-C) --------------------------------------------
(( $+commands[fzf] )) && source <(fzf --zsh)

# --- WSL: notify-send has no native implementation, wsl-notify-send.exe fills the gap ---
[[ -n $WSL_DISTRO_NAME ]] && alias notify-send='wsl-notify-send.exe'

# --- docker compatibility: the podman-docker package already provides a real
# `docker` binary on Fedora (works from cron/scripts too, not just here), so this
# only fires on macOS, where no such wrapper package exists (see APPS.md) ---
(( ! $+commands[docker] && $+commands[podman] )) && alias docker='podman'
(( ! $+commands[docker-compose] && $+commands[podman-compose] )) && alias docker-compose='podman-compose'

# --- cross-platform notifications: unified command name across all 3 machines ---
notify() {
    if (( $+commands[terminal-notifier] )); then
        terminal-notifier -title "${1:-Shell}" -message "$2"
    elif (( $+commands[notify-send] )); then
        notify-send "$1" "$2"
    fi
}

# --- aliases: direct and safe drop-in replacements only ----------------------
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git'
alias cat='bat --paging=never'
alias vim='nvim'

# --- local, machine-specific overrides: never touched or overwritten by this guide ---
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# --- plugins: last on purpose, syntax-highlighting has to load after every
# widget above (fzf, vi mode, anything in .zshrc.local) to color them ---
for dir in /usr/share /opt/homebrew/share; do
    [[ -r $dir/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
        && source $dir/zsh-autosuggestions/zsh-autosuggestions.zsh
    [[ -r $dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
        && source $dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
done
unset dir
EOF

```

Running this block again replaces `~/.zshrc` completely. Personal or machine-specific tweaks go in `~/.zshrc.local`, which the config loads but never creates or edits.

Out of the box, zsh doesn't save history to disk and has no suggestions or highlighting. The history block and the two plugins add those. The plugins come from `dnf`/`brew` and load with a plain `source`. I skipped plugin managers (Oh My Zsh, zinit) because they pull unpinned scripts from GitHub on every update, and two files don't need a manager.

Sanity check:

```bash
test -s ~/.zshrc && echo "OK      .zshrc written" || echo "MISSING .zshrc is empty or absent"
zsh -n ~/.zshrc && echo "OK      .zshrc is syntactically valid" || echo "MISMATCH zsh -n reported a syntax error above"

```

### starship (preset)

```bash
starship preset nerd-font-symbols -o ~/.config/starship.toml

```

Sanity check:

```bash
test -s ~/.config/starship.toml && echo "OK      starship.toml written" || echo "MISSING starship.toml is empty or absent"

```

### Ghostty: use the Nerd Font (Fedora KDE and macOS only)

Skip this on WSL, where Ghostty doesn't run. The font was installed so starship's icons render, but Ghostty won't use it until the config says so:

```bash
mkdir -p ~/.config/ghostty
echo 'font-family = "JetBrainsMono Nerd Font"' >> ~/.config/ghostty/config

```

Sanity check:

```bash
grep -q "JetBrainsMono Nerd Font" ~/.config/ghostty/config 2>/dev/null \
  && echo "OK      ghostty font-family set" \
  || echo "MISSING run this step (or ignore if you're on WSL)"

```

### git: delta as the diff/merge pager

`git-delta` is installed, but git only uses it once configured:

```bash
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"

```

Sanity check:

```bash
test "$(git config --global --get core.pager)" = delta \
  && echo "OK      git core.pager is delta" \
  || echo "MISMATCH git core.pager is not delta"

```

### lnav: regex log highlighting

```bash
mkdir -p ~/.lnav/formats/installed
echo '{
  "custom-highlights": {
    "highlights": {
      "error": { "pattern": "(?i)error|fail(ed|ure)?", "color": "Red" },
      "warn":  { "pattern": "(?i)warn(ing)?",           "color": "Yellow" },
      "ok":    { "pattern": "(?i)success|done|✓",        "color": "Green" }
    }
  }
}' > ~/.lnav/formats/installed/custom-highlights.json

```

Sanity check:

```bash
test -s ~/.lnav/formats/installed/custom-highlights.json \
  && echo "OK      custom-highlights.json written" \
  || echo "MISSING custom-highlights.json is empty or absent"

```

### topgrade: system-wide upgrades (dnf/brew + mise + flatpak)

```bash
mkdir -p ~/.config
echo '[misc]
assume_yes = false
no_retry = false

[git]
max_concurrency = 5' > ~/.config/topgrade.toml

```

`topgrade` updates what it detects (dnf/brew, flatpak, git repos). Its `mise` support isn't documented as complete, so run `mise upgrade` separately until you've confirmed it on your machine. `topgrade --dry-run` lists every step it detected.

Sanity check:

```bash
test -s ~/.config/topgrade.toml && echo "OK      topgrade.toml written" || echo "MISSING topgrade.toml is empty or absent"

```

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

Sanity check:

```bash
tmux new -d -s sanity && tmux has -t sanity && tmux kill-session -t sanity \
  && echo "OK      tmux can start, detach and kill a session" \
  || echo "MISMATCH tmux failed to start a session"

```

### Performance: measure shell startup time

Everything the config loads (`compinit`, `mise activate`, `zoxide init`, `starship init`, `fzf --zsh`, the two plugins) runs every time a shell opens. To see how long that takes:

```bash
hyperfine --warmup 3 'zsh -i -c exit'

```

Look at the mean. That's the delay you get every time you open a terminal. `hyperfine` runs the command many times and reports the spread too, so one slow run (cold disk cache, busy CPU) won't look like a regression the way it would with a single `time`. I haven't set a target number. Run it after setup and again whenever you add something to `.zshrc.local`. If it jumps, comment out one integration at a time in `~/.zshrc` and re-run until you find which one did it.

---

## Full audit (all platforms)

Each sanity check above runs once, right after its step. That catches a failed install on day one, but not a machine that drifts later: signing never turned on, `pull.rebase` never set, `delta` installed but not configured as the pager. This section collects every check in one place so you can paste it again whenever something seems off.

Binaries:

```bash
for bin in mise starship nvim tmux lazygit eza bat rg fd delta zsh fzf lnav topgrade zoxide jq yq mlr btop kubectl k9s gh podman hyperfine pre-commit; do
    printf '%-11s ' $bin
    if command -v $bin >/dev/null; then
        $bin --version 2>/dev/null | head -n1 | grep . || echo "installed (no --version flag)"
    else
        echo MISSING
    fi
done

```

Configuration, which a binary check can't see:

```bash
git config --global user.name >/dev/null && git config --global user.email >/dev/null \
  && echo "OK      git identity" || echo "MISSING git identity"
test "$(git config --global --get pull.rebase)" = true \
  && echo "OK      pull.rebase" || echo "MISSING pull.rebase"
test "$(git config --global --get commit.gpgsign)" = true \
  && echo "OK      commit signing" || echo "MISSING commit signing"
test "$(git config --global --get core.pager)" = delta \
  && echo "OK      delta as git pager" || echo "MISSING delta as git pager"
grep -q IdentitiesOnly ~/.ssh/config 2>/dev/null && grep -q HashKnownHosts ~/.ssh/config 2>/dev/null \
  && echo "OK      ~/.ssh/config hardened" || echo "MISSING ~/.ssh/config hardening"
gh auth status >/dev/null 2>&1 \
  && echo "OK      gh authenticated" || echo "MISSING gh auth login"
if command -v podman >/dev/null; then
  test "$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null)" = true \
    && echo "OK      podman rootless" || echo "MISMATCH podman not running rootless"
fi
test -s ~/.zshrc && echo "OK      .zshrc" || echo "MISSING .zshrc"
test -s ~/.config/starship.toml && echo "OK      starship.toml" || echo "MISSING starship.toml"
test -s ~/.config/topgrade.toml && echo "OK      topgrade.toml" || echo "MISSING topgrade.toml"
test -s ~/.lnav/formats/installed/custom-highlights.json && echo "OK      lnav highlights" || echo "MISSING lnav highlights"

```
