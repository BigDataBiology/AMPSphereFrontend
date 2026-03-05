# AGENTS.md

## Project Overview

REST API backend for the [AMPSphere](https://ampsphere.big-data-biology.org) antimicrobial peptide database. Built with FastAPI, serving AMP data with sequence search capabilities (MMSeqs2, HMMER).

## Commands

```bash
# Run tests
python -m pytest tests

# Run a single test file
python -m pytest tests/test_api_calls.py

# Dev server
uvicorn src.main:app --reload

# Production server
gunicorn -w 4 -k uvicorn.workers.UvicornH11Worker src.main:app

# Generate backend data (requires data in data/original_data/, takes hours)
./generate_data.sh

# Install dependencies (conda)
conda install -c default -c conda-forge -c bioconda \
    fastapi gunicorn sqlalchemy pandas pytest pydantic biopython requests \
    mmseqs2 hmmer uvicorn
conda install -c default -c conda-forge httpx  # for testing
```

## Architecture

**Entry point**: `src/main.py` creates a FastAPI app with three routers, all under `/v1`:
- `amp_router` (`/v1/amps`) -- individual AMP queries, features, distributions, metadata
- `family_router` (`/v1/families`) -- AMP family queries, features, distributions, downloads
- `default_router` (`/v1`) -- statistics, downloads, search (mmseqs, hmmer, exact match)

**Key modules**:
- `src/router.py` -- Route definitions, maps HTTP endpoints to `crud` functions
- `src/crud.py` -- All business logic: filtering, pagination, search orchestration
- `src/database.py` -- Data loading at import time (module-level globals)
- `src/schemas.py` -- Pydantic response models
- `src/utils.py` -- Protein analysis (BioPython), distribution calculations, config management

**Data layer** (hybrid, loaded at startup via `database.py`):
- **SQLite** (`data/ampsphere_main_db/AMPSphere_latest.sqlite`) -- GMSC gene metadata, queried via raw `sqlite3`
- **Polars DataFrame** (`data/tables/AMP.tsv`) -- AMP table, held in memory as `database.amps`
- **NumPy array** (`data/pre_computed/AMP_coprediction_AMPSphere.npy`) -- co-prediction matrix indexed by AMP number
- **Python dict** (`data/tables/GTDBTaxonRank.tsv`) -- GTDB taxonomy mapping

Because data is loaded at module import time, `import src.database` (or anything that imports it) requires the data files to exist.

**Search**: `crud.mmseqs_search()` and `crud.hmmscan_search()` run MMSeqs2/HMMER as subprocesses against pre-built databases in `data/mmseqs_db/` and `data/hmmprofile_db/`.

**Config**: `config/config.ini` stores paths to databases, tmp dir, and log files. Parsed via `configparser` in `src/utils.py`.

## Testing

Tests use `fastapi.testclient.TestClient` and compare against expected JSON fixtures in `tests/expected/`. The parametrized tests in `tests/test_api_calls.py` read inputs from `tests/inputs.tsv`.

CORS is enabled only when the `ADD_CORS_HEADERS` environment variable is set.

## Data Pipeline

`scripts/generate_main_db_tables.py` transforms raw bioinformatics data (FASTA, metadata TSVs, GTDB taxonomy) into the tables and databases the API serves. The shell script `generate_data.sh` orchestrates the full pipeline including MMSeqs2 indexing and HMM database pressing.
