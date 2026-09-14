# Extending the skill

The general-purpose skill scaffolds a brand-new MkDocs site from scratch.
If you already have a site — a blog, a documentation hub, an internal
wiki — and just want new talk write-ups to land inside it, fork the skill
instead of running its scaffolding phases.

## How to fork it

1. Copy `skills/conference-notes/` into your own repo, at
   `.claude/skills/conference-notes/` (Claude Code discovers project-scoped
   skills there recursively) or `.agents/skills/conference-notes/` (Copilot
   CLI's project-local convention).
2. Bring the two scripts along inside your copy's own `scripts/` directory,
   rather than referencing the user-level install — that way your fork keeps
   working even on a machine that's never installed the general skill.
3. Keep Phase 0 and Phase 0b (transcript fetching, Vimeo's fallback chain)
   as-is — they don't depend on where the output goes.
4. Rewrite the "what happens after the transcript exists" phases to match
   your site: where the new page goes, what frontmatter it needs, what
   existing pages it should cross-link into, how it gets built and deployed.
5. Update the skill's own frontmatter `description` so it accurately
   describes what your fork does now — an agent matches on that description
   to decide when to use it.
6. If your site already has posts written before this pattern existed,
   consider adding a retrofit phase — see the general skill's own
   "Retrofitting Screenshots onto Existing Write-ups" section for the shape
   of that workflow.

See [the project-fork use case](use-cases/project-fork.md) for a worked
example of exactly this.

## Keeping a fork in sync

A fork is a deliberate copy, not a symlink — pulling changes from this repo
won't automatically reach it. Revisit your fork when this skill's Phase 0/0b
mechanics change (a new platform gotcha, a new fallback step) even if your
own publishing phases haven't.
