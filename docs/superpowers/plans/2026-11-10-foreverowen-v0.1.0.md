# ForeverOwen v0.1.0 Implementation Plan

> **Superseded in part:** the volume slider and Dialog-volume borrowing (Tasks 4–6) were removed after in-game testing. See PRD §4.3 (schema 2). This plan is kept as history.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship v0.1.0 of ForeverOwen: Owen Wilson says "Wow" whenever the player, or
anything the player controls, crits. It comes with a small faction-themed window
(Play, volume, on/off) and the `/owen` commands.

**Architecture:**
- **Pure modules** (`Config`, `Crit`, and the borrow core inside `Sound`) hold all the
  decisions and are covered by busted specs.
- **Thin glue** (`Sound` playback, `UI`, `Init`) binds them to the WoW API and is checked
  by a human in game.
- **The volume** is set by borrowing the Dialog channel. `ForeverOwenDB.restore` is the
  single source of truth for "a borrow is active".

**Tech Stack:** Lua 5.1, WoW Forever client (Interface 16001), busted 2.3.0, luacheck 1.2.0,
BigWigs packager.

**Spec:** `PRD.md` (repo root). Read it before any task.

## Global Constraints

- Every file starts with `local addonName, ns = ...` (or `local _, ns = ...`). Each
  module is `local X = {}; ns.X = X`.
- **Globals:**
  - The only globals created are `ForeverOwenDB`, `SLASH_FOREVEROWEN1` and
    `ForeverOwenFrame` (the window, for Esc).
  - Every WoW API used goes in `.luacheckrc` `read_globals`, in alphabetical order.
- **Pure modules** (`src/Config.lua`, `src/Crit.lua`, and the borrow core in
  `src/Sound.lua`) never touch a WoW global. Time, `bit.band` and the CVar get/set
  functions are passed in.
- **Formatting:** tabs, LF line endings, max line length 120.
- **Toc load order:** `src\Config.lua`, `src\Crit.lua`, `src\Sound.lua`, `src\UI.lua`,
  `src\Init.lua`. It is already in `ForeverOwen.toc`; don't add files.
- **Every task ends with both commands passing:** `luacheck .` and `busted`.
  - On Windows, run them through the `.bat` wrappers in `%USERPROFILE%\.luarocks\bin`,
    or with the VS Code "Lint and test" task.
- **Each task** adds a line under `## [Unreleased]` in `CHANGELOG.md` when it changes
  something a user can see.
- **Sound constants:**
  - `CLIP_PATH = "Interface\\AddOns\\ForeverOwen\\media\\OwenWilson.mp3"`
  - `CLIP_SECONDS = 0.84`
  - `RESTORE_PAD = 0.25`
  - `CHANNEL = "Dialog"`
- **Exact chat text** (prefix `|cffffd100ForeverOwen|r ` via `ns.Print`):
  - `on. Wow.`
  - `off.`
  - `commands:`, followed by one line per command
  - `<version> loaded. Type /owen.`
  - The PRD writes these as `ForeverOwen: on. Wow.` and so on. The coloured
    `ForeverOwen` prefix stands in for `ForeverOwen:`.
- **Never** tag, push or release unless the owner asks.

## Review Focus

1. **A crit lands while a borrow is still active** (0.84–1.09 s after the last clip
   started). It must not re-snapshot, and only the newest restore timer may restore.
   → Task 4 test `"a second Begin during a borrow keeps the original snapshot"`.
2. **A `/reload` or logout mid-clip.** `db.restore` survives, and the next login must put
   the player's real values back. → Task 4 test
   `"Restore on login puts back a leftover snapshot"`.
3. **Corrupt or old saved data:**
   - `volume = "loud"`, `volume = 7`, `enabled = nil`, or a non-table `ForeverOwenDB`.
   - `Load` must sanitise these, never error.
   - → Task 2 tests `"clamps and rounds volume"`, `"replaces non-number volume"`,
     `"accepts a non-table"`.
