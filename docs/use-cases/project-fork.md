# Use case: a project-local fork

Not every write-up needs a new site. One real adoption of this skill lives
inside an existing documentation site — a technical blog with its own
`mkdocs.yml`, its own `docs/blog/posts/`, and its own cross-linked
`docs/architecture/` and `docs/best-practices/` pages already in place.
Running `conference-notes`'s Phases 1–3 there would mean scaffolding a
second, redundant site next to one that already exists.

Instead, that repo keeps its own copy at `.claude/skills/conference-notes/`
— a **project-local fork**, not just an installed copy — adapted to:

- Write one new blog post into the existing `docs/blog/posts/`, instead of
  scaffolding a new `docs/` tree — a rewrite of `conference-notes`'s own
  Phase 1 delegation to `talk-writeup`, not a change to `talk-writeup`
  itself.
- Add cross-links from that post into the site's existing architecture and
  best-practices pages, matching conventions the general skill has no way to
  know about.
- Add a retrofit step, matching `talk-writeup`'s own "retrofitting
  screenshots onto an existing write-up" workflow, for posts written before
  this pattern existed.
- Add a prerequisites table specific to that repo's own build tooling.
- Add a step to cross-check a video's actual recording date against its
  upload date — useful in any repo publishing dated posts, not something
  the general skill assumes.

`talk-writeup` itself didn't need forking at all here — its transcript and
frame-extraction mechanics are identical regardless of where the output
ends up, and it already writes to whatever path it's given. Only
`conference-notes`'s own phases (what happens once a talk's write-up
exists) got replaced with whatever that project's site actually needs.

See [Extending the skill](../extending.md) for how to set this up in your
own repo.
