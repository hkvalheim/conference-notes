# Use case: a project-local fork

Not every write-up needs a new site. One real adoption of this skill lives
inside an existing documentation site — a technical blog with its own
`mkdocs.yml`, its own `docs/blog/posts/`, and its own cross-linked
`docs/architecture/` and `docs/best-practices/` pages already in place.
Running the general skill's Phases 1–5 there would mean scaffolding a
second, redundant site next to one that already exists.

Instead, that repo keeps its own copy at `.claude/skills/conference-notes/`
— a **project-local fork**, not just an installed copy — adapted to:

- Write one new blog post into the existing `docs/blog/posts/`, instead of
  scaffolding a new `docs/` tree.
- Add cross-links from that post into the site's existing architecture and
  best-practices pages, matching conventions the general skill has no way to
  know about.
- Bundle its own copies of `scripts/parse_vtt.py` and
  `scripts/extract_frames.sh`, so the fork works even on a machine that has
  never installed the user-level skill.
- Add a `Phase R` retrofit step, matching the general skill's own
  "retrofitting screenshots onto existing write-ups" workflow, for posts
  written before this pattern existed.
- Add a prerequisites table specific to that repo's own build tooling.
- Add a step to cross-check a video's actual recording date against its
  upload date — useful in any repo publishing dated posts, not something
  the general skill assumes.

Phase 0/0b's transcript and frame-extraction mechanics don't need to
change — they're identical regardless of where the output ends up. Only the
"what happens after the transcript exists" phases (1–5 in the general skill)
get replaced with whatever that project's site actually needs.

See [Extending the skill](../extending.md) for how to set this up in your
own repo.
