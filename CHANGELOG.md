# Changelog

All notable changes to this addon are listed here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-11-10

First release, for WoW Forever (client 1.60.1, Interface 16001).

### Added
- Owen Wilson says "Wow" when your hostile target takes a critical hit (melee, ranged, wand, spell, or your pet's) and when you receive a critical heal. This client blocks addons from the combat log, so in a group other players' crits on your target play it too.
- No more than one "Wow" at a time: crits during the clip are skipped.
- `/owen` opens a small faction-themed window (blue for Alliance, red for Horde): a Play button to preview the clip, an Enabled toggle, a note about the volume and the list of commands. Drag it by the title bar; Esc or [x] closes it.
- `/owen on` and `/owen off` turn it on and off. Settings are saved per account.
- The clip plays on the game's Dialog channel, so Options > Audio > Dialog sets its volume. The addon never changes your sound settings.
