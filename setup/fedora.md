# Fedora: shared setup (WSL2 & KDE)

Same steps whether you just created the instance through WSL (`wsl.md`, step 1) or you're on bare-metal or a VM with Fedora KDE. When it's done, go to "Fedora WSL2: after the shared setup" in `wsl.md`, or "Fedora KDE: after the shared setup" below.

## 1. Get this repo

```bash
sudo dnf upgrade --refresh -y
sudo dnf install -y git
git clone https://github.com/Anoterrr/zen-runbook.git ~/repos/zen-runbook

```

HTTPS, because there's no SSH key yet. `git.md` switches the remote to SSH once there is. Every later step reads files from `~/repos/zen-runbook`, so if you clone somewhere else, change that path in the commands and in `config/topgrade/.config/topgrade.toml`.

## 2. Packages

```bash
sudo dnf install -y $(grep -v '^#' ~/repos/zen-runbook/packages/fedora.txt)

```

`packages/fedora.txt` is the one list of Fedora packages, grouped and commented. dnf has no list-file format of its own, so the `grep` just drops the comment lines. To add a tool, add a line there and run this again. dnf skips what's already installed.

A few notes on the list:

- `@development-tools` is the build toolchain group (Fedora's equivalent of Arch's `base-devel`). Use the lowercase group ID, because the display name (`"Development Tools"`) fails with `No match for argument`.
- `kubernetes1.37-client` (kubectl) and `k9s` are there because I run workloads on Kubernetes. Fedora packages kubectl once per minor version, with no unversioned `kubernetes-client` (as of 2026-10), because kubectl only supports clusters within one minor version of itself. Match the number to the cluster you use, and bump it when the cluster moves.
- `yq` is the mikefarah Go version. It uses the same query syntax as `jq`, for YAML.
- `pre-commit` is installed globally but does nothing in a repo until that repo has a `.pre-commit-config.yaml` and you run `pre-commit install`.
- `miller` (binary `mlr`) reads CSV by header name. `mlr --icsv --opprint head -n 5 file.csv` is a quick look at an extract without opening a Python REPL.
- `kind` runs a local Kubernetes cluster inside Podman containers, for testing manifests and learning. Real workloads run on cloud clusters. It needs step 4.
- `stow` links the files in `config/` into your home (`shell.md`, step 1).
- `podman-docker` adds a `docker` command that wraps Podman, so existing `docker` and `docker-compose` commands and scripts work unchanged. Podman runs rootless by default. There's no root daemon, no `usermod -aG docker`, and no third-party repo or GPG key to import like Docker's `docker-ce.repo` needs. It also goes on WSL2: Podman is a CLI tool, so the "GUI apps go on the Windows host" rule doesn't apply to it.

`starship`, `lazygit`, `topgrade` and `duckdb` aren't in Fedora's repos. They come from mise (`shell.md`, step 2).

## 3. Default shell → zsh

```bash
chsh -s /usr/bin/zsh

```

Fedora's `zsh` package adds itself to `/etc/shells` when installed. `chsh` applies from the next login. Don't open zsh before `shell.md` is done: with no `~/.zshrc` yet, zsh starts its first-run wizard (`zsh-newuser-install`), and a placeholder `~/.zshrc` would block the link that `shell.md` creates.

## 4. Local Kubernetes: let rootless containers use every cgroup controller

```bash
sudo mkdir -p /etc/systemd/system/user@.service.d
printf '[Service]\nDelegate=yes\n' | sudo tee /etc/systemd/system/user@.service.d/delegate.conf > /dev/null
sudo systemctl daemon-reload

```

By default systemd only hands `cpu`, `memory` and `pids` to your user session. A kind node is a whole Kubernetes node inside a rootless Podman container, and it also needs `cpuset` and `io`, so cluster creation fails without this. It applies right away, no reboot.

kind finds Podman by itself, through the `docker` command from `podman-docker`. Clusters are throwaway:

```bash
kind create cluster --name lab      # first run downloads the node image (a few minutes), then about a minute
kubectl get nodes                   # the context switches to kind-lab
kind delete cluster --name lab

```

kind's default node image is Kubernetes v1.35 (as of 2026-10), two minor versions behind the kubectl in `packages/fedora.txt`, which tracks the work clusters. kubectl only promises one minor version either way, though basic commands worked fine in testing. If something behaves oddly, pick a node image within one minor of kubectl from the kind release notes and pass it with `--image`.

---

# Fedora KDE: after the shared setup

Skip this on WSL2.

## Ghostty and Zed: via Terra repository

