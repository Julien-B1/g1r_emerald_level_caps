# Changelog

Format: [keep a changelog](https://keepachangelog.com/en/1.1.0/).
Version headings match `manifest.json`'s `version`.

## [0.1.7] - 2026-10-02

### Added

- An Aqua/Magma cap toggle for Maxie at Mt. Chimney, Maxie at Magma Hideout, and the Mossdeep Space Center multi battle.

## [0.1.6] - 2026-10-02

### Added

- Independent Rival, Wally, Steven, and post-game cap options.
- Optional Wally checkpoints default to off so skipped battles cannot hold progression.

## [0.1.5] - 2026-10-01

### Fixed

- B closes the direct PC storage shortcut instead of returning to the unused PC root menu.

## [0.1.4] - 2026-10-01

### Fixed

- Close the Gen 3 START menu after opening PC storage so it cannot remain stacked behind the PC or receive stale input after B closes it.

## [0.1.3] - 2026-10-01

### Fixed

- Align the CAPS title with the top content row in the summary frame.

## [0.1.2] - 2026-10-01

### Fixed

- Forward Gen 3 layer input with the correct callback signature so CAPS accepts navigation and cancel.

### Changed

- Rename the mod to 3G Level Caps and its START summary entry to CAPS.

## [0.1.1] - 2026-10-01

### Fixed

- Apply the level-cap clamp after other experience multipliers, including EXP QoL x100.
- Keep START open unless the direct Pokémon storage menu opens successfully.

### Added

- A START-menu boss rules panel showing the current cap and milestone progress.

## [0.1.0] - 2026-10-01

### Added

- Optional Emerald-only PC storage access from the START menu, hidden in the League by default.
- Ordered party selection before the listed major boss encounters.
- Optional progression-based level caps for battle experience and Rare Candy.
- Headless regression tests and manual test guidance.