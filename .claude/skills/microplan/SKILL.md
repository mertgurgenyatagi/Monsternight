---
name: microplan
description: Plan the next three parts of Monsternight's first playable in detail, and a rough roadmap to the end. Use only when the user types /microplan or asks for a Microplan.
---

# Microplan

The first playable ([docs/roadmap.md](../../../docs/roadmap.md#1-first-playable)) is built in about 24 parts. Planning it all at once doesn't work, because things change as they get built. So a Microplan plans three parts at a time, carefully, and keeps a rough roadmap to the end.

The plan lives in `docs/microplan.md`. This skill is the only thing that rewrites its Parts, Roadmap and Log.

## Rules

- **Plan only.** A Microplan session never implements anything. Parts are built in their own sessions. Tokens matter.
- **Read only what you need.** Start with `README.md` and `docs/microplan.md`. Open design docs and code only for what the next three parts touch. The Part notes are there so that you don't have to reread the code.
- **The questionnaire answers win** if a doc disagrees with them (see README).
- **Ask, don't guess.** If a design question comes up that the docs don't answer, ask the user before writing the plan.

## First run

The Parts section is empty.

1. Read the first playable in `docs/roadmap.md`, plus the docs it depends on.
2. Plan parts 1, 2 and 3 in detail (see below).
3. Sketch the roadmap for parts 4 to 24: one line per part. This is very rough.

## Later runs

They happen after part 3, 6, 9 and so on is done. Let N be that part.

1. Read the Part notes since the last Microplan, and `git log development` since then. Look at code only where a note raises something.
2. Plan parts N+1, N+2 and N+3 in detail. Carry over leftovers and bugs from the notes. Splits (like 5a, 5b) are fine.
3. Revise the roadmap to the end. The end is looser each time: it may move from 24 down to 20 or up to 27. Say why it moved.
4. Replace the old detailed parts with the new ones: finished parts only need a line in the roadmap. Clear the Part notes you've absorbed, and keep the file short.

## How detailed a planned part is

Not code-level, but enough that a fresh session can build it without re-deciding things:

- **Goal:** what the player can see or do when it's done, in one or two sentences.
- **Builds:** the scenes, scripts and systems it adds or changes.
- **Polish:** every animation, sound, transition and small detail it needs, named one by one. This is where the love goes. Follow the building principles in `docs/art_and_audio.md#principles`.
- **Assets:** which files from `assets/` it uses, and any that are missing.
- **Check:** how to prove it works by running the game.
- **Risks / open questions**, if any.

## Finish

1. Add a Log entry: the date, which parts were planned, and what changed in the roadmap and why.
2. Update the README's Status "Next" line to point at the next part.
3. Give the user a short summary (the three parts in a line each, and any roadmap changes). After they approve, commit `docs/microplan.md` and `README.md` to `development`.
