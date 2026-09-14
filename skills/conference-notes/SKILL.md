---
name: conference-notes
description: Turns raw conference material (personal notes, AI-generated drafts, session photos, recordings from YouTube, Vimeo, or other yt-dlp-supported sources) for one or more talks into a complete conference write-up published as an MkDocs Material site on GitHub Pages, with one enriched page per talk and inline images. Use when the user wants to write up, summarize, or publish notes from a conference they attended, turn talk photos and recordings into a shareable recap site, or asks to "build a conference notes site" / "publish my conference notes". For a single talk that doesn't need a whole site, use the talk-writeup skill instead - this skill calls into it once per talk.
license: MIT
---

# Conference Notes

## Overview

Produces a full conference recap site: one markdown page per talk (via the
`talk-writeup` skill, run once per talk), scaffolded into an MkDocs Material
site and published on GitHub Pages. This skill owns the parts that only make
sense once there's a whole site to build - gathering assets across many
talks, scaffolding MkDocs, and publishing - while `talk-writeup` owns the
per-talk mechanics (transcript fetching, screenshots, writing the page
itself). See that skill's own SKILL.md for the fetch/screenshot/write-up
detail this document doesn't repeat.

## When to Use

- The user attended a conference and wants a polished, public (or shareable) write-up of the talks.
- They have some combination of: personal notes, an AI draft, HEIC photos from the talks, video links (YouTube, Vimeo, or elsewhere) to recordings, or an agenda.
- They want the result as a proper website (not just markdown files) - MkDocs Material on GitHub Pages.

Not for: a single talk write-up with no site (use `talk-writeup` directly),
or sites that already have their own publishing pipeline (adapt Phase 2
rather than overwrite it - see `docs/extending.md` in this skill's own repo,
or the general shape: keep calling `talk-writeup` per talk, replace what
happens to its output).

If the current repo has its own `.claude/skills/conference-notes/` (a
project-scoped copy, not this user-level one), prefer it - a repo with an
established site and its own conventions (post frontmatter, cross-link
patterns, image layout) typically adapts this skill into a leaner one that
writes directly into the existing site rather than running Phases 1-3 to
scaffold a new one.

## Before You Start - Gather Assets

