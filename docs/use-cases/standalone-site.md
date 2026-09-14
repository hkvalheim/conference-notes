# Use case: a standalone conference site

The most direct use of this skill: one conference, one new repo, one new
MkDocs Material site — running the skill's Phases 0 through 5 essentially
as-is.

Live example: **[javazone-2026](https://hkvalheim.github.io/javazone-2026/)**.

## Shape of the job

- 8 talks from one conference, sourced from a mix of YouTube and Vimeo
  recordings — several of the Vimeo-sourced talks needed the local Whisper
  transcription fallback, since Vimeo shipped no captions for them.
- Personal notes and session photos supplied per talk, enriched with each
  talk's transcript.
- Output: one markdown page per talk under `docs/`, an `index.md` tying them
  together with cross-cutting themes and a glossary, and inline screenshots
  picked from moments the write-up already quotes.
- The repo's own `mkdocs.yml` and `.github/workflows/deploy.yml` came
  straight from the skill's Phase 3 templates, and the GitHub Pages
  `build_type`/`gh-pages` fix from Phase 5 was needed on first publish, same
  as documented.

## Why this is the right shape for a new event

If there's no existing site to write into, scaffolding a fresh one is
simpler than trying to retrofit structure onto something that doesn't exist
yet. This is the default path — reach for the [project-local
fork](project-fork.md) pattern instead only when a site already exists and
you want the write-up to live inside it.
