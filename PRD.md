# ForeverOwen: Product Requirements

> The guide for anyone (human or agent) working on this addon. Read it before
> changing code. If the code and this file disagree, raise it; don't silently
> "fix" either one. Update this file in the same change when behaviour changes.

## 1. What it is

A World of Warcraft addon for **WoW Forever** (`_forever_` client, `## Interface: 16001`,
Lua 5.1, modern retail-style API). Every time the player critically hits, Owen Wilson
says "Wow".

It brings back an addon the owner (ChrisMiho) and their guild used in Classic in 2019–2020.
It was simple and funny, and the whole guild enjoyed it. That is the bar: **simple, funny,
reliable, and never annoying in a way that makes people turn it off.**

The clip is `media/OwenWilson.mp3`, about 0.84 s long (exact length in §6, Constants).

## 2. Goals, non-goals, anti-goals

**Goals**
- Play the clip when **the player, or anything the player controls** (pet, guardians,
  totems, temporary summons), lands a critical:
  - melee and ranged auto-attacks
  - physical abilities
  - damaging spells, including damage over time
  - heals, including heal over time
  - thorns and reflect-style damage (`DAMAGE_SHIELD`)
  - crits that a shield fully absorbs
- Offer a small window with:
  - a **Play** button to preview the clip
  - a **volume slider**
  - an **on/off toggle**
  - the slash commands listed underneath
- Slash commands: `/owen` (open the window), `/owen on`, `/owen off`. Volume is set only in
  the window.
- Theme by faction: a **blue palette for Alliance**, a **red palette for Horde**.
- Save settings **account-wide** in `ForeverOwenDB`.

**Non-goals (for v1)**
- Crits by other players (party, raid, guild).
- Choosing which kinds of crit trigger it (melee only, heals only, and so on). It is all
  or nothing.
- Other sound clips, a minimap button, chat announcements, guild sync.
- CurseForge/Wago publishing. Releases go to GitHub only.
- Other game clients (Classic Era, retail). Only Interface 16001 is supported.

**Anti-goals: things that make the addon a failure even if it "works"**
- **It permanently changes the player's sound settings.** The volume trick (§4.3) borrows a
  game setting. It must always be put back, even after `/reload`, a logout or a disconnect.
  - A client **crash** is best effort only: WoW doesn't write SavedVariables on a crash, and
    probably doesn't write the changed sound settings either. This is a known, accepted gap.
- **It machine-guns.** AoE crits that land in the same instant must not stack ten
  overlapping "Wow"s.
- **It costs frame time in combat.** The combat-log handler runs on every combat event in
  range, so it must return early and cheaply.
- **It throws Lua errors.** One error popup in a raid and the guild turns the addon off.

## 3. Users

- **The player:** installs the addon, opens it with `/owen`, sets the volume once and
  forgets about it.
- **The guild:** installs the same addon. There is no networking; everyone hears only
  their own crits.

## 4. Behaviour

### 4.1 Crit detection

- Listen to `COMBAT_LOG_EVENT_UNFILTERED` and read the event with
  `CombatLogGetCurrentEventInfo()`.
- An event counts if all of these hold:
  1. **The source is the player or something the player owns.** The owner decided: **every**
     unit the player controls counts — the controlled pet, guardians, **totems** (important
     for shamans) and temporary summons.
     - Check `sourceFlags` with `bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0`.
       That flag is set on the player and on everything the player owns, and it doesn't need
       GUID tracking or `SPELL_SUMMON` bookkeeping.
     - Fallback if Phase 0 shows the flag is missing for some summon type: also accept
       `sourceGUID == UnitGUID("player")` or `UnitGUID("pet")`, and track GUIDs from the
       player's `SPELL_SUMMON` events (cleared on `PLAYER_ENTERING_WORLD`).
  2. The sub-event is in the table below.
  3. Its `critical` field is truthy.
  4. For `*_MISSED` sub-events only: `missType == "ABSORB"`. The owner decided that a crit
     **fully absorbed** by a shield still counts. Other miss types (dodge, parry, resist and
     so on) never carry a crit.

