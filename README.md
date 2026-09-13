# conference-notes

A Claude Code / Copilot CLI agent skill that turns raw conference material —
personal notes, an AI-generated draft, session photos, and a talk recording
(YouTube, Vimeo, or any other [yt-dlp](https://github.com/yt-dlp/yt-dlp)-supported
source) — into a complete conference write-up, published as an
[MkDocs Material](https://squidfunk.github.io/mkdocs-material/) site on GitHub
Pages: one enriched page per talk, quote-grounded screenshots, and links back
to the exact timestamp in the source recording.

📖 **Full docs, security considerations, and use cases:**
https://hkvalheim.github.io/conference-notes/

## What it does

- Fetches a talk's transcript (native captions when available, local
  Whisper transcription when not) and parses it into clean, timestamped text.
- Extracts screenshots from the moments a quote or claim in the write-up
  already supports — never a blind, evenly-spaced sample.
- Combines notes, AI drafts, photos, and transcript into one markdown page
  per talk, with every quote and image linked back to its source timestamp.
- Scaffolds and deploys an MkDocs Material site on GitHub Pages, or — via its
  documented fork pattern — adapts into an existing site instead.

## Install

Pick one:

```bash
# GitHub CLI (native agent-skills support)
gh skill install hkvalheim/conference-notes conference-notes

# npx skills
npx skills add hkvalheim/conference-notes

# Manual clone + install script
git clone https://github.com/hkvalheim/conference-notes.git
cd conference-notes
./install.sh claude-code            # or: claude-code-project, copilot, copilot-agents, copilot-project, custom <dest>
```

Re-run `./install.sh <target>` after `git pull` to resync an installed copy
with this repo.

## Repository layout

```
skills/conference-notes/   # the skill itself (SKILL.md + scripts/) - the installable unit
docs/                       # this repo's own documentation site source
mkdocs.yml
install.sh
```

See the [docs site](https://hkvalheim.github.io/conference-notes/) for the CLI
tools this skill relies on, security considerations before running it, and
worked examples (a standalone conference site, and a project-local fork that
writes into an existing site).

## License

MIT — see [LICENSE](LICENSE).
