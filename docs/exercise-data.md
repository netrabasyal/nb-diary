# Exercise data

Implemented in Phase 6. Rules agreed in Phase 0:

- No scraping of copyrighted content. Every record and media file carries a source and licence.
- Instructions and safety notes come only from licensed sources; if none, the field stays empty.
- V1 library is text only (no images) until media provenance is checked.

## Candidate sources

| Source | Licence | Planned use |
| --- | --- | --- |
| [free-exercise-db](https://github.com/yuhonas/free-exercise-db) | Unlicense (public domain) | Seed for names, muscles, equipment, categories. Provenance of instructions checked first. |
| [wger](https://wger.readthedocs.io/) | Data CC-BY-SA 3.0; code AGPL | Optional enrichment, with share-alike obligations. |
| Commercial APIs | Paid | Excluded unless licensed. |

## Ingestion pipeline (Phase 6)

Fetch pinned release → stage → validate → normalise → deduplicate (uncertain matches go to review)
→ diff by content hash → version → publish (bumps the catalogue version).
