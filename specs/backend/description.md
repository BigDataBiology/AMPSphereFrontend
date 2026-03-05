AMPSphere API provides read-only access to AMPSphere AMP, family, metadata, download, and sequence-search data.

All project-specific API routes are `GET` routes under `/v1`. The Swagger UI is served at `/`, ReDoc at `/redoc`, and the OpenAPI schema at `/openapi.json`.

## Current route groups

### AMP routes

- `/v1/amps`
- `/v1/amps/{accession}`
- `/v1/amps/{accession}/features`
- `/v1/amps/{accession}/distributions`
- `/v1/amps/{accession}/metadata`
- `/v1/amps/{accession}/coprediction`

### Family routes

- `/v1/families`
- `/v1/families/{accession}`
- `/v1/families/{accession}/features`
- `/v1/families/{accession}/distributions`
- `/v1/families/{accession}/downloads`
- `/v1/families/{accession}/downloads/{file}`

### Utility, download, and search routes

- `/v1/statistics`
- `/v1/all_available_options`
- `/v1/in_db/{entity_type}/{accession}`
- `/v1/downloads`
- `/v1/downloads/{file}`
- `/v1/search/mmseqs`
- `/v1/search/hmmer`
- `/v1/search/sequence-match`

## Implementation overview

- Route registration lives in `src/router.py` and is mounted by `src/main.py`.
- Business logic lives in `src/crud.py`.
- Data is loaded at import time by `src/database.py` from SQLite, TSV, and NumPy files under `data/`.
- Sequence feature, consensus, distribution, and file-path helpers live in `src/utils.py`.
- Response schemas are defined in `src/schemas.py`.

## Detailed reference

For a complete endpoint-by-endpoint description, including query parameters, response models, data sources, and implementation details, see `API_CALLS.md` in the repository root.
