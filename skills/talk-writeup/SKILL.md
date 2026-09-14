---
name: talk-writeup
description: Turns raw material for one conference talk (personal notes, an AI-generated draft, session photos, and a recording from YouTube, Vimeo, or another yt-dlp-supported source) into a single enriched markdown write-up with inline, quote-grounded screenshots and timestamp links back to the recording. Use when the user wants a write-up of one talk - not a whole conference site. Use when they ask to "summarize this talk with screenshots", "write up this session", or "turn this recording into a blog post". Not for scaffolding or publishing a multi-talk MkDocs site - use the conference-notes skill for that (it uses this skill internally per talk).
license: MIT
---

# Talk Write-up

## Overview

Produces one markdown page for a single conference talk, combining the
user's own notes, any AI-generated draft, photos taken during the talk, and
the talk's recording transcript (from YouTube, Vimeo, or another
yt-dlp-supported source) - with screenshots picked from the exact moments a
quote or claim in the write-up already supports, and every quote/screenshot
linked back to its source timestamp. This skill does not scaffold or publish
a site; it produces a markdown file plus an images folder, wherever the user
wants them.

## When to Use

- The user wants a write-up of **one** talk - a blog post, a shared doc, a
  page to drop into a site they already have.
- They have some combination of: personal notes, an AI draft, HEIC photos
  from the talk, a video link (YouTube, Vimeo, or elsewhere), a Vimeo page.
- They do **not** want a new MkDocs site scaffolded and published - if they
  do, or if there are multiple talks to cover, use the `conference-notes`
  skill instead (it calls into this skill once per talk, then handles the
  site).

## Before You Start - Gather Assets

Ask the user whether they have:
- [ ] Personal notes (markdown or plain text)
- [ ] An AI-generated draft (Gemini, ChatGPT, etc.) to enrich
- [ ] HEIC photos from the talk
- [ ] A YouTube URL, a Vimeo URL, or a page with an inline Vimeo player
- [ ] A recording on any other site `yt-dlp` supports (1800+ hosts) - it
  generally follows whichever of Phase 0/0b's shape it resembles: native
  captions available -> Phase 0's pattern, no captions or bot-gated -> Phase
  0b's pattern
- [ ] Where the output should go (a file path for the markdown, a folder for
  images) - if unspecified, default to `./TALK-SLUG.md` and `./images/TALK-SLUG/`
  in the current directory

Then run Phases 0-3 in order (use Phase 0b instead of/alongside Phase 0 for
a Vimeo-hosted talk).

---

## Prerequisites - Check Before You Start

```bash
for cmd in yt-dlp ffmpeg sips; do
  command -v "$cmd" >/dev/null 2>&1 && echo "OK      $cmd" || echo "MISSING $cmd"
done
```

| Tool | Used for | Install |
|---|---|---|
| `yt-dlp` | Transcript + video download (any yt-dlp-supported source) | `brew install yt-dlp` |
| `ffmpeg` | Frame extraction from downloaded video | `brew install ffmpeg` |
| `sips` | HEIC -> JPEG conversion (Phase 1, Phase 2) | Built into macOS - if missing, you're not on macOS and need a substitute |

Vimeo-only extras (Phase 0b) - skip these if the talk is YouTube-sourced:

| Tool | Used for | Install |
|---|---|---|
| `curl_cffi` | TLS-fingerprint impersonation past Vimeo's Cloudflare Turnstile | `pip3 install curl_cffi` |
| `mlx-whisper` | Local transcription on Apple Silicon (Vimeo ships no captions) | `pip3 install mlx-whisper` |

This is a preflight check, not an auto-installer - it never installs anything
on its own. Deciding to add a new binary to your machine is worth a
deliberate choice, not a silent side effect of running this skill.

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
```

### Parse VTT into plain text

Use `parse_vtt.py` (in this skill's own `scripts/` directory) rather than
hand-rolling a parser - it already handles the rolling-cue-block dedupe
correctly (see the script's docstring for why a naive dedupe leaves gaps in
the text). Resolve the path from wherever this SKILL.md was loaded from -
e.g. `~/.claude/skills/talk-writeup/scripts/parse_vtt.py`,
`~/.copilot/skills/talk-writeup/scripts/parse_vtt.py`, or
`skills/talk-writeup/scripts/parse_vtt.py` if run from a project-local copy
or this skill's own distribution repo.

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
and photos alone don't capture - use them actively to enrich the write-up.

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

**Probe before investing in this.** Not every talk has anything to
screenshot. Before grepping for quote timestamps, pull 4-5 frames spread
evenly across the runtime and look at them:

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
scripts/extract_frames.sh media/TALK-SLUG/source.mp4 images/TALK-SLUG \
  00:03:12 00:14:05 00:27:40
```