4. **Odd combat-log tuples:**
   - `nil` source flags, a MISSED event with `missType ~= "ABSORB"`, a sub-event not in
     the table.
   - All of these must return `false` without erroring.
   - → Task 3 tests.
5. **Slash input with mixed case and spaces** (`"  ON "`, `"Off"`) must work, and anything
   unknown prints the help. → Task 2 `ParseCommand` tests.

---

### Task 1: Phase 0 probe (throwaway, needs the owner in game)

This runs in parallel with Tasks 2–4. Its results may change the constants in Task 3
(`Crit.EVENTS` positions) and Task 4 (`CLIP_SECONDS`, mp3 vs ogg).

**Files:**
- Create: `scripts/probe/ForeverOwenProbe/ForeverOwenProbe.toc`
  - `## Interface: 16001`
  - `## Title: ForeverOwen Probe`
  - loads `Probe.lua`
- Create: `scripts/probe/ForeverOwenProbe/Probe.lua`
- Create: `scripts/probe/README.md`, with install steps and the results table to fill in
- Modify: `.luacheckrc`: add `"scripts/probe/"` to `exclude_files`. The probe is
  throwaway, and `.pkgmeta` already ignores `scripts`.

**Interfaces:** none. Nothing ships.

- [ ] **Step 1: Write `Probe.lua`.** It has three parts:
  - **Combat-log printer:** an event frame on `COMBAT_LOG_EVENT_UNFILTERED`.
    - For any sub-event in the PRD §4.1 table where
      `bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0`, print the
      sub-event, `sourceName` and `sourceFlags` (as hex).
    - Also print fields 12–21 of `CombatLogGetCurrentEventInfo()`, each labelled with its
      index.
  - **`/owenprobe vol <0-1>`:**
    - print the current `Sound_DialogVolume` and `Sound_EnableDialog`;
    - set `Sound_DialogVolume` to the argument and `Sound_EnableDialog` to `1`;
    - play the clip with
      `PlaySoundFile("Interface\\AddOns\\ForeverOwenProbe\\OwenWilson.mp3", "Dialog")`;
    - print `willPlay` and the handle;
    - after `C_Timer.After(1.09, ...)`, restore and print the values.
  - **`/owenprobe api`:** print `type()` of `C_AddOns`, `BackdropTemplate` (use
    `pcall(CreateFrame, "Frame", nil, UIParent, "BackdropTemplate")`), `UISpecialFrames`,
    `UICheckButtonTemplate` and `UIPanelButtonTemplate`, each created with the same
    `pcall` approach.
- [ ] **Step 2: Verify:** `luacheck .` and `busted` both exit 0. The probe is excluded
  from lint.
