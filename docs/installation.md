# Installation

Pick whichever fits how you manage agent skills. There are two skills to
install: `conference-notes` (the full multi-talk site) and `talk-writeup`
(a single talk's write-up, which `conference-notes` calls into per talk).
Install both unless you're certain you'll only ever want one.

## Option 1 — `gh skill install`

GitHub CLI's native agent-skills support (public preview, CLI v2.90.0+).
Discovers a skill via its own `skills/<name>/SKILL.md` in this repo and
writes provenance (repo, ref, tree SHA) into the installed copy's
frontmatter. Run it once per skill:

```bash
gh skill install hkvalheim/conference-notes conference-notes
gh skill install hkvalheim/conference-notes talk-writeup
```

## Option 2 — `npx skills add`

```bash
npx skills add hkvalheim/conference-notes
```

## Option 3 — Clone + `install.sh`

Use this if you want the repo on disk so you can `git pull` and resync later,
or if you want a project-local copy to adapt (see
[Extending the skill](extending.md)).

```bash
git clone https://github.com/hkvalheim/conference-notes.git
cd conference-notes
./install.sh <target>
```

| Target | Installs to |
|---|---|
| `claude-code` | `~/.claude/skills` |
| `claude-code-project` | `<cwd>/.claude/skills` |
| `copilot` | `~/.copilot/skills` |
| `copilot-agents` | `~/.agents/skills` |
| `copilot-project` | `<cwd>/.agents/skills` |
| `custom <dest>` | any directory you provide |

Re-run `./install.sh <target>` after a `git pull` to resync an installed copy
with the repo — it always overwrites the target with the current source, it
never merges.

## Dependencies

Each skill checks for its own dependencies before doing any work — see its
"Prerequisites" section — but for reference, combined:

| Tool | Needed for | Which skill |
|---|---|---|
| `yt-dlp` | Transcript + video download | `talk-writeup` |
| `ffmpeg` | Frame extraction | `talk-writeup` |
| `sips` (macOS-builtin) | HEIC → JPEG conversion | `talk-writeup` |
| `gh` | Repo creation, GitHub Pages config | `conference-notes` |
| `mkdocs` + `mkdocs-material` | Building and serving the site | `conference-notes` |
| `curl_cffi` (Vimeo only) | Bypassing Vimeo's Cloudflare Turnstile | `talk-writeup` |
| `mlx-whisper` (Vimeo only, Apple Silicon) | Local transcription | `talk-writeup` |

None of these are auto-installed on your behalf — see
[Security considerations](security.md) for why that's deliberate.