| Sub-event | `critical` position (1-based, in the full returned tuple) | Notes |
|---|---|---|
| `SWING_DAMAGE` | 18 | |
| `RANGE_DAMAGE`, `SPELL_DAMAGE`, `SPELL_PERIODIC_DAMAGE` | 21 | |
| `DAMAGE_SHIELD` (thorns, reflect-style damage) | 21 | Owner decided this counts |
| `SPELL_HEAL`, `SPELL_PERIODIC_HEAL` | 18 | |
| `SWING_MISSED` | 15 | `missType` at 12 must be `"ABSORB"` |
| `RANGE_MISSED`, `SPELL_MISSED`, `SPELL_PERIODIC_MISSED`, `DAMAGE_SHIELD_MISSED` | 18 | `missType` at 15 must be `"ABSORB"` |

These positions follow the retail combat-log layout: 11 base fields, then a 3-field spell
prefix for SPELL/RANGE/DAMAGE_SHIELD events, then the suffix. The MISSED suffix is
`missType, isOffHand, amountMissed, critical`. **They must be confirmed in game first**
(§7, Phase 0). Put them in one table in `Crit.lua` (critical position plus an optional
missType position) so a fix touches one place.

- Order the checks so the cheapest rejection runs first:
  1. the sub-event lookup
  2. the source flags (one `bit.band`)
  3. the critical flag
  4. the missType, for MISSED events only

### 4.2 Throttle

- After a clip starts, ignore further crits until the clip has finished (`CLIP_SECONDS`).
- A crit inside that window is dropped, not queued.
- The **Play** button ignores the throttle. It restarts the clip: stop the current handle,
  then play a new one.

### 4.3 Volume (the Dialog channel trick)

WoW can't set the volume of a single sound, so the addon plays the clip on the
**Dialog** channel and borrows that channel's volume while the clip plays. The owner chose
this approach.

When the clip plays:
1. If no borrow is active:
   - remember the current `Sound_DialogVolume` and `Sound_EnableDialog` values;
   - **also write them to `ForeverOwenDB.restore`**, so a `/reload` or logout mid-clip can
     put them back on the next login.
2. Set `Sound_DialogVolume` to the user's volume (0–1). Set `Sound_EnableDialog` to `1`.
3. `PlaySoundFile("Interface\\AddOns\\ForeverOwen\\media\\OwenWilson.mp3", "Dialog")`.
4. Schedule a restore with `C_Timer.After(CLIP_SECONDS + RESTORE_PAD, ...)`.
   - **Any** play can start while a borrow is still active: the Play button, or a crit that
     lands after the throttle window (`CLIP_SECONDS`) but before the restore fires
     (`CLIP_SECONDS + RESTORE_PAD`). Such a play skips step 1 (no new snapshot) and bumps a
     generation counter, so only the newest timer restores and stale timers do nothing.
   - Getting this wrong either cuts the second clip short or snapshots the borrowed values
     as the "originals", which breaks the first anti-goal.
5. The restore writes the remembered values back and clears `ForeverOwenDB.restore`.

- On `PLAYER_LOGIN`, if `ForeverOwenDB.restore` exists, restore those values first, then
  clear it.
- Side effect, accepted by the owner: NPC voice lines that play during the ~1 s window are
  played at the addon's volume.
- The Master volume and Master mute still apply. If the player has muted the game, there is
  no Wow. That is correct.
- Keep the borrow-and-restore logic **pure and testable**. The getter and setter for the
  game settings are passed in, so busted tests can use fakes (see §5).

### 4.4 Enable / disable

- `enabled = false` stops crits from playing the clip.
- The Play button still works while disabled, so people can preview the clip.
- Slash commands and the toggle in the window change the same setting. If the window is
  open, it updates straight away.

### 4.5 Slash commands

Register `SLASH_FOREVEROWEN1 = "/owen"`. Matching on the argument is case-insensitive and
ignores spaces at either end.