---

## Retrofitting Screenshots onto an Existing Write-up

A talk that was written up from a transcript alone - before this skill
supported frame extraction, or before anyone got around to it - can have
screenshots added later. That's a distinct workflow from Phases 0-3, not a
repeat of them:

1. **Find the real source.** A write-up can cite several links (a short
   teaser clip, a related talk mentioned in passing, the actual full
   recording) - check which one the write-up is actually built on before
   downloading anything.
2. **Probe first**, exactly as in Phase 0/0b - it may turn out to be a
   talking-head podcast or a PDF-only source with nothing to screenshot.
   Skip explicitly rather than force a decorative image in.
3. **Grep the *existing* prose for quote timestamps** - the write-up already
   contains the exact claims and quotes worth illustrating; use those to
   find moments, don't re-derive a new outline from scratch.
4. Extract, review, convert to output quality (Phase 2), and insert the
   images at the paragraphs that already discuss that point - this is an
   edit to a published file, so keep the surrounding prose intact and
   additive.
5. Note in the commit/summary which candidates were **intentionally**
   skipped and why (talking-head, PDF-only) - that record is what stops the
   same dead end being investigated twice.

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

## Phase 2 - Convert Photos to Output Quality

```bash
for f in /path/to/original/photos/TALK-SLUG/*.HEIC /path/to/original/photos/TALK-SLUG/*.heic; do
  [ -f "$f" ] || continue
  out="images/TALK-SLUG/$(basename "${f%.*}").jpg"
  mkdir -p "$(dirname "$out")"
  sips -Z 1600 -s format jpeg -s formatOptions 65 "$f" --out "$out" 2>/dev/null
done
```

1600px width, quality 65 gives readable slides at roughly 280KB per image.
Adjust the output directory to wherever the caller wants the final images -
`images/TALK-SLUG/` next to the markdown file by default, or straight into a
site's own `docs/images/TALK-SLUG/` when this skill is being driven by
`conference-notes` or a similar orchestrator.

---

## Phase 3 - Write the Summary

Produce a single markdown file for the talk:
- Combine personal notes + AI draft + photo content + transcript.
- Embed photos inline where they support a point: `![description](images/TALK-SLUG/IMG_XXXX.jpg)`
  (adjust the relative path to wherever Phase 2's images actually landed).
- Link every quote and photo/screenshot back to its source timestamp (see
  Phase 0's multi-speaker section for the `&t=Ns` arithmetic) - a short
  `[▶ Watch this moment](URL&t=Ns)` right after it is enough.
- Structure: intro -> main sections with photos -> key takeaways -> links/further reading.
- Default output path: `TALK-SLUG.md` in the current directory, unless the
  caller (the user, or an orchestrating skill like `conference-notes`) asked
  for a specific path.

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

**Publishing personal photos, transcripts, and quotes publicly** - Phase 1/2
photos can include identifiable bystanders, not just the speaker on stage;
crop them out or get consent before publishing. Attributing every quote to
its speaker and linking it back to the source timestamp (the `&t=Ns`/`#t=Ns`
convention used throughout) doubles as attribution, not just verifiability. A
published write-up should have some correction/takedown path (an email
address or an issue link is enough).

---

## Verification

- [ ] The talk has a single markdown write-up combining notes, draft, photos, and transcript
- [ ] Every screenshot was picked from a quote/claim already in the prose, not a blind interval sample
- [ ] A talking-head-only or PDF-only source was identified by probing first and explicitly skipped, not forced
- [ ] Every quote and screenshot links back to its exact `&t=Ns` timestamp in the source video (or Vimeo's `#t=Ns` fragment)
- [ ] Photos are at output quality (Phase 2), not the Phase 1 preview crops
