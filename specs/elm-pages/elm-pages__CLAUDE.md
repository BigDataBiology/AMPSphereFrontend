# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Elm Land is a framework and CLI tool for building web applications with Elm. Published as the `elm-land` npm package (v0.20.1, alpha). The main deliverable is in `projects/cli/`.

## Repository Structure

Multi-project monorepo (no workspace tooling — each project is independent):

- **`projects/cli/`** — Main CLI tool (JavaScript + Elm, ES modules)
- **`projects/graphql/`** — `@elm-land/graphql` GraphQL codegen (WIP)
- **`projects/tooling/codegen/`** — `@elm-land/codegen` Elm code generation library
- **`projects/tooling/elm-error-json/`** — Elm compiler error rendering (TypeScript)
- **`docs/`** — elm.land website (VitePress)
- **`examples/`** — 20 example projects

## Build & Test Commands (projects/cli/)

```bash
cd projects/cli
npm install
npm run build          # Compile Elm workers (codegen-worker.cjs, validate-worker.cjs)
npm run dev            # Watch mode — recompile workers on Elm source changes
npm link               # Make elm-land CLI available globally (needed before tests)
npm test               # Run full bats test suite

# Run a single test file
npx bats tests/01-basic.bats

# Run a specific test by name
npx bats tests/01-basic.bats --filter "can run"
```

Other sub-projects:
- `projects/tooling/codegen/`: `npm test` runs `elm-test`
- `projects/tooling/elm-error-json/`: `npm test` runs `jest`

## Architecture

**Effect-based CLI pattern:** Each command returns `{ message, files, effects }`. The runner (`src/index.js`) creates files via `Files.create()`, runs side-effects via `Effects.run()` (dispatched by `kind`: `runServer`, `build`, `generate`, `customize`), then prints the message.

**Elm workers as build tools:** Code generation and validation are compiled Elm `Platform.worker` programs (`src/codegen/src/Worker.elm`, `src/validate/src/Worker.elm`) that run in Node.js. JavaScript communicates via Elm ports — data goes in as flags to `Elm.Worker.init()`, results come back via `ports.onComplete.subscribe()`. The build step (`npm run build`) compiles these into `dist/codegen-worker.cjs` and `dist/validate-worker.cjs`.

**File-based routing:** Pages in `src/Pages/` define routes by file structure. Conventions: `Home_.elm` → `/`, `Users/Id_.elm` → `/users/:id` (trailing `_` = dynamic param), `Blog/ALL_.elm` → `/blog/*` (catch-all).

**Customizable defaults:** Framework provides default `Effect.elm`, `Shared.elm`, `View.elm`, `Auth.elm`, etc. in `.elm-land/src/`. Users run `elm-land customize <name>` to copy and override them.

**Vite-powered dev server:** Uses `vite-plugin-elm-watch` for hot reloading. Watches for file changes and regenerates framework files automatically.

## Test Suite

Tests use **Bats** (Bash Automated Testing System). Test files are in `projects/cli/tests/`. Helper utilities in `tests/helpers.bash` provide `expectToPass`, `expectToFail`, `expectOutputContains`, `expectFileExists`, `expectFileContains`.

CI runs on macOS-14 with Node.js 18 and 20.

## Languages

- JavaScript (ES modules) — CLI glue code
- Elm 0.19.1 — Code generation, validation, generated user app code
- TypeScript — `elm-error-json` package
- Bash (Bats) — Test suite

## PR Guidelines

PRs should follow the Problem/Solution/Notes format. Start a conversation in the Elm Land Discord before opening a PR.