| Input | Effect | Chat output (exact) |
|---|---|---|
| `/owen` | Toggle the window (open it if closed, close it if open) | none |
| `/owen on` | `enabled = true` | `ForeverOwen: on. Wow.` |
| `/owen off` | `enabled = false` | `ForeverOwen: off.` |
| `/owen help` or anything else | Print the help | `ForeverOwen commands:` then one line per command, the same text as the window's command list |

- Chat lines use the addon-name prefix `|cffffd100ForeverOwen|r`, as in DeathRollForever's
  `ns.Print`.
- On login, print `ForeverOwen <version> loaded. Type /owen.`
  - `<version>` is the toc's `## Version` (`@project-version@` is replaced when packaged).
  - Show `dev` while the placeholder is still there.

### 4.6 The window

A small box, about 260 × 210 px. Final layout is the builder's call; the contents are not.

```
┌─ ForeverOwen ──────────────────── [x] ┐
│  [ ▶ Play ]            [✓] Enabled     │
│                                        │
│  Volume            ───────●─── 80%     │
│                                        │
│  /owen       open this window          │
│  /owen on    turn it on                │
│  /owen off   turn it off               │
└────────────────────────────────────────┘
```

- **Play:** plays the clip at the current slider volume (§4.2, §4.3).
- **Enabled:** a checkbox bound to `enabled`.
- **Volume:**
  - a slider from 0 to 100 % in steps of 5, with a % label;
  - it saves on every change;
  - it does **not** auto-play while dragging, which would be too noisy.
- **Commands:** a static list of the commands, in the small highlight font.
- **The frame itself:**
  - built lazily on the first `/owen`;
  - `BackdropTemplate`;
  - movable by dragging the title bar, clamped to the screen;
  - closes with the [x] and with Esc (needs a global frame name in `UISpecialFrames`);
  - its position is saved in `ForeverOwenDB.point`.
- **Faction palette:**
  - read `UnitFactionGroup("player")`; Alliance is blue, Horde is red, anything else falls
    back to Alliance;
  - start from DeathRollForever's tints: Alliance title `{0.114, 0.302, 0.690}`, Horde
    title `{0.490, 0.110, 0.110}`;
  - tint the title bar, border, Play button and slider thumb or fill;
  - body text stays the standard game font colours, so it stays readable.

## 5. Architecture

Lua 5.1. There are no runtime libraries. The namespace pattern matches DeathRollForever:
every file starts `local addonName, ns = ...`, and each module is `local X = {}; ns.X = X`.
There are **no new globals** except `ForeverOwenDB`, `SLASH_FOREVEROWEN1` and the frame
name used for Esc.

The modules load in this order:

| File | Kind | Owns |
|---|---|---|
| `src/Config.lua` | pure | the `DEFAULTS` table, `Config.Load(saved)` (fills in missing keys, clamps volume, migrates by `schemaVersion`), `Config.SetVolume`, `Config.SetEnabled` |
| `src/Crit.lua` | pure | the sub-event → crit-position table, `Crit.IsMyCrit(mineMask, band, ...)` (the CLEU tuple; `band` is `bit.band`, passed in so specs can supply one), `Crit.ShouldPlay(now, lastStart)` |
| `src/Sound.lua` | pure core + thin glue | the borrow/restore logic with injected `getCVar`/`setCVar`/`after`/`db`; glue binds the real `GetCVar`, `SetCVar`, `C_Timer.After`, `PlaySoundFile` and `StopSound` |
| `src/UI.lua` | glue | the window and its palette. Public: `UI.Toggle()`, `UI.Refresh()` |
| `src/Init.lua` | glue | events (`ADDON_LOADED`, `PLAYER_LOGIN`, `COMBAT_LOG_EVENT_UNFILTERED`), the slash command, `ns.Print`, the version |

**Rule:** pure modules never touch the WoW API. Time (`now`) and the game API are passed
in as parameters. Glue files are checked by hand in game. Pure modules are covered by
busted specs, through `LoadAddonFile` in `spec/helper.lua`.

## 6. Data

