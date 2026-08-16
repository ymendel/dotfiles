# demo

Scripted terminal demos, built on [demo-magic.sh](https://github.com/paxtonhare/demo-magic).

demo-magic drives a live demo: one `pe 'command'` call per step, press ENTER to advance. It works,
and it is ~250 lines of bash, going back to 2015, that (in my opinion) needs the same set of local
repairs and extensions every time it gets used. That's what this is for.

## Using it

```bash
#!/usr/bin/env bash
source "$(demo-lib)"

say "First, the orders that already exist"
hold
pe 'http GET :3000/orders'

say "Creating one takes a customer and a total" "Watch the location header"
hold
pe 'http POST :3000/orders customer=alice total=42'
```

`demo-lib` is on `$PATH` (via the topic `bin/` convention) and prints the wrapper's location, so a
demo script committed to a project doesn't hardcode a path into this repo. It does mean that this
wrapper/harness is necessary to run the demo script. So it goes.

Flags: every demo-magic flag still works — `-d` (no typing), `-n` (no waiting), `-c` (command
numbers), `-w N` (auto-advance after N seconds) — plus `--unattended`.

## What the wrapper provides

| Name | What it does |
|---|---|
| `say` | narration block above a command, dimmed, one argument per line |
| `hold` | manual pause that ignores `PROMPT_TIMEOUT`, for advancing between steps, with an animated hint |
| `demo_commands` | the demo's commands with the `pe` wrapper stripped, for the closing reveal |
| `--unattended` | runs start to finish with no typing and no pauses, as a smoke test |

Knob precedence is flag, then environment, then the wrapper's default:

| Knob | Default | Flag |
|---|---|---|
| `TYPE_SPEED` | 40 | `-d` empties it |
| `PROMPT_TIMEOUT` | 1 | `-w N` |
| `DEMO_PROMPT` | `$ ` | none |

`hold`'s hint has its own knobs, none of which demo-magic knows about:

| Knob | Default | What it does |
|---|---|---|
| `DEMO_HOLD_FRAMES` | `MARQUEE` | which frame set to animate — `BREATHE`, `CARET`, `ELLIPSIS` and `SPINNER` are the others |
| `DEMO_HOLD_INTERVAL` | the chosen set's own | seconds between frames |
| `DEMO_HOLD_HINT` | `ENTER` | the word beside the animation |
| `DEMO_HOLD_COLOR` | `$GREY` | its colour |

So `DEMO_HOLD_FRAMES=CARET ./demo.sh` switches for one run without editing anything. Add a set by
declaring `DEMO_HOLD_FRAMES_<NAME>` and `DEMO_HOLD_INTERVAL_<NAME>` beside the others — the interval
is stated per set, explicitly.

## Why the repairs exist

There are five things that demo-magic gets plain wrong.

**It clobbers your settings at source time.** `TYPE_SPEED`, `PROMPT_TIMEOUT` and `DEMO_PROMPT` are
assigned unconditionally when the file is sourced, so a value already in the environment is gone by
the time you get control back — and a `${VAR:-default}` written *after* the source is a no-op,
because the variable is set to demo-magic's default by then. The wrapper captures the wanted values
before sourcing and re-applies them after.

**But the re-apply has to be conditional per knob, or it eats the command-line flag.** Fixing the
above fell into this trap. Two of the three knobs have a flag that `getopts` parses *during*
sourcing demo-magic. They need different detection:

- `-d` **unsets** `TYPE_SPEED`, which is detectable after the fact — hence the guard on
  `[[ -n "${TYPE_SPEED+set}" ]]`. If it's unset now, the flag was given and must win. The wrapper
  binds it back to empty immediately afterward, for the reason in the next repair, by which point
  the detection has already happened.
- `-w N` **assigns** `PROMPT_TIMEOUT`, and demo-magic's own default is already `0`, so `-w0`
  (deliberately manual) is indistinguishable from no flag at all once the source has run. The flag
  has to be noticed by scanning the arguments *before* sourcing, matching `-*w*` rather than exactly
  `-w` so the bundled forms count — `-dw5` as much as `-w5` and `-w 5`.
- `DEMO_PROMPT` has no flag, so unconditional is correct there.

**It is not `set -u` clean in two separate places, and that breaks its own documented `-d` flag.**
The `-d` handler runs `unset TYPE_SPEED`, and two later lines then read that variable unguarded.
Line 253 runs at *source* time, so a strict-mode script aborts while sourcing and loses `-d`
entirely — the wrapper relaxes nounset across the source and restores it after. Line 107 runs inside
`p` and `pe`, at *call* time, which the first repair cannot reach: the script survives the source
and then dies on its first command instead. So once the wrapper has finished detecting the flag it
binds `TYPE_SPEED` back to the empty string. Empty is precisely what that line's `-z` test is
looking for, so `-d` keeps its meaning and there is nothing unbound left to trip over.

**It gives you one pause where a demo wants two.** demo-magic's `wait` (inside `pe`) is bounded by
`PROMPT_TIMEOUT`, which is right for the run-the-command step — a command should fire shortly after
it finishes typing. Advancing to the *next* command should stay manual, so `hold` is a separate
untimed pause. This may actually be an enhancement rather than a bugfix, but it seems central
enough to say here.

This untimed pause is given an animated hint, so it can be distinguished from a situation where
the demo has hung. There are a few animation choices, shown in a table above.

**It sets the terminal on every command, including when there is no terminal.** `run_cmd` wraps each
command in `stty -echoctl` / `stty echoctl`, so that a `^C` doesn't echo. With stdin closed — which
is how an unattended run keeps its pauses from blocking — both calls fail with
`stty: stdin isn't a terminal`. This plops two stderr lines in front of every command in the one run
whose whole job is to surface real errors. The wrapper redefines `run_cmd` with upstream's body
verbatim plus a `[[ -t 0 ]]` guard around the `stty` pair, so a live run behaves exactly as before
and only the terminal-less case changes.

## Traps worth knowing while writing a demo

**Backslashes in a `pe` string must be doubled.** demo-magic renders the command through
`echo -en "$cmd"`, which interprets escapes at *display* time. A single `\n` executes correctly but
shows on screen as a literal line break, splitting the command in half mid-demo. `\\n` displays as
`\n` and still reaches the command as `\n`. e.g. `curl -w "\\n"`

**An unattended run breaks every httpie POST unless stdin is handled.** With stdin redirected from
`/dev/null` so the pauses don't block, httpie treats stdin as a request body and refuses to combine
it with `key=value` items. Calls sending only headers still succeed, which is what makes it
confusing — the failure looks selective and API-shaped rather than tooling-shaped, and the empty
variables it leaves behind cascade into downstream 401s that look like real regressions. The fix is
`--ignore-stdin`, applied here through `httpie-unattended/config.json` and exported as
`HTTPIE_CONFIG_DIR` only in unattended mode, so it stays off the commands the audience is reading.

**Anything verified only with output redirected has not been verified as a presentation.** httpie
prints response headers plus body on a tty and body-only when stdout is redirected, so an unattended
run and a live run show *different things* — a header block that buries the body off the bottom of
the screen is invisible to a redirected smoke test. Relatedly, `--print` is section-granular with no
per-header selection and the status line always arrives bundled with the headers, so "status line
plus body, no headers" isn't expressible natively; and `--check-status` writes its warning to stderr
only *if stdout is redirected*, so it fires in exactly the case that doesn't matter. Body-only by
default is the usual answer, with a filter on the beats where a status code is the point.

**demo-magic shadows the `wait` builtin.** It defines a function named `wait` — its own
press-ENTER pause — which takes precedence over the builtin for everything sourced alongside it. So
a bare `wait "$pid"` silently ignores its argument and blocks on a `read`, and anything that
backgrounds a process and waits on it needs `builtin wait` instead. The animated `hold` hint is
built on exactly that, and the first draft of it wanted a second ENTER for precisely this reason.

**A demo script can't use `set -e`.** That same `wait` is `read -rst "$PROMPT_TIMEOUT"`, and a
timed-out `read` returns 142. Timing out is what the read is *for*, so under `set -e` the first `pe`
you don't answer within `PROMPT_TIMEOUT` kills the script — before it types the command, which makes
it look like the demo broke rather than the shell option. The wrapper turns this from unlikely into
certain: upstream defaults `PROMPT_TIMEOUT` to `0`, which takes the untimed `read -rs` branch and
returns 0, while the wrapper's default of `1` is a timed read by design. `set -u` is fine — that one
is repaired, above.

## Layout

- `bin/demo-lib` — prints the wrapper's path, for `source "$(demo-lib)"`
- `lib/demo-wrapper.sh` — the repairs and helpers
- `vendor/demo-magic.sh` — upstream, unmodified
- `httpie-unattended/` — the httpie config dir used only by `--unattended`
- `test/run-checks.sh` — the repairs, checked; run it after bumping vendored demo-magic

Every repair above is a behavior an unrepaired demo-magic gets wrong, which makes them all
checkable. `test/run-checks.sh` does that — precedence for each knob across flag, environment and
default, `-d` under strict mode, an unattended run end to end, and the httpie stdin trap in both
directions. It covers the terminal-less path only. The live path is upstream's own body, reached
whenever stdin is a terminal.

Upstream is vendored rather than fetched. It ships no tags and no releases, so there is nothing to
pin against, and it does still take commits — meaning a fetched copy could shift under the repairs,
which are written against specific behavior in this file. Vendoring also removes a setup step. Bump
it by replacing the file and re-reading the repairs above against it.

`pv` is a hard dependency of simulated typing — demo-magic aborts without it whenever `TYPE_SPEED`
is set.

bash 4.3 or newer is a hard dependency of the wrapper, for the nameref that selects `hold`'s frame
set. That rules out the 3.2 Apple still ships as `/bin/bash` and rules in anything from Homebrew, so
write the shebang as `#!/usr/bin/env bash` — as the usage example above does — rather than
hardcoding `/bin/bash`.

## Not here yet

Chapters. A demo long enough to be worth scripting is long enough to want to start partway through
it, and the shape that works is one function per act, registered in an ordered array, with `--list`,
`--from` and `--only`. This can be tricky because a "skipped" chapter may well break the demo if
it's _actually_ skipped. The whole script shares state, and later commands probably build on
actions executed in earlier commands. So jumping past chapters actually means *doing them silently*.
This has been done once, and it involved a `QUIET` flag threaded through `say`, `hold` and a `step` 
wrapper around every command, with state capture kept outside `step` so it runs in both modes. 
Deferred until another demo needs this, and it can probably be written better.
