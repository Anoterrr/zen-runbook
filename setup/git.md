# Git identity, SSH key, and commit signing

Run this after `shell.md`, which links the shared git defaults and the SSH hardening. This file covers the per-machine part. Day-to-day commands and the rules for destructive ones (force-push, history rewrite, repo delete) are in `../GIT.md`.

## Identity: per machine, in `~/.gitconfig`

```bash
git config --file ~/.gitconfig user.name "Your Name"
git config --file ~/.gitconfig user.email "you@example.com"

```

`--file ~/.gitconfig` and not `--global`: when `~/.gitconfig` doesn't exist yet, `--global` writes to `~/.config/git/config`, which is the linked file in the repo. Once `~/.gitconfig` exists, `--global` writes there too.

## SSH key: skip this block if `~/.ssh/id_ed25519.pub` already exists

```bash
ssh-keygen -t ed25519 -C "you@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

```

Copy `~/.ssh/id_ed25519.pub` and add it on GitHub/GitLab under Settings → SSH keys as an **Authentication key**. That lets `git clone git@github.com:...` and `git push` work without a password.

```bash
ssh -T git@github.com

```

If you see "Hi \<username\>! You've successfully authenticated", it worked. GitHub always exits 1 here and refuses a shell. That's normal.

Now switch this repo from the HTTPS clone to SSH, so you can push:

```bash
git -C ~/repos/zen-runbook remote set-url origin git@github.com:Anoterrr/zen-runbook.git

```

## Commit signing with the same SSH key

```bash
git config --file ~/.gitconfig user.signingkey ~/.ssh/id_ed25519.pub

```

The shared config already turns signing on (`gpg.format ssh`, `commit.gpgsign true`), so until this key is set, every commit fails. Add the same public key to GitHub again, this time as a **Signing key**, on the same Settings → SSH keys page. Otherwise commits get signed locally but still show as unverified on GitHub.

## GitHub CLI (`gh`)

`gh` authenticates with its own token, separate from the SSH key. `git push` and `git clone` use SSH, and `gh` uses the token to talk to GitHub's API (`gh repo create`, `gh pr create`, `gh issue list`, ...):

```bash
gh auth login --hostname github.com --git-protocol ssh --web

```

It prints a one-time code and a `github.com/login/device` URL. Open the URL, paste the code and approve. `--git-protocol ssh` makes `gh` clone over SSH with the key above instead of switching to HTTPS.

---

Setup is done. Run `../audit.sh`: it checks everything from every file in `setup/`, and prints only what's missing or wrong next to an `OK` line for the rest.
