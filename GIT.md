# zen-runbook - git & GitHub CLI cheat sheet

`README.md`'s "Git identity, SSH key, and commit signing" section covers the one-time setup. This file is for day-to-day use: the commands I run often, and which ones are safe to run without thinking.

**Every command below is marked safe, reversible, or DANGER.** Safe commands never lose work. Reversible ones can be undone if you know how (usually with `reflog`). DANGER commands can permanently destroy uncommitted or unpushed work, so check first every time, no matter how many times you've run them before.

---

## Before anything that touches history or the working tree

One habit prevents most git disasters: **run `git status` first.** If it shows anything other than `nothing to commit, working tree clean`, decide what to do with those changes (stage, stash, or confirm you don't need them) before running anything from the DANGER section.

```bash
git status

```

---

## Everyday loop: all safe

```bash
git status                      # what's changed, what's staged
git diff                        # unstaged changes, line by line
git diff --staged               # staged changes, line by line
git add <file>                  # stage a specific file
git add -A                      # stage everything (new, modified, deleted)
git commit -m "message"         # commit what's staged
git log --oneline --graph -20   # last 20 commits, one line each, branch shape
git show <commit>                # full diff of one commit
git pull                        # fetch + integrate remote changes (rebases, per README.md's pull.rebase true)
git push                        # send local commits to the remote

```

None of these can lose committed work. `git add -A` stages everything, so read `git status` first to make sure you're not adding a file by accident.

## Branching: safe

```bash
git branch                      # list local branches
git switch -c my-branch         # create + switch to a new branch
git switch main                 # switch back
git merge my-branch             # merge my-branch into the current branch
git branch -d my-branch         # delete, but ONLY if already merged; refuses otherwise

```

`git branch -d` (lowercase) refuses to delete a branch with unmerged work, so the worst it does is print an error. Force delete is the capital `-D`, which is in the DANGER section.

## Undoing things: safe, in order of how much they touch

```bash
git restore <file>              # discard UNSTAGED changes to one file, see DANGER note below
git restore --staged <file>     # unstage a file, keep the edits in the working tree
git commit --amend              # rewrite the last commit's message or add staged changes to it
git revert <commit>             # create a NEW commit that undoes an old one, safe even after pushing

```

Once something is pushed, use `git revert`. It adds a new commit and leaves history alone, so it doesn't conflict with what a collaborator or my other machine already pulled. Only use `git commit --amend` on commits you haven't pushed. Amending a pushed commit changes its hash, which is the same problem as rebasing pushed history (see DANGER).

`git restore <file>` doesn't touch history, but it **does** throw away your uncommitted edits to that file for good. Run `git diff <file>` first if you're not sure what you'd lose.

## Stashing: safe

```bash
git stash                       # shelve uncommitted changes, working tree goes clean
git stash pop                   # reapply the most recent stash and remove it from the stash list
git stash list                  # see everything currently shelved

```

Use this when you need a clean working tree now but aren't ready to commit.

---

## DANGER: run `git status` first, every time

Each of these can permanently discard work. Run one only when you mean to, never as a quick fix copied from somewhere for an unrelated problem.

```bash
git reset --hard <commit>       # moves the branch AND discards all uncommitted changes, no undo
git checkout -- <file>          # old syntax for restore, same danger; discards uncommitted edits
git clean -fd                   # deletes untracked files AND untracked directories, no undo
git push --force                # overwrites the remote branch, can erase a collaborator's or another machine's work
git branch -D my-branch         # force-deletes a branch even with unmerged commits

```

**If you really need to force-push** (you fixed a bad commit that's already pushed and you're sure nobody pulled it), use `--force-with-lease` instead of `--force`. On a solo repo like this one nobody else pulls, but check on anything shared:

```bash
git push --force-with-lease

```

It refuses to push if the remote has commits you haven't fetched. Plain `--force` doesn't check, and the lease costs nothing.

**Rewriting pushed history** (interactive rebase, `filter-repo`, anything that changes old commit hashes) always needs a force-push, and always needs the same check: is anyone else relying on the old history? Example, rewording two commits that were already pushed:

```bash
git rebase -i HEAD~5             # opens an editor; mark the commit(s) to fix as "reword"
# git rewrites the message on save, one prompt per marked commit
git push --force-with-lease

```

For bigger jobs (removing a file from all of history, changing every author email), use `git filter-repo`. It's the current standard and is safer and faster than the old `git filter-branch`. I don't install it by default because I rarely need it: `pip install git-filter-repo` or `sudo dnf install git-filter-repo` when I do.

---

## If something already went wrong

`git reflog` is the safety net. It's a local log of everywhere `HEAD` has pointed, including commits that a `reset --hard` or a bad rebase just made unreachable. Git doesn't delete unreachable commits right away. They stay until garbage collection removes them (weeks, by default), and that's your window to recover them.

```bash
git reflog                      # find the commit hash from right before the mistake
git reset --hard <hash-from-reflog>   # move back to it

```

This only works **locally**. It can't bring back a branch that was force-pushed over on the remote, unless another clone (my other machine, for example) still has the old commits and can push them back. That's the main reason to use `--force-with-lease` over `--force`: it stops you from needing this in the first place.

---

## GitHub CLI (`gh`)

Setup and login are in `README.md`. These are the commands I use day to day.

```bash
gh repo create <name> --public                 # create a new empty repo on GitHub
gh repo create <name> --private
gh repo clone owner/repo                        # clone via gh instead of git clone, same result
gh repo view owner/repo --web                    # open the repo in a browser
gh repo rename <new-name>                        # rename the repo this directory is linked to
gh repo delete owner/repo                        # DANGER: permanent, asks for confirmation once

```

```bash
gh pr create                                     # open a PR from the current branch, interactive prompts
gh pr list                                       # list open PRs
gh pr view <number> --web                        # open a PR in the browser
gh pr checkout <number>                          # fetch a PR's branch locally to review it
gh pr merge <number>                             # merge a PR

```

```bash
gh issue create                                  # interactive prompts for title/body
gh issue list
gh auth status                                   # confirm gh is authenticated and which account

```

Treat `gh repo delete` like the DANGER commands. It can't be undone from the CLI. GitHub Support can sometimes restore a repo within a short window, but don't count on it. Before running it, know what's in the repo and whether anyone else has a clone.

It also needs the `delete_repo` scope, which `gh auth login` doesn't grant by default. That's on purpose: it's the same idea as the extension rule in `HARDENING.md`, where fewer standing permissions means less risk. `gh auth refresh -h github.com -s delete_repo` adds the scope, but there's no command to remove it. If you only needed it once, run `gh auth logout` and then a plain `gh auth login` (without `refresh`) so the token doesn't keep `delete_repo`.

---

## `lazygit`

Installed in `README.md`. It covers the everyday and branching commands above through a UI. Staging single hunks, browsing history and resolving merge conflicts are much faster there than typing the `git` flags by hand. I use the raw commands for scripts or when I need precision (like picking the exact commit for `rebase -i`), and `lazygit` for everything else.