Defaults for `ForeverOwenDB`:
```lua
DEFAULTS = {
	schemaVersion = 1,
	enabled = true,
	volume = 1.0,      -- 0..1, the value Sound_DialogVolume is set to during the clip
	point = nil,       -- { point, relativePoint, x, y } for the window
	restore = nil,     -- { dialogVolume = "x", enableDialog = "y" } while a borrow is active
}
```

Constants (in `Sound.lua`):
- `CLIP_PATH = "Interface\\AddOns\\ForeverOwen\\media\\OwenWilson.mp3"`
- `CLIP_SECONDS = 0.84` (32 MP3 frames at 44.1 kHz = 0.836 s; gapless length 0.805 s). Confirm the felt length in game.
- `RESTORE_PAD = 0.25`
- `CHANNEL = "Dialog"`

## 7. Roadmap

**Phase 0: in-game checks.** Do these before trusting §4.1 and §4.3. Record the results in
a table in this file.
1. The addon loads with `## Interface: 16001` and is not shown as out of date.
   - DeathRollForever already confirmed on this client that `C_AddOns.GetAddOnMetadata`,
     `BackdropTemplate`, `C_Timer` and `UnitFactionGroup` exist. The others below have not
     been checked yet.
2. `PlaySoundFile(CLIP_PATH, "Dialog")` plays the mp3.
   - If mp3 doesn't play, convert the clip to `.ogg` and update `CLIP_PATH`.
3. Setting `Sound_DialogVolume` **before** `PlaySoundFile` changes how loud the clip is.
   Restoring it ~1 s later doesn't cut off the end of the clip.
4. The `critical` positions in §4.1 are correct. Test each kind of crit by printing the
   tuple.
5. `COMBATLOG_OBJECT_AFFILIATION_MINE` is set in `sourceFlags` for the player, the pet, a
   guardian and a shaman totem. Test a totem crit (for example Searing Totem) specifically.
   If it isn't set, switch to the GUID fallback in §4.1.
6. A fully absorbed crit arrives as `*_MISSED` with `missType == "ABSORB"` and a `critical`
   field in the position the table gives. `DAMAGE_SHIELD` (Thorns) can crit at all on this
   client. If it never does, keep it anyway: it costs nothing.

**v0.1.0: MVP.** Everything in §4, specs for the pure modules, and a tagged GitHub release.

**Later ideas (not committed):**
- toggles for each crit kind
- a minimum-crit-size filter
- extra clips
- per-character override

## 8. Tooling and dependencies

- **Runtime:** no libraries. `.pkgmeta` has no externals.
- **Dev dependencies:**
  - luacheck and busted are pinned in the dev rockspec at the repo root;
  - install them with `luarocks install --only-deps <rockspec>`;
  - CI uses the same rockspec.
- **CI** (`.github/workflows/ci.yml`): `luacheck .` and `busted` on every push to `main`
  and on every PR.
- **Release** (`.github/workflows/release.yml`):
  - push an annotated `vX.Y.Z` tag;
  - the BigWigs packager stamps the version, zips the addon and attaches it to a GitHub
    release.
- **Local build:** `scripts/build.sh` builds the zip and installs it into
  `_forever_/Interface/AddOns` (override with `WOW_ADDONS_DIR`). `--no-install` only builds
  the zip.
- **Lint rule:** every WoW API used must be listed in `.luacheckrc` `read_globals`, so a
  typo fails lint.
- Dependabot keeps the GitHub Actions versions current. Bump the rockspec pins and the
  packager pin by hand, and keep `build.sh` and `release.yml` on the same packager version.

## 9. Working agreements for agents

- Keep the scope to this PRD. Ask the owner before adding anything from Non-goals.
- Add each user-facing change to `CHANGELOG.md` under `## [Unreleased]`.
- Never tag, push or release unless the owner asks.
- Tabs for indentation, LF line endings (`.editorconfig`).
- Anything that needs the game client (sound, the window, faction colours, combat-log
  fields) can only be checked by a human. Write down what needs checking instead of
  claiming it works.
