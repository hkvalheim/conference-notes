# conference-notes

**conference-notes** is an agent skill (for Claude Code, GitHub Copilot CLI,
and other `SKILL.md`-compatible assistants) that turns raw conference
material into a complete, published write-up.

Give it some combination of:

- Personal notes (markdown or plain text)
- An AI-generated draft you want enriched
- Photos taken during the talks
- A link to the talk's recording — YouTube, Vimeo, or anything else
  [yt-dlp](https://github.com/yt-dlp/yt-dlp) supports

and it produces one enriched markdown page per talk — notes, draft, photos,
and transcript combined — published as an [MkDocs
Material](https://squidfunk.github.io/mkdocs-material/) site on GitHub Pages.

## What makes it different from "summarize this video"

- **Screenshots are evidence-grounded, not sampled.** Frames are picked from
  the exact moment a quote or claim already in the write-up supports, after
  probing first to confirm the talk actually has slides or a screen-share
  worth capturing — not a blind evenly-spaced sample, and not a decorative
  image for a talking-head-only recording.
- **Every quote and screenshot links back to its source timestamp** — a
  reader who wants more context can jump straight to that second in the
  recording instead of scrubbing a multi-hour stream by hand.
- **It documents its own hard parts.** Fetching a YouTube transcript is
  simple; fetching a Vimeo one reliably (no native captions, a Cloudflare
  Turnstile challenge in front of the player) is not — the skill carries a
  tested fallback chain for that instead of leaving it to trial and error.

## Where to go next

- [**Installation**](installation.md) — get the skill into your agent
- [**How it works**](how-it-works.md) — the CLI tools it shells out to, and why
- [**Security considerations**](security.md) — what to know before running it
- [**Use cases**](use-cases/standalone-site.md) — a from-scratch conference
  site, and a project-local fork that writes into an existing one
- [**Extending the skill**](extending.md) — adapting it to your own site's
  conventions

Source and issues: [github.com/hkvalheim/conference-notes](https://github.com/hkvalheim/conference-notes)
