# Changelog

All notable changes to the AMPSphere frontend are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project does not yet follow semantic versioning; until a first tagged
release, changes accumulate under **Unreleased**.

## [Unreleased]

### Fixed
- Browse Data pagination now uses `onClickPreventDefault` on its page links,
  so clicking a page no longer lets `Browser.application` intercept the
  `<a href="#">` and push `#` onto the history stack.

### Added
- `improvements.md` — a triaged survey of potential improvements.
- `CHANGELOG.md` and `ARCHITECTURE.md`.

### Changed
- README: corrected stale documentation — removed the non-existent `/contact`
  page, documented the `/api` page and the `<copy-button>` web component.
