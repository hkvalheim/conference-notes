---
name: conference-notes
description: Turns raw conference material (personal notes, AI-generated drafts, session photos, recordings from YouTube, Vimeo, or other yt-dlp-supported sources) into a complete conference write-up published as an MkDocs Material site on GitHub Pages, with one enriched page per talk and inline images. Use when the user wants to write up, summarize, or publish notes from a conference they attended, turn talk photos and recordings into a shareable recap site, or asks to "build a conference notes site" / "publish my conference notes".
license: MIT
---

# Conference Notes

## Overview

Produces a full conference recap site: one markdown page per talk, combining the
user's own notes, any AI-generated draft, photos taken during the talk, and the
talk's recording transcript (from YouTube, Vimeo, or another yt-dlp-supported
source) - then publishes it as an MkDocs Material site on GitHub Pages. This
skill is self-contained: every command, gotcha, and explanation needed to go
from raw material to a live site lives here.

## When to Use

- The user attended a conference and wants a polished, public (or shareable) write-up of the talks.
- They have some combination of: personal notes, an AI draft, HEIC photos from the talks, video links (YouTube, Vimeo, or elsewhere) to recordings, or an agenda.
- They want the result as a proper website (not just markdown files) - MkDocs Material on GitHub Pages.

Not for: a single blog post about one talk (just write the markdown directly), or sites that already have their own publishing pipeline (adapt Phase 3 rather than overwrite it).

If the current repo has its own `.claude/skills/conference-notes/` (a
project-scoped copy, not this user-level one), prefer it - a repo with an
established site and its own conventions (post frontmatter, cross-link
patterns, image layout) typically adapts this skill into a leaner one that
writes directly into the existing site rather than running Phases 1-5 to
scaffold a new one. Phase 0/0b transcript and frame-extraction mechanics
below still apply either way.

## Before You Start - Gather Assets

Ask the user whether they have:
- [ ] Personal notes (markdown or plain text)
- [ ] An AI-generated draft (Gemini, ChatGPT, etc.) to enrich
- [ ] HEIC photos from the conference, organized in subfolders per talk
- [ ] YouTube URLs for talk recordings
- [ ] Vimeo URLs (or pages with inline Vimeo players) for talk recordings
- [ ] Recordings on any other site `yt-dlp` supports (1800+ hosts) - these generally follow whichever of Phase 0/0b's shape they resemble: native captions available -> Phase 0's pattern, no captions or bot-gated -> Phase 0b's pattern
- [ ] An agenda URL or program
- [ ] Existing write-ups on the site that never got screenshots (retrofit candidates - see the dedicated section after Phase 0b)

Then run Phases 0-5 in order (use Phase 0b instead of/alongside Phase 0 for Vimeo-hosted talks).

---

## Prerequisites - Check Before You Start

Run this before Phase 0 to catch a missing tool early instead of mid-phase:

```bash
for cmd in yt-dlp ffmpeg sips gh mkdocs; do
  command -v "$cmd" >/dev/null 2>&1 && echo "OK      $cmd" || echo "MISSING $cmd"
done
```

| Tool | Used for | Install |
|---|---|---|
| `yt-dlp` | Transcript + video download (any yt-dlp-supported source) | `brew install yt-dlp` |
| `ffmpeg` | Frame extraction from downloaded video | `brew install ffmpeg` |
| `sips` | HEIC -> JPEG conversion (Phase 1, Phase 4) | Built into macOS - if missing, you're not on macOS and need a substitute |
| `gh` | Repo creation, GitHub Pages config (Phase 5) | `brew install gh` then `gh auth login` |
| `mkdocs` / `mkdocs-material` | Building and serving the site | `pip install mkdocs-material` |

Vimeo-only extras (Phase 0b) - skip these if every talk is YouTube-sourced:

| Tool | Used for | Install |
|---|---|---|
| `curl_cffi` | TLS-fingerprint impersonation past Vimeo's Cloudflare Turnstile | `pip3 install curl_cffi` |
| `mlx-whisper` | Local transcription on Apple Silicon (Vimeo ships no captions) | `pip3 install mlx-whisper` |

This is a preflight check, not an auto-installer - it never installs anything
on its own. Deciding to add a new binary to your machine is worth a deliberate
choice, not a silent side effect of running this skill.

