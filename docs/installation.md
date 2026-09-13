# Installation

Pick whichever fits how you manage agent skills. All three install the same
`skills/conference-notes/` folder (`SKILL.md` + its two helper scripts).

## Option 1 — `gh skill install`

GitHub CLI's native agent-skills support (public preview, CLI v2.90.0+).
Discovers the skill via this repo's `skills/conference-notes/SKILL.md` and
writes provenance (repo, ref, tree SHA) into the installed copy's
frontmatter.

```bash
gh skill install hkvalheim/conference-notes conference-notes
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

The skill itself checks for these before doing any work — see its own
"Prerequisites" section — but for reference:

| Tool | Needed for |
|---|---|
| `yt-dlp` | Transcript + video download |
| `ffmpeg` | Frame extraction |
| `sips` (macOS-builtin) | HEIC → JPEG conversion |
| `gh` | Repo creation, GitHub Pages config |
| `mkdocs` + `mkdocs-material` | Building and serving the site |
| `curl_cffi` (Vimeo only) | Bypassing Vimeo's Cloudflare Turnstile |
| `mlx-whisper` (Vimeo only, Apple Silicon) | Local transcription |

None of these are auto-installed on your behalf — see
[Security considerations](security.md) for why that's deliberate.
