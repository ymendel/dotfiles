# RuboCop configs

Rubocop baselines for easy reference and use.

- **`base.yml`** — core RuboCop only, no plugins. Safe in a gem, a CLI, a script
  directory, anything. This is the main content: omakase's style, the house
  preferences on top, and the Lint and Security departments.
- **`rails.yml`** — loads `rubocop-rails`, for omakase's Rails settings plus the
  Rails-only cops. Goes on top of `base.yml`.
- **`performance.yml`** — loads `rubocop-performance`, for omakase's one
  Performance cop.
- **`minitest.yml`** — the Minitest cops, needing `rubocop-minitest`.

Each plugin gets its own file, so a project can take what it wants.

## Using them

Copy the ones a project wants into its root with a `.rubocop-` prefix, unchanged,
and give the project its own `.rubocop.yml` listing them:

```yaml
inherit_from:
  - .rubocop-base.yml
  - .rubocop-rails.yml
  - .rubocop-performance.yml
  - .rubocop-minitest.yml

# Anything specific to this project goes here.
```

Later files win, then the project's own keys, so keep the order. `base.yml` always
goes first. Each of the others needs its plugin in the Gemfile: `rubocop-rails`,
`rubocop-performance`, `rubocop-minitest`. They are all independent, even
separating Minitest even though Rails defaults to Minitest. Explicit is better
than assumed.

The prefix is meaningful: RuboCop resolves relative `Exclude` paths against a
config file's own directory only when the file's name starts with `.rubocop`, and
against the current directory otherwise. If plainly named `rails.yml` or
`performance.yml`, their `data/**/*` and `test/**/*` excludes would work only when
rubocop runs from the project root.

If you want to track omakase in a Rails app (taking its future changes, at the cost
of `base.yml` masking most of them), add `rubocop-rails-omakase` to the Gemfile and
this to `.rubocop.yml`. `inherit_gem` goes underneath `inherit_from`, so the copied
files still win:

```yaml
inherit_gem:
  rubocop-rails-omakase: rubocop.yml
```

## Why base.yml doesn't just inherit omakase

`rubocop-rails-omakase` depends on `rubocop-rails`, which has runtime dependencies on
activesupport and rack. In a Rails app, whatever. In a gem or similar, that's a heavy
dependency for just some formatting opinions. Almost all of omakase's substance is
core RuboCop anyway, so `base.yml` just has the content, keeping the settings and
comments (except for some wrong ones that are corrected here). Only three of the
entries need a plugin, and two of those were inert.
