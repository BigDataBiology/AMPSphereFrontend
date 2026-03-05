# AMPSphere Frontend — Pages and API Reference

## Home.vue (`/home`)

Landing page with a carousel of distribution graphs (geographical, microbial source, habitat), summary statistics table, and a sequence search form (MMseqs for AMPs, HMMER for families) that navigates to SequenceSearch.

**API calls:**
- `GET /statistics` — fetches counts (num_amps, num_genes, num_families, etc.)

## AMP_Card.vue (`/amp?accession=AMP10.xxx`)

Individual AMP detail page. Overview tab shows quality badges (shields.io), peptide sequence, co-prediction scores, geographic/habitat/microbial-source Plotly charts, and a paginated metadata table of associated smORF genes. Features tab shows helical wheel, violin plots of biochemical properties positioned within the family, and secondary structure bar chart.

**API calls:**
- `GET /amps/{accession}` — AMP details (sequence, family, features, quality flags)
- `GET /amps/{accession}/distributions` — geographic, habitat, microbial source data
- `GET /amps/{accession}/coprediction` — co-prediction scores from multiple predictors
- `GET /families/{family}/features` — family-level feature distributions (for violin plots)
- `GET /amps/{accession}/metadata?page=&page_size=` — paginated smORF gene metadata

## Family_card.vue (`/family?accession=SPHERE-III.xxx`)

AMP family page. Overview tab has consensus sequence, sequence logo (from alignment file), secondary structure bar chart with error bars, geographic/habitat/microbial-source plots, and paginated associated AMPs table. Features tab shows violin/box plots of biochemical property distributions. Downloads tab provides alignment, sequences, HMM profile, tree files.

**API calls:**
- `GET /families/{accession}` — family details (consensus sequence, feature statistics, distributions, download links)
- `GET /families/{accession}/downloads/{accession}.aln` — alignment file for sequence logo
- `GET /amps/?family=&page=&page_size=` — paginated list of member AMPs

## Browse_data.vue (`/browse_data` or `/sample?sample=...`)

Filterable, paginated AMP table with sidebar controls: column visibility toggles, quality filters (high-quality, experimental evidence, Antifam, RNAcode, coordinates), metadata filters (habitat, microbial source), range sliders (peptide length, molecular weight, isoelectric point, charge), and advanced filters (family, sample/genome). Also used as the sample view when accessed with a `?sample=` query param.

**API calls:**
- `GET /amps?page=&page_size=&...filters` — paginated, filtered AMP list
- `GET /all_available_options` — filter dropdown options (habitats, microbial sources, ranges)
- `GET /in_db/{entity_type}/{value}` — validates family/sample existence in DB

## SequenceSearch.vue (`/sequence_search?method=MMseqs|HMMER&queries=...`)

Shows results of a sequence search initiated from the Home page. Displays an alignment table (MMseqs) or domain hit table (HMMER) with expandable alignment rows. Query sequences are passed via URL query params.

**API calls:**
- `GET /search/mmseqs?query=` — MMseqs2 sequence search
- `GET /search/hmmer?query=` — HMMER HMM profile search

## TextSearch.vue (`/text_search?query=...`)

Paginated results table for text-based searches (triggered from the global header search bar for non-accession queries). Shows accession, family, sequence, gene count, and quality tag.

**API calls:**
- `GET /search/text?query=&page=&page_size=` — paginated text search

## Downloads.vue (`/downloads`)

Static table of downloadable files (SQLite DB, TSV tables, MMseqs DB, HMM profiles). File URLs are constructed from `axios.defaults.baseURL + /downloads/...`. No dynamic API calls.

## About.vue (`/about`)

Static page describing AMPSphere, quality tests, and references. No API calls.

## Contact.vue (`/contact`)

Static contact information page. No API calls.
