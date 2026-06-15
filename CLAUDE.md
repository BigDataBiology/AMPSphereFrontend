# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
elm-land server   # dev server on http://localhost:1234
elm-land build    # production build → dist/
```

No test framework is configured. Verify changes compile with `elm-land build`.

## Architecture

Elm Land v0.20.1 SPA with file-based routing. Backend is a read-only REST API at `https://ampsphere-api.big-data-biology.org/v1`.

### Key Patterns

**API calls** use a custom `Effect.apiGet` that defers HTTP commands — the base URL is injected at runtime from `Shared.Model.apiBaseUrl`. Each `src/Api/*.elm` module exposes a `get` function returning `Effect msg`:

```elm
Api.Amp.get { accession = "AMP10.000_000", onResponse = GotAmp }
```

**Remote data** uses `Api.Data`: `NotAsked | Loading | Success a | Failure Http.Error`. Pages set `Loading` in init, then pattern-match in the view.

**Layout** (`Layouts.Default`) provides a Bootstrap Navbar with global search. Search routing: `AMP*` → `/amp/{id}`, `SPHERE*` → `/family/{id}`, else → `/text-search?query=`. The layout communicates with shared state via `Effect.sendSharedMsg`.

**UI** uses `rundis/elm-bootstrap` 5.2.0 (Bootstrap 4.3.1 CSS via CDN). Plotly charts use a `<plotly-chart>` web component (`src/web-components/plotly-chart.js`). The helical wheel is a self-contained `<helical-wheel data-sequence="...">` web component (`src/web-components/helical-wheel.js`) — a vanilla-JS port of the MIT-licensed d3 helical wheel by Tina Wang & Shyam Saladi (https://clemlab.github.io/helicalwheel/), with angle/color-scheme/hydrophobic-moment/hydrophobic-face controls and SVG export. The hydrophobic-moment arrow is computed from the sequence (Eisenberg consensus scale): direction = hydrophobic face, length ∝ mean moment `<μH>`. Web components are registered in `src/interop.js` (`onReady`). Custom CSS is minimal (~120 lines in `static/styles.css`).

**Pagination links** must use `onClickPreventDefault` (via `Html.Events.preventDefaultOn "click"`) on `<a href="#">` elements — otherwise `Browser.application` intercepts the click and fires unwanted `pushUrl "#"`.

**Tabs with lazy loading** (Amp, Family pages): `Tab.State` is opaque so active tab is tracked separately in the model with explicit switch messages that trigger data fetching.

### Known Issues

- The `/all_available_options` endpoint returns ~29,500 microbial source strings. With the Elm debugger enabled (dev mode), `Debug.toString` on this data causes a stack overflow, freezing the app. Production builds (debugger disabled) are unaffected.
