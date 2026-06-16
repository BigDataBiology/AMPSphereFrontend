# AMPSphere Frontend

Web frontend for [AMPSphere](https://ampsphere.big-data-biology.org), a comprehensive catalog of antimicrobial peptides (AMPs) predicted from metagenomes and microbial genomes.

Built with [Elm Land](https://elm.land/) (v0.20.1).

## Prerequisites

- [Node.js](https://nodejs.org/) (v18+)
- [Elm Land](https://elm.land/) (`npm install -g elm-land@0.20.1`)

## Getting Started

```bash
# Install Elm dependencies (if needed)
elm-land build

# Start dev server on http://localhost:1234
elm-land server
```

## Production Build

```bash
elm-land build
# Output in dist/
```

## Configuration

The API base URL defaults to `https://ampsphere-api.big-data-biology.org/v1` and can be overridden via the `API_BASE_URL` environment variable.

## Project Structure

```
src/
  interop.js                    # JS flags + web component imports
  Effect.elm                    # Custom effects (apiGet, shared msgs)
  Shared.elm                    # App-wide state init/update
  Shared/
    Model.elm                   # { apiBaseUrl, globalSearchQuery }
    Msg.elm                     # Global search events
  Api.elm                       # Data type: NotAsked | Loading | Success | Failure
  Api/
    Statistics.elm              # GET /statistics
    Amp.elm                     # GET /amps/{accession}
    AmpDistributions.elm        # GET /amps/{accession}/distributions
    AmpCoprediction.elm         # GET /amps/{accession}/coprediction
    AmpMetadata.elm             # GET /amps/{accession}/metadata
    AmpList.elm                 # GET /amps (paginated, filtered)
    Family.elm                  # GET /families/{accession}
    FamilyFeatures.elm          # GET /families/{accession}/features
    FamilyDownloads.elm         # GET /families/{accession}/downloads
    AvailableOptions.elm        # GET /all_available_options
    SearchMmseqs.elm            # GET /search/mmseqs
    SearchHmmer.elm             # GET /search/hmmer
    SearchText.elm              # GET /search/text
  Layouts/
    Default.elm                 # Header (nav + global search) + footer
  Pages/
    Home_.elm                   # / — statistics + sequence search form
    Amp/Accession_.elm          # /amp/:accession — AMP detail card
    Family/Accession_.elm       # /family/:accession — family detail card
    BrowseData.elm              # /browse-data — filterable AMP table
    SequenceSearch.elm          # /sequence-search — MMseqs2/HMMER results
    TextSearch.elm              # /text-search — text search results
    Downloads.elm               # /downloads — downloadable files
    About.elm                   # /about
    Api.elm                     # /api — API usage documentation
    NotFound_.elm               # 404
  web-components/
    plotly-chart.js             # <plotly-chart> custom element wrapping Plotly.js
    helical-wheel.js            # <helical-wheel> custom element (helical wheel diagram)
    copy-button.js              # <copy-button> copy-to-clipboard custom element
static/
  styles.css                    # Global stylesheet
```

## Web Components

Interactive visualizations that are awkward to express in Elm are implemented as
custom elements and registered in `src/interop.js` (`onReady`). Elm renders the
element with `Html.node` and passes inputs via `data-*` attributes; the component
owns its own DOM, controls, and rendering.

- **`<plotly-chart data-chart="…">`** — wraps [Plotly.js](https://plot.ly/javascript/)
  (loaded from CDN) to draw the statistical charts. `data-chart` is a JSON blob with
  `data` / `layout` / `config`.

- **`<helical-wheel data-sequence="…">`** — renders a helical wheel projection of a
  peptide. Self-contained vanilla JS (no extra dependency) with controls for the
  angle of separation (α-helix / π-helix / 3-10), amino-acid color scheme (Cinema,
  Shapely, Lesk, Clustal, MAEditor, HeliQuest), hydrophobic-moment arrow,
  hydrophobic-face arc, and SVG export. The diagram is a port of the MIT-licensed
  d3 helical wheel by Tina Wang and Shyam Saladi
  ([clemlab/helicalwheel](https://github.com/clemlab/helicalwheel),
  <https://clemlab.github.io/helicalwheel/>), credited in the UI. The hydrophobic
  moment arrow is computed from the sequence using the Eisenberg consensus
  hydrophobicity scale: it points toward the hydrophobic face and its length
  scales with the mean moment `<μH>` (shown on hover). The hydrophobic-face arc
  is centered on that same moment direction, so both annotations track the
  sequence consistently (neither is drawn when the moment is ~zero).

- **`<copy-button data-text="…">`** — a small button that copies `data-text` to
  the clipboard and briefly shows a confirmation. Self-contained, with a
  `document.execCommand` fallback for browsers without the async Clipboard API.

## Pages

| URL | Description |
|-----|-------------|
| `/` | Landing page with database statistics and sequence search |
| `/amp/:accession` | AMP detail card (quality badges, sequence, co-prediction scores, distribution charts, metadata table, helical wheel, violin plots) |
| `/family/:accession` | Family card (consensus sequence, distributions, associated AMPs, feature box plots, download links) |
| `/browse-data` | Filterable, paginated AMP table with sidebar controls |
| `/sequence-search` | MMseqs2 or HMMER search results |
| `/text-search` | Text search results |
| `/downloads` | Downloadable data files |
| `/about` | About AMPSphere |
| `/api` | API usage documentation |

## Citation

Santos-Junior, C.D., Pan, S., Zhao, XM. *et al.* Discovery of antimicrobial peptides in the global microbiome with machine learning. *Cell* (2024). https://doi.org/10.1016/j.cell.2024.05.013