Ask the user whether they have, per talk:
- [ ] Personal notes (markdown or plain text)
- [ ] An AI-generated draft (Gemini, ChatGPT, etc.) to enrich
- [ ] HEIC photos from the conference, organized in subfolders per talk
- [ ] YouTube URLs for talk recordings
- [ ] Vimeo URLs (or pages with inline Vimeo players) for talk recordings
- [ ] Recordings on any other site `yt-dlp` supports (1800+ hosts)
- [ ] An agenda URL or program
- [ ] Existing write-ups on the site that never got screenshots (retrofit
  candidates - see `talk-writeup`'s "Retrofitting Screenshots onto an
  Existing Write-up" section, applied per post under `docs/`)

Then run Phases 1-3 in order.

---

## Prerequisites - Check Before You Start

`talk-writeup` (Phase 1 below) needs `yt-dlp`, `ffmpeg`, and `sips` - see its
own SKILL.md for that check, plus its Vimeo-only extras. This skill
additionally needs:

```bash
for cmd in gh mkdocs; do
  command -v "$cmd" >/dev/null 2>&1 && echo "OK      $cmd" || echo "MISSING $cmd"
done
```

| Tool | Used for | Install |
|---|---|---|
| `gh` | Repo creation, GitHub Pages config (Phase 3) | `brew install gh` then `gh auth login` |
| `mkdocs` / `mkdocs-material` | Building and serving the site (Phase 2) | `pip install mkdocs-material` |

This is a preflight check, not an auto-installer - it never installs anything
on its own. Deciding to add a new binary to your machine is worth a
deliberate choice, not a silent side effect of running this skill.

---

## Phase 1 - Write Each Talk

For each talk, gather that talk's assets (above), then use the
`talk-writeup` skill's Phase 0, Phase 0b, Phase 1, Phase 2, and Phase 3 to
produce its write-up - but write the output directly into this site's
structure instead of a standalone location:

- Markdown page: `docs/TALK-SLUG.md` (talk-writeup's Phase 3 default output path)
- Images: `docs/images/TALK-SLUG/` (talk-writeup's Phase 2 default output directory)

Everything else about the per-talk mechanics - transcript fetching, the
Vimeo fallback chain, probing before extracting screenshots, linking quotes
back to timestamps - is identical to running `talk-writeup` standalone; only
the output paths change.

Once every talk has a page, create `docs/index.md` with the talk list,
cross-cutting themes across talks, and a glossary - this is a site-level
concern `talk-writeup` has no way to produce on its own, since it only ever
sees one talk at a time.

---

## Phase 2 - Set Up MkDocs

**`mkdocs.yml`** (minimal template - set `language` and the search `lang` to
match the notes' language, e.g. `en`):
```yaml
site_name: CONFERENCE NAME
site_url: https://USERNAME.github.io/REPO-NAME/
repo_url: https://github.com/USERNAME/REPO-NAME

theme:
  name: material
  language: en
  features:
    - navigation.tabs
    - navigation.tabs.sticky
    - navigation.top
    - search.highlight
    - content.code.copy

nav:
  - Overview: index.md
  - Talks:
    - "Talk 1": talk1.md
    # etc.

plugins:
  - search:
      lang: en

markdown_extensions:
  - admonition
  - tables
  - attr_list
```

**`.github/workflows/deploy.yml`**:
```yaml
name: Deploy MkDocs to GitHub Pages
on:
  push:
    branches: [main]
  workflow_dispatch:         # allows manually triggering via `gh workflow run`
permissions:
  contents: write
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: 3.x
      - run: pip install mkdocs-material
      - run: mkdocs gh-deploy --force
```

> **macOS `.gitignore` gotcha:** macOS's filesystem is case-insensitive. A
> pattern like `Keynote/` (no leading `/`) also matches `docs/images/keynote/`
> and silently excludes those photos from git. Always anchor HEIC-folder
> patterns to the repo root:

**`.gitignore`**:
```
.DS_Store
**/*.HEIC
**/*.heic
/Keynote/          # rooted pattern - matches ONLY the root, not docs/images/keynote/
/TalkFolder1/
/TalkFolder2/
/media/            # rooted - raw downloaded video + intermediate VTT from talk-writeup's Phase 0b
site/
```

---

## Phase 3 - Create the Repo and Publish

```bash
git init && git add . && git commit -m "Add conference notes and site"
gh repo create REPO-NAME --public --source=. --push
```

> **GitHub Pages gotcha:** Enabling GitHub Pages from the repo settings makes
> GitHub default to `build_type: workflow` with `main` as the source. That
> means it serves `README.md` directly - not the MkDocs output on
> `gh-pages`. Run this once, right after the first push:

```bash
gh api --method PUT repos/OWNER/REPO/pages \
  --field build_type=legacy \
  --field 'source[branch]=gh-pages' \
  --field 'source[path]=/'
```

Verify it took:
```bash
gh api repos/OWNER/REPO/pages | grep -E '"build_type"|"branch"'
# Should show: "build_type": "legacy"  and  "branch": "gh-pages"
```

Then push a small change to `main` (or run `gh workflow run deploy.yml`) to
trigger a fresh deploy against the correct source.

---

## Verify with Playwright

If the Playwright MCP is available (`claude mcp add playwright npx @playwright/mcp@latest`):

```
mcp__playwright__browser_navigate  →  https://USERNAME.github.io/REPO-NAME/
mcp__playwright__browser_take_screenshot
```

Check for:
- The MkDocs Material theme renders (not a raw README render)
- The correct page title from `docs/index.md` (not the README content)
- Images render on the talk pages

---

## File Structure

```
docs/
  index.md          # Overview, talk list, themes, glossary
  talk1.md
  talk2.md
  images/
    talk1/           # lowercase, no spaces
      IMG_XXXX.jpg
/TalkFolder1/        # HEIC originals - ignored by git via the rooted pattern
/media/              # Vimeo-sourced raw video + VTT (talk-writeup's Phase 0b) - ignored by git
  talk1/
    source.mp4
    source.vtt
mkdocs.yml
.github/workflows/deploy.yml
.gitignore
README.md           # Short: link to the Pages site + local run instructions (pip install mkdocs-material && mkdocs serve)
```

---

## Security Considerations

Per-talk risks (browser cookie use in the Vimeo fallback, platform Terms of
Service, publishing personal photos/quotes) are documented once, in
`talk-writeup`'s own SKILL.md, since they apply identically whether that
skill runs standalone or is called from here. This section covers what's
specific to running a whole site:

**`gh`/GitHub credentials** - Phase 3 assumes `gh auth login` is already done
and creates the repo with `--public` by default; treat that as a decision to
make each run, not a rubber stamp - `--private` is one flag away if the
material shouldn't be public yet. The `gh api .../pages` call and the deploy
workflow's `contents: write` permission are both scoped to that one repo; no
extra secrets or broader access are needed.

---

## Verification

- [ ] Every talk with source material has a `docs/<talk>.md` page (see `talk-writeup`'s own checklist for per-talk quality)
- [ ] `docs/index.md` lists all talks with cross-cutting themes and a glossary
- [ ] `.gitignore` uses rooted patterns for HEIC-original folders (macOS case-insensitivity gotcha)
- [ ] GitHub Pages `build_type` is `legacy` with source `gh-pages` (checked via `gh api repos/OWNER/REPO/pages`)
- [ ] Live site shows the MkDocs Material theme and correct title, not a raw README render
