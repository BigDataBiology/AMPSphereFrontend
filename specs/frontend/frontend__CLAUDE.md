# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AMPSphere is a Vue 3 frontend for browsing a catalog of antimicrobial peptides (AMPs). It displays AMP data, family groupings, geographical/habitat distributions, sequence searches, and quality assessments. Live at https://ampsphere.big-data-biology.org/

## Commands

- `npm run serve` — dev server with hot-reload (port 8080)
- `npm run build` — production build to `dist/`
- `npm run lint` — lint and auto-fix
- `npm run report` — production build with bundle analysis

## Architecture

**Stack:** Vue 3 (Options API) + Vue Router 4 + Quasar + Element Plus + Axios + Plotly.js (loaded from CDN, declared as webpack external)

**API:** All data comes from `https://ampsphere-api.big-data-biology.org/v1` (configured in `src/main.js` via `axios.defaults.baseURL`). API calls use `this.axios.get()` within Vue components.

**Key directories:**
- `src/views/` — Page-level components, one per route. Each is a large self-contained SFC with data fetching, display logic, and Plotly chart configuration.
- `src/components/` — Reusable components: `Plotly.vue` (wrapper around plotly.js), `SeqLogo.vue`, `HelicalWheel.vue`
- `src/router/index.js` — All routes defined here; uses `createWebHistory`

**Pages (views):**

- **Home.vue** (`/home`) — Landing page with a carousel of distribution graphs (geographical, microbial source, habitat), summary statistics table, and a sequence search form (MMseqs for AMPs, HMMER for families) that navigates to SequenceSearch.
  - `GET /statistics` — fetches counts (num_amps, num_genes, num_families, etc.)

- **AMP_Card.vue** (`/amp?accession=AMP10.xxx`) — Individual AMP detail page. Overview tab shows quality badges (shields.io), peptide sequence, co-prediction scores, geographic/habitat/microbial-source Plotly charts, and a paginated metadata table of associated smORF genes. Features tab shows helical wheel, violin plots of biochemical properties positioned within the family, and secondary structure bar chart.
  - `GET /amps/{accession}` — AMP details (sequence, family, features, quality flags)
  - `GET /amps/{accession}/distributions` — geographic, habitat, microbial source data
  - `GET /amps/{accession}/coprediction` — co-prediction scores from multiple predictors
  - `GET /families/{family}/features` — family-level feature distributions (for violin plots)
  - `GET /amps/{accession}/metadata?page=&page_size=` — paginated smORF gene metadata

- **Family_card.vue** (`/family?accession=SPHERE-III.xxx`) — AMP family page. Overview tab has consensus sequence, sequence logo (from alignment file), secondary structure bar chart with error bars, geographic/habitat/microbial-source plots, and paginated associated AMPs table. Features tab shows violin/box plots of biochemical property distributions. Downloads tab provides alignment, sequences, HMM profile, tree files.
  - `GET /families/{accession}` — family details (consensus sequence, feature statistics, distributions, download links)
  - `GET /families/{accession}/downloads/{accession}.aln` — alignment file for sequence logo
  - `GET /amps/?family=&page=&page_size=` — paginated list of member AMPs

- **Browse_data.vue** (`/browse_data` or `/sample?sample=...`) — Filterable, paginated AMP table with sidebar controls: column visibility toggles, quality filters (high-quality, experimental evidence, Antifam, RNAcode, coordinates), metadata filters (habitat, microbial source), range sliders (peptide length, molecular weight, isoelectric point, charge), and advanced filters (family, sample/genome). Also used as the sample view when accessed with a `?sample=` query param.
  - `GET /amps?page=&page_size=&...filters` — paginated, filtered AMP list
  - `GET /all_available_options` — filter dropdown options (habitats, microbial sources, ranges)
  - `GET /in_db/{entity_type}/{value}` — validates family/sample existence in DB

- **SequenceSearch.vue** (`/sequence_search?method=MMseqs|HMMER&queries=...`) — Shows results of a sequence search initiated from the Home page. Displays an alignment table (MMseqs) or domain hit table (HMMER) with expandable alignment rows. Query sequences are passed via URL query params.
  - `GET /search/mmseqs?query=` — MMseqs2 sequence search
  - `GET /search/hmmer?query=` — HMMER HMM profile search

- **TextSearch.vue** (`/text_search?query=...`) — Paginated results table for text-based searches (triggered from the global header search bar for non-accession queries). Shows accession, family, sequence, gene count, and quality tag.
  - `GET /search/text?query=&page=&page_size=` — paginated text search

- **Downloads.vue** (`/downloads`) — Static table of downloadable files (SQLite DB, TSV tables, MMseqs DB, HMM profiles). File URLs are constructed from `axios.defaults.baseURL + /downloads/...`. No dynamic API calls.

- **About.vue** (`/about`) — Static page describing AMPSphere, quality tests, and references. No API calls.

- **Contact.vue** (`/contact`) — Static contact information page. No API calls.

**Plotly:** Loaded globally from CDN in `public/index.html`, mapped as webpack external (`"plotly.js": "Plotly"` in `vue.config.js`). The `Plotly.vue` component wraps the global Plotly object.

**Styling:** Quasar grid system (`q-*` classes) for layout; Element Plus components (`el-table`, etc.) for data tables; custom CSS in `src/styles/`.

## Conventions

- Components use Vue 3 Options API (not Composition API / `<script setup>`)
- Route params are passed via query strings (e.g., `?accession=AMP10.000_000`), not path params
- Accession IDs: AMPs start with `AMP`, families start with `SPHERE`
