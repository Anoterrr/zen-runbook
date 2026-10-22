# macOS

## 1. Homebrew, this repo, packages

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

git clone https://github.com/Anoterrr/zen-runbook.git ~/repos/zen-runbook
brew bundle --file ~/repos/zen-runbook/packages/macos.Brewfile

```

The Homebrew installer also installs Apple's Command Line Tools, which bring `git`, so the clone works before `brew bundle` runs. HTTPS, because there's no SSH key yet. `git.md` switches the remote to SSH once there is.

`packages/macos.Brewfile` is Homebrew's own list format. `brew bundle` installs what's missing and skips the rest, and `brew bundle check` (which `../audit.sh` runs) reports what's missing without installing anything. To add a tool, add a line there.

On macOS, `brew` has every CLI tool, so `mise` only handles language runtimes (`shell.md`, step 2).

## 2. Default shell: zsh

macOS has used `/bin/zsh` as the default login shell since Catalina, so there's nothing to install or `chsh`. I use Apple's build instead of Homebrew's to have one less thing to upgrade. Only the plugins come from Homebrew.

## 3. Notifications

`terminal-notifier` is in the Brewfile. `~/.zshrc` defines `notify-send` on macOS on top of it, so the same command works here and on Fedora KDE.

## 4. Rancher Desktop (work Mac: containers and local Kubernetes)

This Mac is my work machine, so it gets Rancher Desktop instead of the Podman the Fedora setups use: it's what the teams use, so their docs and scripts work as written. Real workloads run on cloud clusters. The local cluster is for testing manifests and learning. Rancher Desktop runs a small Linux VM with k3s (a local Kubernetes cluster) and a container engine, and ships `docker`, `kubectl`, `helm` and `nerdctl` in `~/.rd/bin`. That's why the Brewfile has no `kubectl` or `podman` for macOS.

First launch, in Preferences:

- **Container Engine**: `dockerd (moby)`, so `docker` and `docker compose` work like on any other machine.
- **Kubernetes**: on, with the version closest to the work clusters (kubectl supports one minor version either way).
- **Application → Environment → PATH configuration: Manual.** The default (Automatic) edits `~/.zshrc` and `~/.zprofile` to add `~/.rd/bin`. `~/.zshrc` is linked into the repo, so it would write into the repo. The macOS block of `config/zsh/.zshrc` already adds `~/.rd/bin`.

---

Next: `shell.md`. `../audit.sh` checks the Brewfile, the login shell and that `kubectl` resolves to Rancher Desktop's.
