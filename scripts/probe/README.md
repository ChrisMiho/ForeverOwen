# ForeverOwen Phase 0 probe (throwaway)

Never ships (`.pkgmeta` ignores `scripts/`). Run it once in game to confirm the API
assumptions in PRD section 4.1 and 4.3, then record the results in PRD section 7.

## Install

1. Create `_forever_\Interface\AddOns\ForeverOwenProbe\` in the game folder.
2. Copy everything from `scripts/probe/ForeverOwenProbe/` into it.
3. Copy `media/OwenWilson.mp3` into the same folder (next to `Probe.lua`).
4. Start the game. Check the AddOns list: the probe loads and is not "out of date".

## Things to try

- A melee crit, a spell crit, a heal crit, and a DoT/HoT crit.
- A pet crit, and a **totem crit** (Searing Totem).
- A crit into a shield (Power Word: Shield, or a target dummy with an absorb).
- `/owenprobe vol 0.2`, then `/owenprobe vol 1`. Listen for loudness and for the end
  of the clip being cut off.
- `/owenprobe api`.

Output lines start with `OwenProbe`. Combat lines show the sub-event, source name, source
flags in hex, then fields `[12]` to `[21]`. Find which index holds the crit boolean.

## Results

| # | Check (PRD section 7) | Result | Notes |
|---|---|---|---|
| 1 | Loads with Interface 16001, not out of date | | |
| 2 | `PlaySoundFile(..., "Dialog")` plays the mp3 | | |
| 3 | `Sound_DialogVolume` set before play changes loudness; restore at 1.09 s does not cut the clip | | |
| 4 | `critical` positions correct: SWING_DAMAGE (18) | | |
| 4 | RANGE/SPELL/SPELL_PERIODIC_DAMAGE (21) | | |
| 4 | DAMAGE_SHIELD (21) | | |
| 4 | SPELL_HEAL / SPELL_PERIODIC_HEAL (18) | | |
| 5 | AFFILIATION_MINE set: player | | |
| 5 | AFFILIATION_MINE set: pet | | |
| 5 | AFFILIATION_MINE set: guardian | | |
| 5 | AFFILIATION_MINE set: shaman totem (Searing Totem) | | |
| 6 | Absorbed crit arrives as `*_MISSED` with `missType == "ABSORB"`, critical at 15 (swing) / 18 (others) | | |
| 6 | DAMAGE_SHIELD (Thorns) can crit | | |
| API | `C_AddOns` is a table | | |
| API | `BackdropTemplate` frame creates | | |
| API | `UICheckButtonTemplate` / `UIPanelButtonTemplate` create | | |
| API | `UISpecialFrames` is a table | | |