---

## Phase 0 - Fetch Transcripts

> **Important:** Don't use WebFetch or Playwright for this. WebFetch only returns
> YouTube's footer HTML. Playwright hits the cookie dialog and the page content
> never loads. `yt-dlp` uses YouTube's internal API and pulls subtitles
> directly - no video is downloaded.

The same `--write-auto-subs` approach works unmodified for any site `yt-dlp`
lists caption support for (`yt-dlp --list-extractors` covers 1800+ sites) -
YouTube is simply the common case here. A site with no native captions
(Vimeo among them) needs Phase 0b's local-transcription fallback instead.

```bash
# Install if needed (macOS)
brew install yt-dlp

# Download subtitles for one video (no video is downloaded)
yt-dlp --write-auto-subs --write-subs --sub-langs "en.*" --skip-download \
  -o "/tmp/yt_transcripts/%(title)s" "https://www.youtube.com/watch?v=VIDEO_ID"

# For several videos at once
for url in "URL1" "URL2" "URL3"; do
  yt-dlp --write-auto-subs --write-subs --sub-langs "en.*" --skip-download \
    -o "/tmp/yt_transcripts/%(title)s" "$url"
done
```

### Parse VTT into plain text

Use `parse_vtt.py` (in this skill's own `scripts/` directory) rather than
hand-rolling a parser - it already handles the rolling-cue-block dedupe
correctly (see the script's docstring for why a naive dedupe leaves gaps in
the text). Resolve the path from wherever this SKILL.md was loaded from -
e.g. `~/.claude/skills/conference-notes/scripts/parse_vtt.py`,
`~/.copilot/skills/conference-notes/scripts/parse_vtt.py`, or
`skills/conference-notes/scripts/parse_vtt.py` if run from a project-local
copy or this skill's own distribution repo.

```bash
# Process every *.en.vtt file in a directory
python3 /path/to/conference-notes/scripts/parse_vtt.py /tmp/yt_transcripts/

# Extract just one speaker's section from a multi-speaker stream
python3 /path/to/conference-notes/scripts/parse_vtt.py \
  /tmp/yt_transcripts/STREAM.en.vtt --start 04:52:36 --end 05:41:10
```

`--start`/`--end` accept `HH:MM:SS` and only apply in single-file mode.

### Multi-speaker streams - find the right section

All-day streams contain many talks. Never trust a user-supplied timestamp
blindly - always verify it first:

```bash
# Grep for a keyword from the talk to find the right speaker and timestamp
grep -i "KEYWORD" /tmp/yt_transcripts/STREAM.en.vtt | head -20
```

VTT timestamps map 1:1 in seconds to YouTube's `t=` URL parameter:
```
[04:52:36] = 4×3600 + 52×60 + 36 = 17556 → &t=17556s
```

This isn't just for finding the right section - use the same arithmetic to
link every quote and screenshot in the write-up back to its exact moment
(`https://www.youtube.com/watch?v=VIDEO_ID&t=17556s`). A reader who wants to
verify a claim or see more context shouldn't have to scrub a multi-hour
recording by hand. Vimeo's equivalent is a URL fragment on the canonical
`vimeo.com/ID` page (not the `player.vimeo.com` embed form used for
downloading): `https://vimeo.com/VIDEO_ID#t=90s`.

Read the resulting `.txt` files with the Read tool - typically ~40-60KB for a
one-hour talk. Transcripts carry details, anecdotes, and numbers that notes
and photos alone don't capture - use them actively to enrich the write-ups.

### Spot-check caption quality before trusting it

YouTube's auto-captions are machine-generated and their quality is
inconsistent **per video, not per channel or per uploader** - two talks from
the exact same channel can differ from clean to unusable. Before writing a
single sentence of the post from a downloaded transcript, skim at least the
first page of the parsed `.txt` for tell-tale corruption: words or phrases
that don't belong to the talk's language or topic at all (stray website
names, unrelated brand names, garbled fragments repeating mid-sentence).
Don't assume a transcript is fine just because a previous video from the
same source worked, and don't assume it's broken just because a previous one
was - check each one on its own.

If it's corrupted, don't try to patch it up - fall back to a local
transcription exactly as Phase 0b does for Vimeo: download the video
(`yt-dlp -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]"`) and run
`mlx_whisper` against it, then feed the resulting `.vtt` into the same
`parse_vtt.py`. This local-transcription fallback isn't Vimeo-specific - it's
the answer any time a source's native captions are missing *or* unusable.

### Rate limiting on the caption endpoint

YouTube's caption endpoint throttles independently of the video endpoint -
expect an occasional `ERROR: Unable to download video subtitles for 'en':
HTTP Error 429: Too Many Requests`, especially right after fetching subs for
a different video. Just retry the same `yt-dlp` command once; it typically
succeeds on the second attempt without any backoff needed. If it keeps
failing, proceed on video + prior write-up knowledge alone (see the probing
step below) rather than blocking the whole task on one transcript.

### Also want screenshots, not just the transcript?

`yt-dlp --skip-download` above never touches the video - fine for a pure
text summary, but conference talks usually have slides worth capturing. If
screenshots are wanted, download the video too and extract frames with the
same `scripts/extract_frames.sh` used for Vimeo in Phase 0b (it's source-agnostic,
nothing YouTube-specific needed):

```bash
brew install ffmpeg   # if not already installed

yt-dlp -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" \
  -o "media/TALK-SLUG/source.%(ext)s" "https://www.youtube.com/watch?v=VIDEO_ID"
```

`height<=1080` is a deliberate cap, not a limitation to work around - 1080p
is already enough resolution for legible slide screenshots, and the highest
available format is often a much larger 4K file that only slows the
download down for no visible benefit in a still frame.

**Pick timestamps from evidence, not guesses.** Once a written summary (or
draft) exists, grep the transcript for the exact quotes/claims already in
the prose - that reliably lands on the right slide, far more often than
evenly-spaced sampling:

```bash
grep -n -i "the exact phrase from your draft" media/TALK-SLUG/transcript.txt
```

Convert the matched line's `[HH:MM:SS]` tag straight into `extract_frames.sh`'s
timestamp argument. Extract 2-3 candidate frames a few seconds apart around
each moment (slides often change mid-sentence) and look at all of them with
the Read tool before picking - the first frame at a guessed timestamp is
frequently a mid-transition blur or the wrong slide.

**Probe before investing in this, for both new talks and old ones.** Not
every talk has anything to screenshot. Before grepping for quote timestamps,
pull 4-5 frames spread evenly across the runtime and look at them:

```bash
for t in 100 500 1000 1500 2000; do   # adjust to the video's actual duration
  ffmpeg -y -ss "$t" -i media/TALK-SLUG/source.mp4 -frames:v 1 -q:v 2 \
    "/tmp/probe_${t}.png" -loglevel error
done
```

- **Pure talking-head / podcast format** (every probe frame is just a face
  and a microphone, no slides or screen-share): stop here. Do not add a
  generic portrait as a screenshot - it carries no information the reader
  couldn't get from the author photo already on the post. Say so plainly and
  move on without images for that talk.
- **Slide deck or screen-share visible** in the probes: proceed to the
  quote-timestamp step above.
- **The source is actually a PDF/slide-deck link, not a recording** (some
  talks publish only a static deck): there's no video to extract frames
  from. That's a different, PDF-screenshotting task, out of scope for this
  video-frame workflow - flag it rather than forcing a workaround.

---

## Phase 0b - Fetch Vimeo Transcripts & Frames

Vimeo needs a different approach from YouTube: there's no equivalent of
`yt-dlp --write-auto-subs` that reliably works, and Vimeo's player endpoint
is commonly protected by a Cloudflare Turnstile challenge that blocks plain
HTTP clients (curl, or yt-dlp without a real browser fingerprint) with a
`401` even when `Referer`/`Origin` headers look correct. Treat this as a
fallback chain - try each step only if the previous one fails - rather than
a single command.

### Step 1 - Find the video ID

If the user gives a direct Vimeo URL or ID, skip to Step 2. If they only
give a page that embeds the video (e.g. a conference program page), that
page is very often a JS-rendered SPA - the raw HTML has no video reference.
Don't waste time scraping rendered DOM. Instead:

```bash
# Fetch the page and look for an obvious script bundle
curl -s -A "Mozilla/5.0" "PAGE_URL" -o /tmp/page.html
grep -o 'src="[^"]*\.js"' /tmp/page.html

# Pull the JS bundle(s) and grep for vimeo references or an API base URL
curl -s -A "Mozilla/5.0" "https://SITE/assets/BUNDLE.js" -o /tmp/bundle.js
grep -o 'https\?://[a-zA-Z0-9./_-]*' /tmp/bundle.js | sort -u | grep -iE 'vimeo|api'
```

Many conference sites ship a public JSON data feed for their own frontend
(a `/public/...` or `/api/...` endpoint) - it usually surfaces the Vimeo
video ID alongside title/speaker/abstract in one shot, which is far more
reliable than trying to render the SPA. Check for one before falling back to
Step 1 for every single talk.

### Step 2 - Try automated download

`curl`/plain `yt-dlp` gets a `401` with a Cloudflare Turnstile challenge page
no matter what headers are sent - that's TLS-fingerprint bot detection, not
a missing header. `yt-dlp`'s `--impersonate` (via `curl_cffi`) fixes this in
practice: it makes the request look like a real Chrome TLS handshake, which
passes Turnstile without needing any cookies or manual browser step.

```bash
brew install ffmpeg
pip3 install curl_cffi   # in a venv - lets yt-dlp impersonate a real browser TLS fingerprint

yt-dlp --impersonate chrome --referer "PAGE_URL_THAT_EMBEDS_THE_VIDEO" \
  -o "media/TALK-SLUG/source.%(ext)s" "https://player.vimeo.com/video/VIDEO_ID"
```

**Use the `player.vimeo.com/video/VIDEO_ID` form, not `vimeo.com/VIDEO_ID`**
- the latter hits yt-dlp's "web client" code path which additionally
requires a logged-in Vimeo account and fails with "The web client only
works when logged-in" even with impersonation working correctly. The
player URL goes straight for the HLS manifest and just works.

This succeeds outright (no Step 3/4 needed) for most Vimeo pages once
`curl_cffi` is installed - Turnstile is TLS-fingerprint based, not per-video,
so once impersonation works for one talk on a site it typically works for the
rest.

### Step 3 - If that fails with a 401 / Turnstile error

A real browser passes Turnstile silently; a bare HTTP client can't solve it.
Ask the user to open the embedding page once in their normal, logged-in
Chrome (just letting the player load is enough), then retry reusing that
session's cookies:

```bash
yt-dlp --cookies-from-browser chrome --referer "PAGE_URL" \
  -o "/tmp/vimeo_dl/%(id)s.%(ext)s" "https://vimeo.com/VIDEO_ID"
```

### Step 4 - If it still fails: manual fallback

Tell the user exactly which URL to open and where to save the result, e.g.
"open https://vimeo.com/VIDEO_ID, download or screen-record it, and save it
as `media/TALK-SLUG/source.mp4`". This is not a dead end - Step 5 onward is
identical no matter which step produced the local file.

### Step 5 - Transcript and frames from the local video file

Vimeo videos typically ship no captions at all (unlike YouTube's
auto-subs), so transcribe locally. On Apple Silicon, `mlx-whisper` uses the
GPU via MLX and is much faster than CPU-only Whisper:

```bash
pip3 install mlx-whisper
mlx_whisper media/TALK-SLUG/source.mp4 --language no \
  --output-format vtt --output-dir media/TALK-SLUG/
```

(swap `--language no` for the talk's actual language). Feed the resulting
`.vtt` straight into the **same** `scripts/parse_vtt.py` used for YouTube -
it already handles VTT correctly regardless of source, no changes needed.

For screenshots, first read the transcript and pick 3-5 moments that
actually illustrate a concrete point (grep for the moment a concept/tip is
introduced) - don't guess evenly-spaced timestamps blind. Then extract them:

```bash
scripts/extract_frames.sh media/TALK-SLUG/source.mp4 docs/images/TALK-SLUG \
  00:03:12 00:14:05 00:27:40
```

---

## Retrofitting Screenshots onto Existing Write-ups

A site built with this skill (or with a "just write the markdown directly"
single post, per the scope note above) accumulates talks that were written
up from a transcript alone, before this skill supported frame extraction, or
before anyone got around to it. Coming back to add screenshots later is a
distinct workflow from Phases 0-4, not a repeat of them:

1. **Find every candidate and its real source.** Grep every existing post for
   a video link:
   ```bash
   grep -oE 'https://(www\.)?(youtube\.com|youtu\.be|vimeo\.com)/[^)"[:space:]]+' \
     docs/**/*.md
   ```
   A post can cite several links (a short teaser clip, a related talk
   mentioned in passing, the actual full recording) - the first regex match
   is not reliably the primary source. Check the post's own "Source(s)"
   section for which link the write-up is actually built on before
   downloading anything.
2. **Probe first, per talk**, exactly as in Phase 0/0b - some of the
   candidates will turn out to be talking-head podcasts or PDF-only sources
   with nothing to screenshot. Skip those explicitly rather than force a
   decorative image in.
3. **Grep the *existing* prose for quote timestamps** - the write-up already
   contains the exact claims and quotes worth illustrating; use those to find
   moments, don't re-derive a new outline from scratch.
4. Extract, review, convert to repo quality (Phase 4), and insert the images
   at the paragraphs that already discuss that point - this is an edit to a
   published file, so keep the surrounding prose intact and additive.
5. Note in the commit/summary which candidates were **intentionally**
   skipped and why (talking-head, PDF-only) - that record is what stops the
   same dead end being investigated twice.

---

## Growing an Existing Site Over Time

Most repeat runs of this skill aren't "scaffold a whole site from a pile of
assets" (Phases 1-5 once) - they're "add one more talk to a site that's
already live," repeated every time a good talk turns up. That's a distinct,
lighter workflow with its own gotchas:

- **Give every post an explicit, machine-findable date.** Use a
  `**Published:**` (or `**Talk date:**` if the two differ, e.g. a conference
  talk recorded months before the recording was uploaded) line near the top
  of the post, in a consistent format (`DD Month YYYY`) - the same line
  already used for `**Speaker:**`/`**Source:**`/`**Length:**`. This is what
  makes reordering later mechanical `grep` work instead of re-reading every
  post to remember when it happened.
- **Insert new posts in date order, don't append.** When adding a talk to a
  site that already has others, place its entry in `mkdocs.yml`'s nav list
  and in `docs/index.md`'s post listing at its chronological position among
  the existing posts (by the date above), not at the end of the list. If the
  user hasn't said which date to sort by, ask once, then stay consistent -
  don't mix "upload date" for some posts and "original talk date" for others
  on the same site.
- **Multi-part series get a shared slug and two-way links.** For an
  interview or talk split across multiple videos (e.g. `..._part-1.md`,
  `..._part-2.md`), use one shared slug prefix with a `-part-N` suffix, and
  add a "Further reading" link from each part to every other part - a reader
  landing on part 2 first still needs a way to find part 1.
- **Re-run `mkdocs build --strict` after any reorder**, not just after
  adding new content - a manual nav edit is exactly the kind of change a
  stray indentation or missing colon slips into unnoticed.

---

## Phase 1 - Read the Photos

iPhone HEIC files are too large for the Read tool (>256KB). Convert to small
JPEGs first - `sips` is built into macOS:

```bash
for dir in /path/to/photos/*/; do
  talk=$(basename "$dir")
  mkdir -p /tmp/conf_images/$talk
  for f in "$dir"*.HEIC "$dir"*.heic; do
    [ -f "$f" ] || continue
    out="/tmp/conf_images/$talk/$(basename "${f%.*}").jpg"
    sips -Z 800 -s format jpeg -s formatOptions 15 "$f" --out "$out" 2>/dev/null
  done
done
```

Read the images in batches of 10-15 at a time to avoid tool rejection.

---

## Phase 2 - Write the Summaries

Create one markdown file per talk in `docs/`:
- Combine personal notes + AI draft + photo content + transcript.
- Embed photos inline where they support a point: `![description](images/talk-name/IMG_XXXX.jpg)`.
- Link every quote and photo/screenshot back to its source timestamp (see
  Phase 0's multi-speaker section for the `&t=Ns` arithmetic) - a short
  `[▶ Watch this moment](URL&t=Ns)` right after it is enough.
- Structure per talk: intro → main sections with photos → key takeaways → links/further reading.
- Create `docs/index.md` with the talk list, cross-cutting themes, and a glossary.
- **Verify every external link before publishing, not just the source
  video/URL.** "Further reading" links (official write-ups, research pages,
  related talks) rot or get reorganized independently of the source
  recording - fetch each one (e.g. with a web-fetch tool) and confirm it
  resolves before including it. If an obvious canonical link 404s, look for
  the organization's own current URL for that resource rather than linking
  to a mirror or an outdated path - a dead link in a "further reading"
  section is worse than no link at all.

---

## Phase 3 - Set Up MkDocs

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
/media/            # rooted - raw downloaded video + intermediate VTT from Phase 0b
site/
```

---

## Phase 4 - Convert Photos to Repo Quality

```bash
for dir in /path/to/original/photos/*/; do
  talk=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  outdir="/path/to/repo/docs/images/$talk"
  mkdir -p "$outdir"
  for f in "$dir"*.HEIC "$dir"*.heic; do
    [ -f "$f" ] || continue
    out="$outdir/$(basename "${f%.*}").jpg"
    sips -Z 1600 -s format jpeg -s formatOptions 65 "$f" --out "$out" 2>/dev/null
  done
done
```

1600px width, quality 65 gives readable slides at roughly 280KB per image.

---

## Phase 5 - Create the Repo and Publish

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
/media/              # Vimeo-sourced raw video + VTT (Phase 0b) - ignored by git
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

**Browser cookie use** (Phase 0b Step 3, `--cookies-from-browser chrome`) -
this reads live session cookies out of a running browser profile. Use it only
when the Turnstile/impersonation steps actually fail, not as a default habit.
Check which Google/Vimeo account that browser profile is actually logged into
first - the cookies read are whatever's active at invocation time. Nothing is
persisted by this skill; the cookies are read once, for that one `yt-dlp`
call.

**Platform Terms of Service** - Phase 0/0b download video or audio, not just
captions, from YouTube/Vimeo. Whether that's permitted depends on the
platform's ToS and how the result is used. Most conference organizers
explicitly allow derivative write-ups and screenshots of their own published
recordings, but that's not universal - check the conference's own
recording/reuse policy before publishing, not just before downloading.

**Publishing personal photos, transcripts, and quotes publicly** - Phase 1/4
photos can include identifiable bystanders, not just the speaker on stage;
crop them out or get consent before publishing. Attributing every quote to
its speaker and linking it back to the source timestamp (the `&t=Ns`/`#t=Ns`
convention used throughout) doubles as attribution, not just verifiability. A
published site should have some correction/takedown path (an email address or
an issue link in the footer is enough).

**`gh`/GitHub credentials** - Phase 5 assumes `gh auth login` is already done
and creates the repo with `--public` by default; treat that as a decision to
make each run, not a rubber stamp - `--private` is one flag away if the
material shouldn't be public yet. The `gh api .../pages` call and the deploy
workflow's `contents: write` permission are both scoped to that one repo; no
extra secrets or broader access are needed.

---

## Verification

- [ ] Every talk with source material has a `docs/<talk>.md` page
- [ ] Downloaded transcripts were spot-checked for garbled/corrupted captions before being used, and re-transcribed locally (`mlx-whisper`) if unusable
- [ ] Vimeo-sourced talks have both a transcript-derived write-up and at least one extracted screenshot
- [ ] Every screenshot was picked from a quote/claim already in the prose, not a blind interval sample
- [ ] Talking-head-only and PDF-only sources were identified by probing first and explicitly skipped, not forced
- [ ] Every quote and screenshot links back to its exact `&t=Ns` timestamp in the source video (or Vimeo's `#t=Ns` fragment)
- [ ] Every external "further reading"/reference link was verified to resolve, not just the source recording link
- [ ] `docs/index.md` lists all talks with cross-cutting themes and a glossary
- [ ] Each post has an explicit, consistently-formatted publish/talk date, and both `mkdocs.yml`'s nav and `docs/index.md`'s list are ordered chronologically by it, not by add-order
- [ ] Photos render inline on their talk pages, sized for the repo (Phase 4, not the Phase 1 preview crops)
- [ ] `.gitignore` uses rooted patterns for HEIC-original folders (macOS case-insensitivity gotcha)
- [ ] GitHub Pages `build_type` is `legacy` with source `gh-pages` (checked via `gh api repos/OWNER/REPO/pages`)
- [ ] Live site shows the MkDocs Material theme and correct title, not a raw README render
