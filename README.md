# BattyBirdNET Docker Setup

Docker Compose setup that builds and runs the [BattyBirdNET-Analyzer](https://github.com/rdz-oss/BattyBirdNET-Analyzer)
REST API server locally, for classifying bat (and bird) calls from uploaded audio.

## Usage

```
docker compose up -d
```

The server listens on `http://localhost:7667` (configurable via `.env`).

- `GET /healthcheck`
- `POST /analyze` — multipart upload with an `audio` file field and an optional
  `meta` JSON form field (`lat`, `lon`, `overlap`, `sensitivity`, `sf_thresh`, `pmode`, `save`)

Configuration lives in `.env`:

- `AREA` — classifier region (default `EU`). Valid values: `Bavaria`, `EU`, `Scotland`,
  `South-Wales`, `UK`, `USA`, `USA-EAST`, `USA-WEST`, `BIRDS`, `CUSTOM_BIRD`, `CUSTOM_BAT`.
  The server picks one classifier at startup; it cannot be switched per-request.
- `PORT` — host port to publish (default `7667`)
- `REPO_REF` — upstream git ref to clone at build time (default `main`)

## `meta` field effects

`/analyze`'s `meta` JSON accepts `lat`, `lon`, `week`, `overlap`, `sensitivity`,
`sf_thresh`, `pmode`, and `save`. Not all of them affect the returned result:

| Field | Effect |
|---|---|
| `overlap` | Changes segment windowing (overlap between consecutive analysis windows). |
| `sensitivity` | Changes the confidence scores in the response. |
| `save` | Persists the uploaded file and the JSON response under `uploads/<date>/`, which this repo's compose volume mounts, so they do survive container restarts. The server never deletes these — they accumulate indefinitely with no built-in cleanup or rotation, unlike the default (unsaved) path, where each request's temp file is explicitly removed after analysis. Only use `save: true` if you have your own process for pruning `uploads/`. |
| `pmode` | Parsed and validated, but the code path that would use it (pooling per-segment scores into one per-file result) is commented out in `server.py`. No effect on the response. |
| `lat`, `lon`, `week`, `sf_thresh` | Parsed and validated, but the species-list filtering that would use them only exists in a code path (`saveResultFile()`, used for CLI file export) that the API server never calls. No effect on the response for any `--area`. Separately, this filtering is wired to a bird-only occurrence model, so it would only ever be meaningful for `--area BIRDS`/`CUSTOM_BIRD`, not the bat areas. |

`results` in the response is always the full unpooled per-segment breakdown —
every candidate species per time window, not a single verdict for the file.

## Modification to upstream

`Dockerfile` patches a bug in upstream's `server.py`: the `--area` validation
whitelist omits `"EU"` and `"Scotland"`, even though both have working classifier
branches and bundled `.tflite` checkpoints. The patch adds them to the whitelist
so `--area EU` and `--area Scotland` work as documented in the script's own
`--help` text.

## Attribution & License

This repository packages and makes a small modification to
[BattyBirdNET-Analyzer](https://github.com/rdz-oss/BattyBirdNET-Analyzer) by
R.D. Zinck, licensed under
[CC BY-NC-SA 4.0](http://creativecommons.org/licenses/by-nc-sa/4.0/).
In keeping with that license's ShareAlike terms, this repository (an adaptation)
is licensed under the same terms — see [LICENSE](LICENSE). Use is non-commercial
only.

If you use BattyBirdNET-Analyzer, the upstream project asks that you cite it:

```bibtex
@misc{Zinck2023,
  author = {Zinck, R.D.},
  title = {BattyBirdNET - Bat Sound Analyzer},
  year = {2023},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/rdz-oss/BattyBirdNET-Analyzer}}
}
```
