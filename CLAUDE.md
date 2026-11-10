# ForeverOwen

World of Warcraft: Forever addon (Lua 5.1, Interface 16001) that plays Owen
Wilson's "Wow" when the player or their pet crits (melee, ranged, spell or
heal). It has a small window with a Play button, a volume slider and an on/off
toggle, and the slash commands `/owen`, `/owen on` and `/owen off`.

## Spec

`PRD.md` is the spec. Read it before changing behaviour. A change to behaviour
is not done until `PRD.md` agrees with the code, and a change to the PRD's
requirements needs the human's approval.

## Commands

Run from the repo root. On Windows, `.sh` scripts need Git Bash.

| Task | Command |
|------|---------|
| Install pinned dev tools | `luarocks install --local --only-deps foreverowen-dev-1.rockspec` |
| Lint | `luacheck .` |
| Unit tests | `busted` |
| Build, zip and install into the game | `scripts/build.sh` |
| Build and zip only (no game install) | `scripts/build.sh --no-install` |

Lint and tests must pass before you call work done; CI installs from the same
rockspec and runs both on every push. The build output goes to `.release/`
(git-ignored). `scripts/build.sh` only works in a normal checkout: inside a git
worktree the packager stops with "No Git, SVN, or Hg checkout found", so build
from `main` after merging.

## Layout

| Path | Purpose |
|------|---------|
| `ForeverOwen.toc` | Load order. Every new `src/` file must be listed here |
| `src/` | Addon code: `Config.lua`, `Crit.lua`, `Sound.lua`, `UI.lua`, `Init.lua`, loaded in that order |
| `media/OwenWilson.mp3` | The clip (about 0.8 s, 44.1 kHz stereo, 128 kbps) |
| `spec/` | busted tests, one `<Module>_spec.lua` per module |
| `scripts/` | Developer scripts (not shipped) |
| `foreverowen-dev-1.rockspec` | Exact luacheck and busted versions (not shipped) |
| `.pkgmeta` | Files left out of the package |

## Code rules

- **Every file starts with `local addonName, ns = ...`** (or `local _, ns = ...`).
  Share code through `ns`, never through new globals. The only globals are
  `ForeverOwenDB` (SavedVariables, account-wide) and the slash command.
- **Keep pure logic separate from game code.** Deciding whether a combat log
  event is a crit by the player or their pet, settings defaults and volume maths
  go in modules that call no WoW API and get busted tests. Code that touches
  frames, events, CVars or sounds stays in thin glue files (like `src/Init.lua`).
- **Test pure modules through `LoadAddonFile`** (from `spec/helper.lua`), which
  loads a file the way the game does: `LoadAddonFile("src/Crit.lua").Crit`.
- **Declare every WoW API you use** in `read_globals` in `.luacheckrc`, and every
  global you create in `globals`. That way lint catches typos in API names.
- **Volume** works by setting the `Sound_DialogVolume` CVar, playing the clip on
  the `"Dialog"` channel, and restoring the player's own value afterwards.
- Tabs for Lua indentation; see `.editorconfig`.

## Dependencies

- No runtime libraries (no Ace3, no LibStub). Do not add one without asking.
- Dev tools are pinned in `foreverowen-dev-1.rockspec` and bumped by hand;
  Dependabot only updates the GitHub Actions.
- Newly created files are left out of builds until they are `git add`ed.

## Things only a human can check

Anything that needs the game client: how the window looks, the faction colours,
whether a crit plays the sound, volume and the CVar restore, slash commands.
When a task depends on one of these, finish the parts you can test, then list
exactly what the user should try in game and what they should expect to see.

## Changes and releases

- Add a line under `## [Unreleased]` in `CHANGELOG.md` for each user-facing change.
- Releases are made by pushing a `v*` tag (see README). Do not tag or push
  unless asked.
