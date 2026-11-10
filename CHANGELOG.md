# Changelog

All notable changes to this addon are listed here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Project scaffold: `.toc`, packaging, lint and test setup, CI and release workflows, and the Owen Wilson "Wow" clip in `media/`.
- Your critical hits and heals, and your pet's, play the "Wow" clip.
- `/owen on` and `/owen off` turn it on and off.
- A `loaded` message in chat when you log in.
- `/owen` opens a small faction-themed window: a Play button to preview the clip, an Enabled toggle, a note about the Dialog volume and the list of commands. Drag it by the title bar; Esc or [x] closes it.

### Changed
- The volume slider is gone; the clip follows the game's Dialog volume, and the window says so.

### Fixed
- Crits in combat no longer trigger "blocked from an action": the addon no longer changes sound settings.