- [ ] **Step 3: Commit:** `git commit -m "Phase 0 probe addon (throwaway)"`.
- [ ] **Step 4: Owner runs it in game.**
  - Copy `scripts/probe/ForeverOwenProbe/` and `media/OwenWilson.mp3` into
    `_forever_\Interface\AddOns\ForeverOwenProbe\`.
  - Then try:
    - a melee crit, a spell crit, a heal crit and a DoT/HoT crit;
    - a pet crit and a **totem crit** (Searing Totem);
    - a crit into a shield (Power Word: Shield or a target dummy with an absorb, if one
      is available);
    - `/owenprobe vol 0.2`, then `/owenprobe vol 1`;
    - `/owenprobe api`.
- [ ] **Step 5: Record the results.**
  - Fill in the Phase 0 table in `PRD.md` §7.
  - If anything differs from the PRD, update `PRD.md` §4.1 / §6 first, then the
    constants in Tasks 3 and 4.
  - Commit: `"PRD: Phase 0 results"`.

---

### Task 2: Config (defaults, sanitising, commands)

**Files:**
- Create: `src/Config.lua`
- Test: `spec/Config_spec.lua`

**Interfaces:**
- Produces:
  - `ns.Config.DEFAULTS`
    - `{ schemaVersion = 1, enabled = true, volume = 1.0 }`
    - `point` and `restore` are left as absent keys.
  - `ns.Config.Load(saved: any) -> table`
    - If `saved` is a table, it is fixed in place and returned. Otherwise a new table is
      returned.
    - Missing keys come from DEFAULTS.
    - `enabled` is coerced: anything other than `false` becomes `true`.
    - `volume` goes through `ClampVolume`. Anything that isn't a number becomes `1.0`.
    - `schemaVersion` is set to `1`.
    - `point` and `restore` are kept when they are tables, otherwise set to `nil`.
  - `ns.Config.ClampVolume(v: number) -> number`: clamp to [0, 1], then round to the
    nearest 0.05.
  - `ns.Config.SetVolume(db, v) -> number`: stores `ClampVolume(v)` and returns it.
  - `ns.Config.SetEnabled(db, on: boolean)`
  - `ns.Config.ParseCommand(text: string|nil) -> "toggle"|"on"|"off"|"help"`
    - The text is trimmed and lower-cased first.
    - `""` or `nil` → `"toggle"`; `"on"` → `"on"`; `"off"` → `"off"`; anything else →
      `"help"`.
  - `ns.Config.COMMANDS`: an array of `{ cmd, desc }`, exactly:
    - `{ "/owen", "open this window" }`
    - `{ "/owen on", "turn it on" }`
    - `{ "/owen off", "turn it off" }`

- [ ] **Step 1: Write `spec/Config_spec.lua`.**
  - Load it with `local Config = LoadAddonFile("src/Config.lua").Config`.
  - Tests:
    - `"Load(nil) returns defaults"`: `same({ schemaVersion = 1, enabled = true, volume = 1.0 }, Config.Load(nil))`
    - `"accepts a non-table"`: `Config.Load("junk").volume == 1.0`
    - `"keeps valid saved values"`: `Load({ enabled = false, volume = 0.35, point = { "CENTER", "CENTER", 10, 20 } })`
      gives `enabled == false`, `volume == 0.35` and the same `point`.
    - `"clamps and rounds volume"`: `ClampVolume(7) == 1`, `ClampVolume(-1) == 0`,
      `ClampVolume(0.42) == 0.40`, `ClampVolume(0.43) == 0.45`.
      - Compare with `assert.is_true(math.abs(a - b) < 1e-9)`.
    - `"replaces non-number volume"`: `Load({ volume = "loud" }).volume == 1.0`
    - `"drops a non-table restore"`: `Load({ restore = "x" }).restore == nil`
    - `"keeps a table restore"`: a table restore survives `Load`.
    - `"SetVolume stores the clamped value"`: `SetVolume(db, 0.42)` returns `0.40`, and
      `db.volume == 0.40`.
    - `"ParseCommand"`:
      - `nil` → `toggle`; `""` → `toggle`; `"  ON "` → `on`; `"Off"` → `off`;
        `"volume 5"` → `help`; `"help"` → `help`.
    - `"COMMANDS lists the three commands in order"`: compared with `same`.
- [ ] **Step 2: Run** `busted spec/Config_spec.lua`. Expected: FAIL, because
  `src/Config.lua` doesn't exist yet.
- [ ] **Step 3: Implement `src/Config.lua`** to the Interfaces above. Round with
  `math.floor(v * 20 + 0.5) / 20`.
- [ ] **Step 4: Run** `luacheck .` and `busted`. Expected: all pass.
  - The toc smoke test `"lists only files that exist"` now runs instead of being pending.
    It **fails** until every toc file exists.
  - To stop that, change its `pending` guard so it lists only files that are missing and
    whose module is due in a later task. Simplest: make it `pending` while any
    `src/*.lua` listed in the toc is missing, and assert once all five exist.
  - Adjust `spec/toc_spec.lua` to do that.
- [ ] **Step 5: Commit:** `git commit -m "Config: defaults, sanitising, slash parsing"`

---

### Task 3: Crit detection and throttle

**Files:**
- Create: `src/Crit.lua`
- Test: `spec/Crit_spec.lua`

**Interfaces:**
- Produces:
  - `ns.Crit.EVENTS`: sub-event → `{ crit = <index>, miss = <index or nil> }`, with the
    values from PRD §4.1:
    - `SWING_DAMAGE = { crit = 18 }`
    - `RANGE_DAMAGE`, `SPELL_DAMAGE`, `SPELL_PERIODIC_DAMAGE`, `DAMAGE_SHIELD` = `{ crit = 21 }`
    - `SPELL_HEAL`, `SPELL_PERIODIC_HEAL` = `{ crit = 18 }`
    - `SWING_MISSED = { crit = 15, miss = 12 }`
    - `RANGE_MISSED`, `SPELL_MISSED`, `SPELL_PERIODIC_MISSED`, `DAMAGE_SHIELD_MISSED` =
      `{ crit = 18, miss = 15 }`
  - `ns.Crit.IsMyCrit(mineMask: number, band: function, ...) -> boolean`
    - `...` is the full `CombatLogGetCurrentEventInfo()` tuple.
    - Checks in this order:
      1. the sub-event (`select(2, ...)`) is in `EVENTS`;
      2. `band(sourceFlags or 0, mineMask) ~= 0`, where `sourceFlags` is `select(6, ...)`;
      3. `(select(e.crit, ...))` is truthy;
      4. if `e.miss` is set, `(select(e.miss, ...)) == "ABSORB"`.
    - Wrap each `select` in parentheses so only one value comes back.
  - `ns.Crit.ShouldPlay(now: number, lastStart: number|nil, window: number) -> boolean`
    - `true` if `lastStart == nil` or `now - lastStart >= window`.

- [ ] **Step 1: Write `spec/Crit_spec.lua`.**
  - Setup:
    - A helper `tuple(sub, flags, fields)` builds a 21-slot array:
      - slot 1 = `0`, slot 2 = `sub`, slot 6 = `flags`;
      - each `fields[i]` is placed at slot `i`.
    - Call it as `Crit.IsMyCrit(MINE, band, unpack(t, 1, 21))`.
    - `MINE = 0x1`.
    - `band` is a pure-Lua bitwise AND for small ints. Define it in the spec, because
      busted on Lua 5.1 has no `bit`.
  - Tests:
    - `"SWING_DAMAGE crit by me"` → `true` (`[18] = 1`)
    - `"SWING_DAMAGE non-crit"` → `false` (`[18] = nil`)
    - `"SPELL_DAMAGE crit at 21"` → `true`
    - `"SPELL_HEAL crit at 18"` → `true`
    - `"SPELL_PERIODIC_HEAL crit"` → `true`
    - `"DAMAGE_SHIELD crit"` → `true`
    - `"crit by someone else"` → `false` (flags `0x400`, MINE bit clear)
    - `"crit by my totem/guardian"` → `true` (flags `0x2111`, MINE bit set)
    - `"nil flags"` → `false`, with no error
    - `"SPELL_MISSED ABSORB crit"` → `true` (`[15] = "ABSORB"`, `[18] = true`)
    - `"SPELL_MISSED DODGE"` → `false` (`[15] = "DODGE"`, `[18] = true`)
    - `"SWING_MISSED ABSORB crit"` → `true` (`[12] = "ABSORB"`, `[15] = true`)
    - `"unknown sub-event"` (`"SPELL_CAST_SUCCESS"`) → `false`
    - ShouldPlay: `(10, nil, 0.84) == true`; `(10.5, 10, 0.84) == false`;
      `(10.84, 10, 0.84) == true`.
- [ ] **Step 2: Run** `busted spec/Crit_spec.lua`. Expected: FAIL, because `src/Crit.lua`
  doesn't exist yet.
- [ ] **Step 3: Implement `src/Crit.lua`** to the Interfaces above. Use the indices from
  Phase 0 if Task 1 has already corrected them.
- [ ] **Step 4: Run** `luacheck .` and `busted`. Expected: pass.
- [ ] **Step 5: Commit:** `git commit -m "Crit: owned-unit crit detection and throttle"`

---

### Task 4: Sound borrow core (pure)

**Files:**
- Create: `src/Sound.lua`. This task writes the pure part only. Task 5 adds the glue in
  the same file.
- Test: `spec/Sound_spec.lua`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `ns.Sound.CLIP_PATH`, `CLIP_SECONDS`, `RESTORE_PAD` and `CHANNEL`, with the values
    from Global Constraints.
  - `ns.Sound.NewBorrower(api) -> borrower`
    - `api = { getCVar = fn(name) -> string|nil, setCVar = fn(name, value), after = fn(seconds, cb) }`
  - `borrower:Begin(db, volume: number)`
    - If `db.restore == nil`, set
      `db.restore = { dialogVolume = getCVar("Sound_DialogVolume"), enableDialog = getCVar("Sound_EnableDialog") }`.
    - Then `setCVar("Sound_DialogVolume", tostring(volume))` and
      `setCVar("Sound_EnableDialog", "1")`.
    - Then increment the generation and call
      `after(CLIP_SECONDS + RESTORE_PAD, cb)`, where `cb` calls `Restore(db)` only if its
      generation is still the newest.
  - `borrower:Restore(db)`
    - If `db.restore` is set, write `dialogVolume` and `enableDialog` back. Skip any
      field that is `nil`. Then set `db.restore = nil`.
    - If `db.restore` is not set, do nothing.

- [ ] **Step 1: Write `spec/Sound_spec.lua`.**
  - Setup:
    - Use fakes. `cvars` is a table `{ Sound_DialogVolume = "0.7", Sound_EnableDialog = "0" }`.
    - The `after` fake pushes `{ seconds, cb }` onto `timers`.
    - The test fires a timer by calling `timers[i][2]()`.
  - Tests:
    - `"Begin snapshots, sets volume and enables dialog"`
      - `db.restore` equals `{ dialogVolume = "0.7", enableDialog = "0" }`.
      - `cvars.Sound_DialogVolume == "0.4"` after `Begin(db, 0.4)`.
      - `cvars.Sound_EnableDialog == "1"`.
      - `timers[1][1]` is close to `1.09`.
    - `"timer restores the originals and clears db.restore"`
    - `"a second Begin during a borrow keeps the original snapshot"`
      1. `Begin(db, 0.4)`, then `Begin(db, 0.9)`.
      2. `db.restore.dialogVolume == "0.7"`.
      3. Fire `timers[1]`: the cvars are unchanged (still `"0.9"`).
      4. Fire `timers[2]`: `Sound_DialogVolume == "0.7"` and `db.restore == nil`.
    - `"Restore on login puts back a leftover snapshot"`
      - `db = { restore = { dialogVolume = "0.5", enableDialog = "1" } }`.
      - Call `Restore(db)`.
      - The cvars are set to those values, and `db.restore == nil`.
    - `"Restore with nothing borrowed does nothing"`
      - `setCVar` is never called. Use a spy, or count the calls.
- [ ] **Step 2: Run** `busted spec/Sound_spec.lua`. Expected: FAIL.
- [ ] **Step 3: Implement the pure part of `src/Sound.lua`.**
  - The borrower keeps `gen` as a local upvalue.
  - It touches no WoW global at load time, so specs can load the file.
- [ ] **Step 4: Run** `luacheck .` and `busted`. Expected: pass.
- [ ] **Step 5: Commit:** `git commit -m "Sound: Dialog-channel borrow and restore core"`

---

### Task 5: Playback glue, events and slash command (needs the owner in game)

**Files:**
- Modify: `src/Sound.lua`. Add glue functions that look WoW globals up **when called**,
  not when the file loads.
- Create: `src/Init.lua`
- Create: `src/UI.lua`, as a stub for now:
  - `UI.Toggle()` prints `window coming soon`;
  - `UI.Refresh()` does nothing.
- Modify: `.luacheckrc` `read_globals`, if any API is missing.
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: Config (Task 2), Crit (Task 3), Sound core (Task 4).
- Produces:
  - `ns.Sound.Play(db)`
    - Lazily create one borrower bound to `GetCVar`, `SetCVar` and `C_Timer.After`.
    - Call `borrower:Begin(db, db.volume)`.
    - If a previous handle exists, call `StopSound(handle)`.
    - Then `local _, handle = PlaySoundFile(CLIP_PATH, CHANNEL)`, store the handle, and
      set `ns.Sound.lastStart = GetTime()`.
  - `ns.Sound.OnCrit(db)`
    - If `db.enabled` and `Crit.ShouldPlay(GetTime(), ns.Sound.lastStart, CLIP_SECONDS)`,
      call `Play(db)`.
  - `ns.Sound.RestoreLeftover(db)`
    - Calls `borrower:Restore(db)`.
  - `ns.Print(text)`
    - `print("|cffffd100ForeverOwen|r " .. text)`.
  - `ns.version`
    - `C_AddOns.GetAddOnMetadata(addonName, "Version")`.
    - If that is `nil` or starts with `@`, use `"dev"`.
  - `ns.db`
    - Set on `ADDON_LOADED` for this addon:
      `ForeverOwenDB = Config.Load(ForeverOwenDB); ns.db = ForeverOwenDB`.
  - Events:
    - **`PLAYER_LOGIN`:** call `Sound.RestoreLeftover(ns.db)`, then print the loaded
      line.
    - **`COMBAT_LOG_EVENT_UNFILTERED`:** if
      `Crit.IsMyCrit(COMBATLOG_OBJECT_AFFILIATION_MINE, bit.band, CombatLogGetCurrentEventInfo())`,
      call `Sound.OnCrit(ns.db)`.
  - Slash command: dispatch on `Config.ParseCommand(text)`:
    - **toggle:** `UI.Toggle()`.
    - **on:** `Config.SetEnabled(db, true)`, `ns.Print("on. Wow.")`, `UI.Refresh()`.
    - **off:** `Config.SetEnabled(db, false)`, `ns.Print("off.")`, `UI.Refresh()`.
    - **help:** print `commands:`, then each `COMMANDS` entry as `cmd .. " - " .. desc`.

- [ ] **Step 1: Implement the Sound glue and `src/Init.lua`**, plus the `src/UI.lua`
  stub, to the Interfaces above.
- [ ] **Step 2: Run** `luacheck .` and `busted`. Expected: pass. All five toc files now
  exist, so the toc smoke test asserts for real.
- [ ] **Step 3: Run** `scripts/build.sh` in Git Bash. Expected: a zip in `.release/`, and
  the addon copied to `_forever_\Interface\AddOns\ForeverOwen`.
- [ ] **Step 4: Owner checks in game, and writes the results in the PR or commit
  message:**
  - The loaded line prints with a version.
  - A melee crit plays "Wow". A non-crit doesn't.
  - A totem crit plays it.
  - AoE crits produce one "Wow", not a pile of them.
  - `/owen off` prints `off.` and crits are silent. `/owen on` brings it back.
  - `/owen nonsense` prints the help.
  - After a clip, Interface → Sound → Dialog volume is back to what it was.
  - `/reload` straight after a crit leaves the Dialog volume unchanged after the next
    login.
- [ ] **Step 5: Commit:** `git commit -m "Init and playback glue: crits play Wow, /owen on|off"`

---

### Task 6: The window (needs the owner in game)

**Files:**
- Modify: `src/UI.lua`. Replace the stub.
- Modify: `.luacheckrc`:
  - add `ForeverOwenFrame` to `globals`;
  - add `UISpecialFrames` and any other templates or APIs used to `read_globals`.
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: `ns.db`, `ns.Config.SetVolume`, `ns.Config.SetEnabled`, `ns.Config.COMMANDS`,
  `ns.Sound.Play`.
- Produces:
  - `ns.UI.Toggle()`: build the window on first use, then show or hide it.
  - `ns.UI.Refresh()`: if the window has been built, sync the checkbox and the slider
    from `ns.db`.

The layout and contents are in PRD §4.6. These are the decisions it leaves open, settled:
- **Frame:**
  `CreateFrame("Frame", "ForeverOwenFrame", UIParent, "BackdropTemplate")`, about
  260 × 210, strata `DIALOG`.
  - Insert `"ForeverOwenFrame"` into `UISpecialFrames` so Esc closes it.
  - Drag by the title bar, and clamp it to the screen.
  - On drag stop, save `{ point, relativePoint, x, y }` from `GetPoint(1)` into
    `ns.db.point`. Re-apply it when the window is built.
- **Palette:** a `PALETTE` table keyed `Alliance` / `Horde`, each with
  `{ title, border, button, accent }` 0..1 RGB values.
  - Alliance title is `{0.114, 0.302, 0.690}`. Horde title is `{0.490, 0.110, 0.110}`.
  - The faction is `UnitFactionGroup("player")`. If it is neither faction, use
    `"Alliance"`.
- **Play:** `UIPanelButtonTemplate`, labelled `Play`. It calls `ns.Sound.Play(ns.db)`,
  which ignores `enabled` and the throttle.
- **Enabled:** `UICheckButtonTemplate`, labelled `Enabled`. It calls `Config.SetEnabled`.
- **Volume:**
  - a plain `CreateFrame("Slider")` with its own thumb texture tinted with
    `PALETTE.accent`. Don't use `OptionsSliderTemplate`; it may not exist on this client.
  - `SetMinMaxValues(0, 100)`, `SetValueStep(5)`, `SetObeyStepOnDrag(true)`.
  - The label reads `math.floor(v + 0.5) .. "%"`.
  - `OnValueChanged` calls `Config.SetVolume(ns.db, v / 100)`. It does **not** play the
    clip.
- **Commands:** one `FontString` per `Config.COMMANDS` entry, in
  `GameFontHighlightSmall`. The command is left-aligned and the description sits in a
  second column.

- [ ] **Step 1: Implement `src/UI.lua`** as described above.
- [ ] **Step 2: Run** `luacheck .` and `busted`. Expected: pass.
- [ ] **Step 3: Run** `scripts/build.sh`.
- [ ] **Step 4: Owner checks in game:**
  - `/owen` opens the window. `/owen` again, the [x] button and Esc each close it.
  - Alliance character: blue theme. Horde character: red theme.
  - Play works at 20 % and at 100 %, and is clearly quieter at 20 %.
  - Play also works while the addon is disabled.
  - Dragging the slider makes no sound.
  - The slider snaps to multiples of 5.
  - The window position, volume and enabled state survive `/reload`, and are shared
    with an alt (account-wide).
  - Typing `/owen off` while the window is open unticks the box.
- [ ] **Step 5: Commit:** `git commit -m "UI: faction-themed window with Play, volume and toggle"`

---

### Task 7: Release prep for v0.1.0

**Files:**
- Modify: `CHANGELOG.md`: move the Unreleased lines under `## [0.1.0] - <date>`.
- Modify: `README.md`: change Status to playable, and add the commands and a screenshot
  if the owner provides one.
- Modify: `PRD.md`: mark v0.1.0 done in §7, and fill in anything learned in game.

- [ ] **Step 1: Decide on Dependabot's packager-bump PR (2.6.1 → 2.7.0).** If the owner
  wants it, bump `scripts/build.sh` `PACKAGER_VERSION` in the same change, so both use
  the same version.
- [ ] **Step 2: Update the docs.** Run `luacheck .` and `busted`. Expected: pass.
- [ ] **Step 3: Commit:** `git commit -m "Release 0.1.0"`.
- [ ] **Step 4: Only when the owner says so:**
  - `git tag -a v0.1.0 -m "v0.1.0"`
  - `git push origin main --follow-tags`
  - Check that the Release workflow attaches `ForeverOwen-v0.1.0.zip`.
