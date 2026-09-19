# zen-runbook — git & GitHub CLI cheat sheet

Companion to `README.md`'s "Git identity, SSH key, and commit signing" section, which covers one-time setup. This file is the day-to-day reference: the commands actually used often enough to be worth memorizing, and — more importantly — a clear line between what's safe to run without thinking and what isn't.

The organizing principle: **every command below is tagged safe, reversible, or DANGER.** Safe commands never lose work. Reversible ones can undo real damage if you know the trick (mostly `reflog`). DANGER commands can permanently destroy uncommitted or unpushed work — those get a stop-and-check step every time, no exceptions, even on your 500th commit.

---

## Before anything that touches history or the working tree

One habit prevents almost every git disaster: **run `git status` first.** If it says anything other than `nothing to commit, working tree clean`, stop and decide what to do with those changes (stage them, stash them, or confirm you don't care about them) before running a command from the DANGER section below.

```bash
git status

```

---

## Everyday loop — all safe

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

None of these can lose committed work. `git add -A` is safe specifically because this repo has no `.gitignore` surprises to worry about — always worth a `git status` read before it anyway, to catch a file you didn't mean to add.

## Branching — safe

```bash
git branch                      # list local branches
git switch -c my-branch         # create + switch to a new branch
git switch main                 # switch back
git merge my-branch             # merge my-branch into the current branch
git branch -d my-branch         # delete, but ONLY if already merged — refuses otherwise

```

`git branch -d` (lowercase) is the safe delete — it's a no-op error, not data loss, if the branch has unmerged work. That guardrail is exactly why the DANGER section below has a separate, capital-`-D` entry.

## Undoing things — safe, in order of how much they touch

```bash
git restore <file>              # discard UNSTAGED changes to one file — see DANGER note below
git restore --staged <file>     # unstage a file, keep the edits in the working tree
git commit --amend              # rewrite the last commit's message or add staged changes to it
git revert <commit>             # create a NEW commit that undoes an old one — safe even after pushing

```

`git revert` is the one to reach for once something is already pushed — it never rewrites history, so it never conflicts with what a collaborator (or your other machine) already pulled. `git commit --amend` is only safe if that commit hasn't been pushed yet — amending a pushed commit is the same category of problem as the DANGER section's rebase entry, because it changes a commit's hash after the world has already seen it.

`git restore <file>` is listed as safe with a caveat: it's safe in the sense that it doesn't touch history, but it **does** permanently discard uncommitted edits to that file, no undo. Run `git diff <file>` first if there's any doubt about what you'd be throwing away.

## Stashing — safe

```bash
git stash                       # shelve uncommitted changes, working tree goes clean
git stash pop                   # reapply the most recent stash and remove it from the stash list
git stash list                  # see everything currently shelved

```

The move for "I need a clean working tree right now but I'm not ready to commit this."

---

## DANGER — confirm `git status` first, every time

Each of these can permanently discard work. The trigger for using one should always be a deliberate decision, never a reflex or a copy-pasted fix for an unrelated problem.

```bash
git reset --hard <commit>       # moves the branch AND discards all uncommitted changes, no undo
git checkout -- <file>          # old syntax for restore, same danger — discards uncommitted edits
git clean -fd                   # deletes untracked files AND untracked directories, no undo
git push --force                # overwrites the remote branch, can erase a collaborator's or another machine's work
git branch -D my-branch         # force-deletes a branch even with unmerged commits

```

**If a force-push is genuinely necessary** (fixed a bad commit that's already pushed, and you're certain nobody else pulled it — true by default on a solo repo like this one, but confirm on anything shared), use `--force-with-lease` instead of bare `--force`:

```bash
git push --force-with-lease

```

It refuses the push if the remote has commits you haven't fetched yet — the one guardrail bare `--force` doesn't have, at essentially zero extra cost.

**Rewriting already-pushed history** (interactive rebase, `filter-repo`, anything that changes old commit hashes) always needs a force-push to actually land, and always needs the same "is anyone else relying on the old history" check first. The worked example below is the exact command used to strip a `Co-Authored-By` trailer from two already-pushed commits in this repo's own history:

```bash
git rebase -i HEAD~5             # opens an editor; mark the commit(s) to fix as "reword"
# git rewrites the message on save, one prompt per marked commit
git push --force-with-lease

```

For anything heavier than a couple of commits (stripping a file from all of history, rewriting every author email), `git filter-repo` is the current standard tool — safer and faster than the older `git filter-branch`. Not installed by default here since it's a rare-enough operation; `pip install git-filter-repo` or `sudo dnf install git-filter-repo` when actually needed.

---

## If something already went wrong

`git reflog` is the safety net underneath almost everything above — it's a local log of every place `HEAD` has pointed, including commits a `reset --hard` or a bad rebase just made unreachable. Unreachable commits aren't deleted immediately; they sit until git's garbage collector eventually sweeps them (weeks, by default), which is exactly the window that makes recovery possible.

```bash
git reflog                      # find the commit hash from right before the mistake
git reset --hard <hash-from-reflog>   # move back to it

```

This only works **locally** — it can't recover a branch that got force-pushed away on the remote unless another clone (this repo's other machine, for instance) still has the old commit and can push it back. That asymmetry is the real argument for `--force-with-lease` over `--force`: it's the check that prevents needing this recovery path in the first place.

---

## GitHub CLI (`gh`) — the API side, no browser needed

Setup and auth are in `README.md`. Below is what gets used day to day.

```bash
gh repo create <name> --public                 # create a new empty repo on GitHub
gh repo create <name> --private
gh repo clone owner/repo                        # clone via gh instead of git clone — same result
gh repo view owner/repo --web                    # open the repo in a browser
gh repo rename <new-name>                        # rename the repo this directory is linked to
gh repo delete owner/repo                        # DANGER — permanent, asks for confirmation once

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

`gh repo delete` is the one command on this list that belongs in spirit next to the DANGER section above — it's not reversible from the CLI at all (GitHub Support can sometimes restore within a short window, but that's not something to plan around). Same rule applies: know exactly what's in the repo and whether anyone else has a clone before running it.

---

## `lazygit` — when the terminal UI is faster than typing

Already installed per `README.md`. Covers the everyday loop and branching sections above through a visual interface — staging individual hunks, browsing history, and resolving merge conflicts are all meaningfully faster there than composing the equivalent `git` flags by hand. Reach for the raw commands above when scripting or when precision matters (e.g. picking the exact commit for `rebase -i`); reach for `lazygit` for everything exploratory.