Neither is in the official Fedora repos.

```bash
sudo dnf install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra$(rpm -E %fedora)" -y terra-release
sudo dnf config-manager setopt terra.includepkgs="terra-release,ghostty*,zed*,dbeaver-bin"
sudo dnf install -y $(grep -v '^#' ~/repos/zen-runbook/packages/fedora-kde.txt)

```

The `setopt` line makes dnf ignore every Terra package except these (`dbeaver-bin` is for `../APPS.md`). It's saved in `/etc/dnf/repos.override.d/`, so it survives `terra-release` updates rewriting `terra.repo`. To take something else from Terra later, add it to that list first.

`packages/fedora-kde.txt` also has `fontconfig` (for the font below) and `libnotify`, which gives `notify-send`. macOS gets the same command from `~/.zshrc`.

## Snapshots before every dnf transaction (snapper)

Fedora KDE installs on Btrfs, which can snapshot the whole system in a second without copying anything. snapper takes one before and one after every `dnf` transaction, so an update that breaks something (most likely the NVIDIA driver, `../APPS.md`) can be undone. That's the rollback the immutable distros sell, from Fedora's own packages. `snapper` and `libdnf5-plugin-actions` were installed with `packages/fedora-kde.txt` above.

```bash
sudo snapper list-configs | grep -q '^root ' || sudo snapper -c root create-config /
sudo snapper -c root set-config TIMELINE_CREATE=no NUMBER_LIMIT=10
sudo systemctl enable --now snapper-cleanup.timer
sudo tee /etc/dnf/libdnf5-plugins/actions.d/snapper.actions > /dev/null <<'EOF'
# Example from the dnf5 actions plugin docs (man libdnf5-actions), plus "-c number" so old pairs get cleaned up.
pre_transaction::::/usr/bin/sh -c echo\ "tmp.snapper_descr=$(ps\ -o\ command\ --no-headers\ -p\ '${pid}')"
pre_transaction::::/usr/bin/sh -c echo\ "tmp.snapper_pre_number=$(snapper\ create\ -t\ pre\ -c\ number\ -p\ -d\ '${tmp.snapper_descr}')"
post_transaction::::/usr/bin/sh -c [\ -n\ "${tmp.snapper_pre_number}"\ ]\ &&\ snapper\ create\ -t\ post\ --pre-number\ "${tmp.snapper_pre_number}"\ -c\ number\ -d\ "${tmp.snapper_descr}"\ ;\ echo\ tmp.snapper_pre_number\ ;\ echo\ tmp.snapper_descr
EOF

```

- `TIMELINE_CREATE=no`: no hourly snapshots, only the dnf pairs. The rollback I need is "before that update", not "at 3 PM".
- `NUMBER_LIMIT=10` with the cleanup timer keeps the last 10 snapshots, enough for about five transactions back, and deletes older ones.
- Only `/` is snapshotted. `/home` (the vault, the masters, the repos) isn't, because undoing an update must never roll back my files.

Check it on the next install: `sudo snapper list` should show a `pre` and `post` pair with the dnf command as the description.

**Undo an update:**

```bash
sudo snapper list                          # find the pre/post pair of the bad transaction
sudo snapper -c root undochange 41..42     # pre..post numbers: puts back every file the transaction changed
sudo reboot

```

If the desktop doesn't come up (the usual NVIDIA failure), log in on a text console with Ctrl+Alt+F3 and run the same commands. `/boot` is a separate partition, so kernels aren't in the snapshot: for a bad kernel, pick the previous one in the boot menu instead, since Fedora keeps the last three. Snapshots live on the same disk, so they're an undo button, not a backup.

## Fonts

```bash
mkdir -p ~/.local/share/fonts
curl -Lo /tmp/jbmono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.zip"
echo "fab782a66f7d3019da64f6572db9fc5d3a4bcb19f9fa13e2d8a62e3693d6396e  /tmp/jbmono.zip" | sha256sum -c - \
  && unzip -oq /tmp/jbmono.zip -d ~/.local/share/fonts
rm -f /tmp/jbmono.zip
fc-cache -f ~/.local/share/fonts

```

Pinned to `v3.5.1` rather than `/latest/download/`, and checked against the hash in that release's `SHA-256.txt`. To upgrade, change the tag and take the new hash for `JetBrainsMono.zip` from the new release's `SHA-256.txt` (releases: https://github.com/ryanoasis/nerd-fonts/releases).

---

Next: `shell.md`. `../audit.sh` checks everything above (packages, the Terra limit, the font).
