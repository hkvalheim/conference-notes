# Extending the skill

`conference-notes` scaffolds a brand-new MkDocs site from scratch. If you
already have a site — a blog, a documentation hub, an internal wiki — and
just want new talk write-ups to land inside it, fork `conference-notes`
instead of running its scaffolding phases. `talk-writeup`, which
`conference-notes` calls into per talk, usually needs **no forking at all**:
it already writes its markdown page and images wherever it's told to, so
pointing it at your site's `docs/` (or wherever posts live) is enough.

## How to fork it

1. Copy `skills/conference-notes/` into your own repo, at
   `.claude/skills/conference-notes/` (Claude Code discovers project-scoped
   skills there recursively) or `.agents/skills/conference-notes/` (Copilot
   CLI's project-local convention). Leave `talk-writeup` as the shared,
   user-level skill unless your site needs its own copy too (see below).
2. Rewrite Phase 1 ("Write Each Talk") to point `talk-writeup`'s output at
   your site's actual structure instead of `docs/TALK-SLUG.md` /
   `docs/images/TALK-SLUG/` — where the new page goes, what frontmatter it
   needs, what existing pages it should cross-link into.
3. Rewrite Phase 2/3 (MkDocs setup, publish) to match how your site is
   already built and deployed — or delete them entirely if the site has its
   own pipeline and you only need Phase 1's per-talk step.
4. Update the skill's own frontmatter `description` so it accurately
   describes what your fork does now — an agent matches on that description
   to decide when to use it.
5. If your site already has posts written before this pattern existed,
   consider adding a retrofit phase — see `talk-writeup`'s own
   "Retrofitting Screenshots onto an Existing Write-up" section for the
   shape of that workflow.

See [the project-fork use case](use-cases/project-fork.md) for a worked
example of exactly this.

## When to also fork `talk-writeup`

Only fork `talk-writeup` itself if you need to change its per-talk
mechanics — a new platform gotcha, a different transcript source, a
different default image size. If you only need its *output* to land
somewhere different, that's a one-line change to the path you pass it, not a
fork. If you do fork it, bring `scripts/parse_vtt.py` and
`scripts/extract_frames.sh` along inside your copy's own `scripts/`
directory, rather than referencing the user-level install — that way your
fork keeps working even on a machine that's never installed the shared
skill.

## Keeping a fork in sync

A fork is a deliberate copy, not a symlink — pulling changes from this repo
won't automatically reach it. Revisit your `conference-notes` fork when its
Phase 1 delegation contract changes; revisit a `talk-writeup` fork (if you
made one) when its Phase 0/0b mechanics change (a new platform gotcha, a new
fallback step).
