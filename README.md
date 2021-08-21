# ymendel's dotfiles

For system personalization, easy set-up, &c &c.

## Consideration

This repo is really just for me, and I'll be honest and say that right now. I also don't have a lot of different machines, so
it tends to be more targetted and less robust for widespread use than other dotfiles repos you may find. With that said, I'm
far from against other people using any of this. I just felt I should make that clear.

Also, if you want to use these dotfiles, I strongly suggest you first review the contents and see what works for you. Make your
own copy. It's all about personalizing a system to you, not just blindly using someone else's settings. You could be in for a bad
time if you do that.

## Installation

### Using git and the bootstrap script

This can be cloned wherever you like, but I like to keep it along with other projects in `~/dev/projects/mine`. The bootstrap
script will create the `~/.dotfiles` symlink, among other things.

```bash
git clone https://github.com/ymendel/dotfiles.git
cd dotfiles
script/bootstrap
```
## Organization

### Topics

This is separated into _topic_ directories. Instead of a single large file (or a small set of large files) to handle everything,
things are broken up into small directories and files (viz. `git`, `ruby`, `system`, `shell`, `macos`). I find it easier to 
understand and handle with this separation.

### Locations

- **script/**: This is the location for scripts and commands that handle the dotfiles project itself, like `script/bootstrap`
- **bin/**: This gets added to the `$PATH` and anything in here is available to run everywhere. This is a sort of general, catch-all
  location for commands and utilities that don't fit elsewhere. Also, `updot` lives here. ([see below](#updot))
- _topic_/**bin/**: These directories also get added to the `$PATH`, for topic-related commands that will be made available to run everywhere.
- _topic_/**\*.bash**: Any files ending in `.bash` get loaded into the environment.
- _topic_/**install.sh**: Any file named `install.sh` is executed by `script/install` (which is run by `updot`). These end in `.sh`
  instead of `.bash` to avoid being loaded automatically.
- _topic_/**\*.symlink**: Any file ending in `.symlink` gets symlinked into `$HOME` with a prepended `.` (e.g. `git/gitconfig.symlink` → `~/.gitconfig`)
  This lets all of these files stay versioned in the dotfiles repository, but still be useful in their expected locations.
  These files are symlinked by `script/bootstrap` (not `updot`).
- **~/.local/bashrc**: This file will be sourced if it exists, allowing you to have special per-machine differences.

## Rejuvenation

### `updot`

The `updot` command is provided to easily stay up-to-date. It installs dependencies, runs install scripts, sets defaults, &c.
Run this script occasionally to keep your system and environment up-to-date.

**Note**: Running `updot` will _not_ update the git repository, and this is by design. It _only_ updates the system with
the current contents of the repository. It also (by design) doesn't update already-installed Homebrew formulae. Those can
be handled separately with `brew`.

## Appreciation

This organization was largely inspired by [Zach Holman](http://github.com/holman) and his wonderful dotfiles repo.
There were some things I wanted to do differently. Some of those I gave up on simply because his stuff was so good.

Along the way, I've gotten a good bit from other repos. Of particular note, and in no particular order:

- [holman dotfiles](http://github.com/holman/dotfiles)
- [mathiasbynens dotfiles](https://github.com/mathiasbynens/dotfiles)
