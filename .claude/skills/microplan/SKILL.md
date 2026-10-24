---
name: microplan
description: Plan the next three parts of Monsternight's final game in detail, and a rough roadmap to the end. Use only when the user types /microplan or asks for a Microplan.
---

# Microplan

The first playable was built in parts 1 to 24 and is done (its plan is archived in `docs/microplan_first_playable.md`). The final game ([docs/roadmap.md](../../../docs/roadmap.md#2-final-game)) goes on from part 25. Planning it all at once doesn't work, because things change as they get built. So a Microplan plans three parts at a time, carefully, and keeps a rough roadmap to the end.

The plan lives in `docs/microplan.md`. This skill is the only thing that rewrites its Parts, Roadmap and Log.

## Rules

- **Plan only.** A Microplan session never implements anything. Parts are built in their own sessions. Tokens matter.
- **Read only what you need.** Start with `README.md` and `docs/microplan.md`. Open design docs and code only for what the next three parts touch. The Part notes are there so that you don't have to reread the code. For code the final game's notes don't cover yet, the archived file's "Built so far" notes are the map.
- **The questionnaire answers win** if a doc disagrees with them, and so does the user's [final game brief](../../../docs/questionnaire_answers/final_game_brief.md) (see README).
- **Ask, don't guess.** If a design question comes up that the docs don't answer, ask the user before writing the plan.

## First run

Done: Microplan 9 (2026-10-24) started the final game and planned parts 25 to 27.

## Later runs

They happen after part 27, 30, 33 and so on is done. Let N be that part.

1. Read the Part notes since the last Microplan, and `git log development` since then. Look at code only where a note raises something.
2. Plan parts N+1, N+2 and N+3 in detail. Carry over leftovers and bugs from the notes. Splits (like 28a, 28b) are fine.
3. Revise the roadmap to the end. The end is looser each time: it may move from 44 down to 40 or up to 47. Say why it moved.
4. Replace the old detailed parts with the new ones: finished parts only need a line in the roadmap. Clear the Part notes you've absorbed, and keep the file short. When the first playable's code map is outdated in a place, carry the correct facts into this file's Part notes.

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
3. Give the user a short summary (the three parts in a line each, and any roadmap changes). After they approve, commit `docs/microplan.md`, `README.md` and any other doc the session changed to `development`.
