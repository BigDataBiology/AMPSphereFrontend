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
- Favicon (`static/favicon.ico`), referenced via a `<link rel="icon">` in
  `elm-land.json`.
- `improvements.md` — a triaged survey of potential improvements.
- `CHANGELOG.md` and `ARCHITECTURE.md`.
- Shared modules to remove cross-page duplication: `Util.Format`
  (`float`/`thousands`/`percent`/`eValue`/`truncate`), `Util.Html`
  (`onClickPreventDefault`/`spinner`/`errorAlert`), `Components.Pagination`
  (`view`/`small`), and an `Api.view` helper that collapses the
  `NotAsked/Loading/Failure/Success` ladder.

### Changed
- Centralized formatters, the `onClickPreventDefault` helper, the RemoteData
  view ladder, and pagination into the shared modules above; all six pages now
  use them. Pagination is standardized on a single 0-indexed convention,
  removing the 0- vs 1-indexed mismatch between pages.
- README: corrected stale documentation — removed the non-existent `/contact`
  page, documented the `/api` page and the `<copy-button>` web component.
- Browse Data: replaced the 14-positional-argument `buildFilters` with a
  `modelToFilters : Model -> Int -> Filters` helper that builds the filter record
  directly from the model, removing the risk of silently mis-ordering same-typed
  arguments.
