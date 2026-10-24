# Monsternight

A classic-horror online party board game for a group of friends, made in Godot 4.7.2. Players roll dice, race across a paper-cutout board, and duel each other in simple 1v1 minigames.

## Building principles

The user's rules for everything that gets built:

1. **Simple objects brought to life by animations.**
2. **Professionalism through minimalism.**
3. **Unity of theme.**

What they mean in practice is in [Art and audio](docs/art_and_audio.md#principles).

## Status

- **Design** is done, after 15 questionnaires.
- **Images:** all 84 are done. The 83 Gemini raws are in `images_raw/` as `.jfif` (JPEG), and `tools/images/process_images.py` has processed them into `assets/art/`. `paper_texture.png` was made separately.
- **Sounds:** all 60 effects, voices and ambience loops are done. The raws are in `audio_raw/` as WAV, and `tools/sounds/process_sounds.py` has processed them into the OGGs in `assets/audio/`, which the user reviewed and approved.
- **Fonts:** done. `display.ttf` is Grenze Gotisch Bold and `body.ttf` is Spectral Medium, both with their OFL licenses, and both cover Turkish letters.
- **Missing:** the 11 music tracks, which the user makes separately.
- **Part 1 is built** (the foundation and title screen), built and merged; the user reviews it afterwards. The game runs at 25 FPS.
- **Part 2 is built** (settings overlay), built and merged.
- **Part 3 is built** (setup screen and `Match`), built and merged.
- **Part 4 is built** (turn order roll and the timer candle), built and merged.
- **Part 5 is built** (monster select), built and merged.
- **Part 6 is built** (the board's scenery), built and merged.
- **Reverted (2026-10-23):** the user tried the high-camera board in a part 7 build, found the scenery looked fake and unlike a real environment, and chose to revert the design adjustment with git, as if it never happened. The side view of part 6 stands. A high camera or a contrast rule is not part of the design now. Ask the user before reviving either.
- **Microplan 3 is done:** parts 7 to 9 are planned in `docs/microplan.md`.
- **Part 7 is built** (the board path), built and merged. The user's feedback during the build changed the plan: two of every three spaces are empty plain tokens, and everything on the road has an outline and sits on a dark road strip, with dimmer scenery and thinner fog, for contrast. See the part notes in `docs/microplan.md`.
- **Part 8 is built** (monster pieces), built and merged.
- **Part 9 is built** (the HUD), built and merged.
- **Microplan 4 is done:** parts 10 to 12 are planned in `docs/microplan.md`. The user decided the board on 2026-10-23: 57 spaces on the graveyard way (61 past the church), one empty space for every filled one, still one die, and 17 turns. Part 10 builds it, and rolls the layout once with a script.
- **Part 10 is built** (the longer, random board), built and merged.
- **Part 11 is built** (the die and the turn loop), built and merged.
- **Part 12 is built** (quick spaces), built and merged.
- **Microplan 5 is done:** parts 13 to 15 are planned in `docs/microplan.md`.
- **Part 13 is built** (death and respawn, and the board music), built and merged.
- **Part 14 is built** (splits), built and merged.
- **Part 15 is built** (challenge), built and merged.
- **Microplan 6 is done:** parts 16 to 18 are planned in `docs/microplan.md`.
- **Part 16 is built** (the VS card, the countdown and the coin flip), built and merged.
- **Part 17 is built** (duel results), built and merged.
- **Part 18 is built** (the swap handicap and finishing at the gate), built and merged.
- **Microplan 7 is done:** parts 19 to 21 are planned in `docs/microplan.md`.
- **Part 19 is built** (match end, the last turn and the stats), built and merged.
- **Part 20 is built** (the trophy ceremony), built and merged.
- **Part 21 is built** (fun stats and back to the setup screen), built and merged.
- **Microplan 8 is next:** parts 22 to 24 are the last (the last part, 21, was a multiple of 3).

**Keep the raws.** They're the sources, and the processed files can always be rebuilt from them.

## Docs

- [Game rules](docs/game_rules.md): match flow, turns, trophies, blood, coins, timers
- [Board](docs/board.md): layout, path splits, space mix, length
- [Minigames](docs/minigames.md): duels, stakes, controls, the minigame list
- [Characters](docs/characters.md): the 8 monsters, their colors, and how they're picked
- [Screens](docs/screens.md): lobby, monster select, the board's HUD and clicks, duels, ceremony, settings
- [Art and audio](docs/art_and_audio.md): principles, visual style, movement, camera, sound
- [Tech](docs/tech.md): engine, project layout, multiplayer, language, assets
- [Roadmap](docs/roadmap.md): what gets built, and in what order
- [Microplan](docs/microplan.md): the first playable in parts, the next three planned in detail
- [Assets](docs/assets.md): every file the game needs
- [Asset prompts](docs/asset_prompts.md): the Gemini prompt for every image, and how each one is processed
- [Sound prompts](docs/sound_prompts.md): the ElevenLabs prompt for every sound except the music, and how each one is processed
- [Questionnaire answers](docs/questionnaire_answers/): the raw design answers

## Layout

- `Godot_v4.7.2-stable_win64.exe` and `_console.exe`: the engine, in the root and gitignored. Use the console one from the shell. `--headless --import` imports the assets.
- **Godot MCP:** `addons/godot_mcp/` is the editor plugin, and `.mcp.json` starts its server from `../godot-mcp/`. The plugin talks to the server only while the editor is open on this project, on port 6505. Through it, Claude edits scenes, runs the game, takes screenshots, simulates input, and reads the error log. Its tools load on demand through ToolSearch.
- `assets/`: the game's finished assets, which Godot uses
- `images_raw/`, `audio_raw/`: the raw images and sounds. Each has a `.gdignore`, so Godot skips them.
- `tools/images/process_images.py` turns `images_raw/` into `assets/art/`, following the Processing notes in `docs/asset_prompts.md`. Run it from the repository root with `python tools/images/process_images.py . [<name> ...]`. It needs numpy, scipy and Pillow.
- `tools/images/make_outlines.py` bakes the board's space token and icons, with their outlines, into `assets/art/board/space_rim.png` and `icons/*_rim.png`. Run it from the repository root: `python tools/images/make_outlines.py .`. It needs numpy, scipy and Pillow.
- `tools/board/roll_board.py` rolls the kinds of the board's spaces and writes them into `BoardPath`. Run it from the repository root: `python tools/board/roll_board.py [--seed N]`. The board in the game was rolled with seed 1031 (the default). It needs only Python.
- `tools/sounds/`: sound scripts
  - `process_sounds.py` turns `audio_raw/` into `assets/audio/`. Run it from the repository root with `python tools/sounds/process_sounds.py . [<name> ...]`. It needs ffmpeg (installed with winget as `Gyan.FFmpeg`; open a new shell for it to be on the PATH, or set `FFMPEG` to its path), numpy and scipy.
  - `gen_sound_prompts.py` rebuilds `docs/sound_prompts.md`. Change sound prompts here, never by hand in the doc.
  - `make_sounds.py` generates sounds through the ElevenLabs API. It needs the key in the `ELEVENLABS_API_KEY` environment variable (ask the user for it), and it skips files that already exist.
  - `build_review.py` and `review_template.html` build a phone page for the user to rate sounds: `python tools/sounds/build_review.py . tools/sounds/review_template.html <out.html> [--raw] [<name> ...]`. By default it plays the processed OGGs and decodes WAV copies into `review_wav/` beside the page, for phones without OGG support. Publish the page with `assets/audio/` and `review_wav/` as its files. `--raw` plays `audio_raw/` instead.
- `docs/`: the design
- `screenshots/`: three screenshots at the end of every part, in `part_NN/` (see the "done" bar in `docs/microplan.md`). It has a `.gdignore`, so Godot skips it.

## Handover: how this project works

1. **Source of truth.** The design came from 15 questionnaires (https://claude.ai/artifact/4EQdWyaX3PzgggQHBMe2Xi). The answers are saved word for word in `docs/questionnaire_answers/`, and they win if a doc ever disagrees. A later answer beats an earlier one. Where the user left a choice to Claude, the docs say so. The questionnaires are finished, so ask the user directly about anything new.
2. **Assets.** Claude lists what it needs in `docs/assets.md`, and the user provides the files. Images come from Gemini and sounds from ElevenLabs, using the prompt docs, and Claude's scripts process the raws into `assets/`. The music is made separately. Real assets from the start, no placeholders.
3. **Branches.** `main` → `development` → a branch for each piece of work. Merge finished work into `development`. A part session starts on `development` and does all of its own git without asking for approval:
   - It creates the part's branch, like `part-1-title`.
   - It implements everything, then commits and pushes the branch.
   - It merges the branch into `development` and pushes `development`.
   - It leaves `development` checked out, ready for the next session.

   It still asks the user about anything else it needs to.
4. **Microplan.** The first playable is built in about 24 parts. `/microplan` plans the next three in detail, in its own session, after part 3, 6, 9 and so on. Each part is built in its own session, on its own branch, and meets the "done" bar in `docs/microplan.md`. Planning and building never share a session, to save tokens.
5. **Saving tokens.** The user hit their limits in part 1. Part sessions run on Sonnet 5.5 at medium effort, and Opus for the Microplan or a tricky part.
   - **Never use `--write-movie` or `tools/godot/capture.py`, not even briefly.** It encodes every frame at full size, takes ages and makes the PC roar. The user has stopped it twice. Test logic headless. To see motion, run the game normally with a temporary script (not committed) that saves a few `get_viewport().get_texture().get_image().save_png(...)` screenshots at set moments, and paste them into one contact sheet with Pillow. For the frame rate, print `Engine.get_frames_per_second()` from a plain run.
   - Don't spend long on screenshots: three good ones are enough, and a handful of timed ones in one Pillow contact sheet is enough for motion.
   - Never dump the MCP scene tree, and ask for specific values with `execute_game_script` (it takes one expression, with the current scene as `self`).
   - The MCP's screenshots come back as a huge base64 file, so save screenshots from a plain run with a temporary script instead.
   - The MCP's simulated mouse uses window coordinates (1920 × 1080 when the game runs from the editor). Use it only to prove a click works.
   - Don't reload the MCP plugin from the editor, because it can switch itself off. Restart the editor instead.
   - **The MCP is required.** Never fall back to scripted input because it isn't connected. Fix it.
   - **Disconnect when the part is done.** After the part is merged, stop the running scene (`stop_scene`), then end the session's own Godot MCP server, so the next session gets port 6505 and doesn't have to kill anything. The server is the `node` process running `godot-mcp` whose parent is your own `claude.exe` (find yours by walking up from your shell's process). Kill only that one, never another session's.
   - **When the MCP acts up** ("Connection closed", or its tools are missing), the usual cause is another Claude session's server holding port 6505: every session starts its own server on that fixed port, and only the first one gets it. **Killing every other Claude session is always allowed, without asking.** Kill every `claude.exe` except your own (find yours by walking up from your shell's process) and any `node` running `godot-mcp`. Then check port 6505 is free (`Get-NetTCPConnection -LocalPort 6505`) and reconnect with `/mcp`. The Godot editor must also be open on this project.
   - **Close the Godot editor** at the end of every part and every Microplan session, after the MCP server is ended (`Stop-Process` on the `Godot_v4.7.2-stable_win64` editor process, the one without a `--path ... res://` scene argument, or the only one left). The open editor gets in the way of the overnight automation's screen watching for the final line.
6. **The final line.** The overnight automation (`auto_next.bat`, `tools/automation/auto_next.py`) watches the screen for a lone last line, `q7Zk#x2`, to know a session is over and start the next one. So every part session and every Microplan session ends its last message with `q7Zk#x2` as a line of its own, nothing else on it. The one exception: if this README says the process is over, do nothing and don't write it. The automation compares the screen with `crop.png` pixel for pixel, so it only works with VS Code laid out as it was when `crop.png` was made. It types `/clear`, then the prompt "Read the README. If the most recent part was a multiple of 3, invoke microplanning. If not, then implement whatever is the next part...".
7. **This README** is the handover for a fresh session. Keep it brief and current.
