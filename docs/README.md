# Documents

Four documents, three audiences. They overlap in subject and not in purpose, so
the useful question is not "which is newest" but "which problem do you have".

| you want to | read |
|---|---|
| write or change an E2E scenario **here** | not a document — load the `e2e-nuevo-escenario` skill, and see `CLAUDE.md` |
| take this whole framework to another project | [`e2e-framework/transplant-prompt.md`](./e2e-framework/transplant-prompt.md) |
| introduce Patrol into an app already in production | [`prompt-migracion-patrol.md`](./prompt-migracion-patrol.md) |
| decide whether Patrol is worth its cost at all | [`e2e-handoff.md`](./e2e-handoff.md) |

## Why the last two still exist

They read like earlier drafts of the transplant prompt and they are not.

**`transplant-prompt.md`** assumes you are bringing everything — kit, reporter,
runners, CI — into a project where you may shape the app to fit. It is written
as one briefing, and most of its length is the traps this repo already paid
for.

**`prompt-migracion-patrol.md`** assumes the opposite: a mature application,
under active development, with a team and real users, where every change is a
liability. Hence the phases with a mandatory stop between them, and hence the
locator protocol — a long section on testing an app that has **no test keys**,
and on adding identifiers only after proving they were needed. None of that
appears in the transplant prompt, which assumes the keys are yours to add.

**`e2e-handoff.md`** is analysis rather than instructions: what Patrol's
footprint on an app actually is, split into what is irreducible, what this repo
has that nobody needs to copy, the risks in order, and what is not viable at
all. It answers the question the other two skip, because both of them start
from "you have decided to do this".

The overlap that remains is deliberate: each is meant to be read alone, by
somebody who does not have the other two.
