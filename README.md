# Monsternight

A classic-horror online party board game for a group of friends, made in Godot 4.7.2. Players roll dice, race across a paper-cutout board, and duel each other in simple 1v1 minigames.

## Building principles

The user's rules for everything that gets built:

1. **Simple objects brought to life by animations.**
2. **Professionalism through minimalism.**
3. **Unity of theme.**

What they mean in practice is in [Art and audio](docs/art_and_audio.md#principles).

## Status

- **Design: done.** The first playable's design came from 15 questionnaires, and the final game's from the user's brief and questionnaires 16 to 18 (part 25). The user then ended the questionnaires and left the rest, online play included, to Claude. The docs mark Claude's calls.
- **Images:** all 94 are done (the first playable's 84, and 10 for the final game from part 26). The 83 Gemini raws are in `images_raw/` as `.jfif` (JPEG), and `tools/images/process_images.py` has processed them into `assets/art/`. `paper_texture.png` was made separately.
- **Sounds:** all 74 effects, voices and ambience loops are done (60, and 14 for the final game from part 26). The raws are in `audio_raw/` as WAV, and `tools/sounds/process_sounds.py` has processed them into the OGGs in `assets/audio/`, which the user reviewed and approved.
- **Fonts:** done. `display.ttf` is Grenze Gotisch Bold and `body.ttf` is Spectral Medium, both with their OFL licenses, and both cover Turkish letters.
- **Missing:** the 11 music tracks, which the user makes separately.
- **The first playable is done** (parts 1 to 24, 2026-10-23 to 24): a whole local match, one person clicking for everyone, with the real assets and coin-flip duels. It runs at 25 FPS. Its plan and notes are archived in `docs/microplan_first_playable.md`, and the notes are the map of the code. The release script `tools/release/build_release.py` and `export_presets.cfg` are ready, but the Godot export templates are not installed, so nothing has been exported yet (see `docs/tech.md`).
- **The camera:** a high camera was tried in part 7 and reverted, because the scenery looked fake. On 2026-10-24 the user asked for a slight zoom out and a slightly higher angle, and part 27 did it (zoom 0.88, a slightly raised horizon): `BoardCamera.ZOOM` is the one number to retune, and 1.0 undoes the zoom.
- **The final game started on 2026-10-24:** 3 to 8 players, a power for each monster, four minigames (Pong, Sumo, Head Soccer, Tug of War), and online play in the browser on itch.io. Microplan 9 planned parts 25 to 27 in `docs/microplan.md`.
- **Part 25 is done:** the questionnaires, and the docs updated for the final game.
- **Part 26 is done:** the final game's 10 images and 14 sounds, made and approved (`docs/assets.md`).
- **Part 27 is done:** the camera tweak, waiting for the user's verdict on the before-and-after sheet (`screenshots/part_27/1.png`).
- **Microplan 10 is done:** parts 28 to 30 are planned in `docs/microplan.md` (the lobby-size rules, the board for each lobby size, the passive powers). The roadmap now ends at part 43.
- **Part 28 is done:** the lobby-size rules (turns by lobby size, one finishing trophy, Walk away on swap-only duels). Notes in `docs/microplan.md`.
- **Next: part 29,** the board for each lobby size.

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
- [Microplan](docs/microplan.md): the final game in parts, the next three planned in detail
- [First playable's microplan](docs/microplan_first_playable.md): parts 1 to 24, archived, and the map of the code
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
- `tools/release/build_release.py` builds the Windows release without the Godot MCP (see `docs/tech.md`).
- `docs/`: the design
- `screenshots/`: three screenshots at the end of every part, in `part_NN/` (see the "done" bar in `docs/microplan.md`). It has a `.gdignore`, so Godot skips it.

## Handover: how this project works

1. **Source of truth.** The design came from 18 questionnaires (https://claude.ai/artifact/4EQdWyaX3PzgggQHBMe2Xi). The answers are saved word for word in `docs/questionnaire_answers/`, and they win if a doc ever disagrees. A later answer beats an earlier one. The user's final game brief (`final_game_brief.md` there) counts as an answer too. Where the user left a choice to Claude, the docs say so. Outside a questionnaire part, ask the user directly about anything new.
2. **Assets.** Claude lists what it needs in `docs/assets.md`, and the user provides the files. Images come from Gemini and sounds from ElevenLabs, using the prompt docs, and Claude's scripts process the raws into `assets/`. The music is made separately. Real assets from the start, no placeholders.
3. **Branches.** `main` → `development` → a branch for each piece of work. Merge finished work into `development`. A part session starts on `development` and does all of its own git without asking for approval:
   - It creates the part's branch, like `part-1-title`.
   - It implements everything, then commits and pushes the branch.
   - It merges the branch into `development` and pushes `development`.
   - It leaves `development` checked out, ready for the next session.

   It still asks the user about anything else it needs to.
4. **Microplan.** The first playable was built in parts 1 to 24. The final game goes on from part 25. `/microplan` plans the next three in detail, in its own session, after part 27, 30, 33 and so on. Each part is built in its own session, on its own branch, and meets the "done" bar in `docs/microplan.md`. Planning and building never share a session, to save tokens.
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
