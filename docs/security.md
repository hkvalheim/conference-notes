# Security considerations

This skill downloads third-party media, reads local files, and publishes
content publicly. None of that is unusual for the task, but it's worth
understanding before you run it.

## Browser cookie use

Vimeo's fallback chain includes, as a last resort before a fully manual
download, reusing your browser's existing session:

```bash
yt-dlp --cookies-from-browser chrome --referer "PAGE_URL" ...
```

This reads live session cookies out of a running browser profile. Use it
only when the TLS-impersonation step has actually failed, not as a default
habit — and check which account that browser profile is actually logged
into first, since the cookies read are whatever's active at invocation time.
Nothing is persisted by the skill; the cookies are read once, for that one
command.

## Platform Terms of Service

Downloading video or audio — not just reading captions — from YouTube or
Vimeo touches those platforms' Terms of Service, and whether it's permitted
depends on the platform and how the result is used. Most conference
organizers explicitly allow derivative write-ups and screenshots of their
own published recordings, but that's not universal. Check the conference's
own recording/reuse policy before **publishing**, not just before
downloading — downloading a transcript to draft with is a different act
than shipping screenshots of someone's slides to the public internet.

## Publishing personal photos, transcripts, and quotes

Conference photos taken from the audience can include identifiable
bystanders, not just the speaker on stage — crop them out or get consent
before a photo goes into a published page. Attributing every quote to its
speaker and linking it back to the exact source timestamp (the convention
this skill uses throughout) does double duty as attribution, not just
verifiability for the reader. Whatever site you publish to should have some
way for someone to ask for a correction or takedown — an email address or an
issue link in the footer is enough.

## GitHub credentials and repo visibility

The publishing phase assumes `gh auth login` is already done, and defaults
to creating the repository with `--public`. Treat that as a decision to make
each time, not a rubber stamp — swap in `--private` if the material isn't
ready to be public yet. The GitHub Pages configuration call and the deploy
workflow's `contents: write` permission are both scoped to that one
repository; nothing broader is needed, and no extra secrets are involved
beyond your existing `gh` authentication.
