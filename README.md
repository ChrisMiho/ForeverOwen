# ForeverOwen

A World of Warcraft: Forever addon that plays Owen Wilson's "Wow" every time
your target takes a critical hit (melee, ranged, wand, spell or your pet's) or you receive a critical heal.

Status: playable on WoW Forever (client 1.60.1). See [PRD.md](PRD.md) for the full
design.

## Commands

| Command | What it does |
|---------|--------------|
| `/owen` | Open the ForeverOwen window (Play button, on/off toggle, volume note) |
| `/owen on` | Turn the crit sound on |
| `/owen off` | Turn the crit sound off |

The window is blue for Alliance characters and red for Horde. Settings are
saved per account.

## Install (players)

1. Download the latest `ForeverOwen-<version>.zip` from the
   [Releases](../../releases) page.
2. Unzip it into `World of Warcraft\_forever_\Interface\AddOns\`, so you end up
   with `...\AddOns\ForeverOwen\ForeverOwen.toc`.
3. Restart the game or type `/reload`.

Prefer the Releases zip over GitHub's green "Code > Download ZIP" button: that
copy has the wrong folder name and carries the development files.

## Development

### Tools

- Git and the GitHub CLI
- VS Code with the extensions in `.vscode/extensions.json`
- LuaJIT and LuaRocks (Lua 5.1, same as the game)
- Git Bash (comes with Git for Windows) for the scripts in `scripts/`

### Dev dependencies

luacheck and busted are pinned to exact versions in
`foreverowen-dev-1.rockspec`. Install them with:

```bash
luarocks install --local --only-deps foreverowen-dev-1.rockspec
```

(`--local` installs into your user tree. `luarocks --local config deploy_bin_dir`
prints its `bin` folder; make sure that folder is on your `PATH`.) In VS Code this is the "Install dev
dependencies" task. CI installs from the same rockspec. To move to newer
versions, edit the pins in the rockspec, run the checks below, and commit.

### Build

In VS Code press `Ctrl+Shift+B` (task "Build and install"), or from Git Bash:

```bash
scripts/build.sh
```

Each build runs the same packager as a release, then:

1. writes `.release/ForeverOwen-<version>.zip`, which holds one `ForeverOwen`
   folder that teammates unzip into `Interface\AddOns`, and
2. replaces `Interface\AddOns\ForeverOwen` in your game with the build.
   Type `/reload` in game to load it.

`scripts/build.sh --no-install` (task "Build zip only") skips step 2. If your
game is not in the default folder, set `WOW_ADDONS_DIR` to your `AddOns` path.

The version is the git tag on a tagged commit, or the short commit hash
otherwise. New files must be `git add`ed before they appear in a build; the
script warns about any that are not.

### Everyday checks

```bash
luacheck .
busted
```

In VS Code these are the "Lint and test" task. CI runs the same two commands on
every push and pull request.

### Layout

| Path | What it is |
|------|------------|
| `ForeverOwen.toc` | Addon manifest: load order, version, saved variables |
| `src/` | Addon code. Pure logic files have no WoW API calls and are unit tested |
| `media/` | The `OwenWilson.mp3` clip played on a crit |
| `spec/` | busted unit tests |
| `scripts/` | Developer scripts (not shipped) |
| `foreverowen-dev-1.rockspec` | Pinned dev tools (luacheck, busted); not shipped |
| `.pkgmeta` | Packager config: files to leave out of the zip |

### Releasing

1. Move the `Unreleased` notes in `CHANGELOG.md` under a new version heading.
2. Commit, then tag and push:

   ```bash
   git tag -a v0.1.0 -m "v0.1.0"
   git push origin main --follow-tags
   ```

3. The Release workflow builds the zip and attaches it to a GitHub release.

## Credits

The "Wow" sound is a short clip of Owen Wilson's well-known exclamation, used
for fun in a free, non-commercial fan addon. All rights to the clip belong to
their owners. No libraries are used.

## Licence

MIT (the addon code). See [LICENSE](LICENSE).
