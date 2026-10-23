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
- **No code yet.**
- **Next:** [part 1](docs/microplan.md#part-1-foundation-and-title-screen) of the first playable, in its own session.

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

- `Godot_v4.7.2-stable_win64.exe` and `_console.exe`: the engine, in the root and gitignored. Use the console one from the shell. `--headless --import` imports the assets. `--write-movie <dir>/f.png --fixed-fps 30 --quit-after <frames>` runs the game and saves every frame as a PNG, plus the audio as a WAV, so Claude can check the motion frame by frame.
- **Godot MCP:** `addons/godot_mcp/` is the editor plugin, and `.mcp.json` starts its server from `../godot-mcp/`. The plugin talks to the server only while the editor is open on this project, on port 6505. Through it, Claude edits scenes, runs the game, takes screenshots, simulates input, and reads the error log. Its tools load on demand through ToolSearch.
- `assets/`: the game's finished assets, which Godot uses
- `images_raw/`, `audio_raw/`: the raw images and sounds. Each has a `.gdignore`, so Godot skips them.
- `tools/images/process_images.py` turns `images_raw/` into `assets/art/`, following the Processing notes in `docs/asset_prompts.md`. Run it from the repository root with `python tools/images/process_images.py . [<name> ...]`. It needs numpy, scipy and Pillow.
- `tools/sounds/`: sound scripts
  - `process_sounds.py` turns `audio_raw/` into `assets/audio/`. Run it from the repository root with `python tools/sounds/process_sounds.py . [<name> ...]`. It needs ffmpeg (installed with winget as `Gyan.FFmpeg`; open a new shell for it to be on the PATH, or set `FFMPEG` to its path), numpy and scipy.
  - `gen_sound_prompts.py` rebuilds `docs/sound_prompts.md`. Change sound prompts here, never by hand in the doc.
  - `make_sounds.py` generates sounds through the ElevenLabs API. It needs the key in the `ELEVENLABS_API_KEY` environment variable (ask the user for it), and it skips files that already exist.
  - `build_review.py` and `review_template.html` build a phone page for the user to rate sounds: `python tools/sounds/build_review.py . tools/sounds/review_template.html <out.html> [--raw] [<name> ...]`. By default it plays the processed OGGs and decodes WAV copies into `review_wav/` beside the page, for phones without OGG support. Publish the page with `assets/audio/` and `review_wav/` as its files. `--raw` plays `audio_raw/` instead.
- `docs/`: the design

## Handover: how this project works

1. **Source of truth.** The design came from 15 questionnaires (https://claude.ai/artifact/4EQdWyaX3PzgggQHBMe2Xi). The answers are saved word for word in `docs/questionnaire_answers/`, and they win if a doc ever disagrees. A later answer beats an earlier one. Where the user left a choice to Claude, the docs say so. The questionnaires are finished, so ask the user directly about anything new.
2. **Assets.** Claude lists what it needs in `docs/assets.md`, and the user provides the files. Images come from Gemini and sounds from ElevenLabs, using the prompt docs, and Claude's scripts process the raws into `assets/`. The music is made separately. Real assets from the start, no placeholders.
3. **Branches.** `main` → `development` → a branch for each piece of work. Merge finished work into `development`. A part session starts on `development` and does all of its own git without asking for approval:
   - It creates the part's branch, like `part-1-title`.
   - It implements everything, then commits and pushes the branch.
   - It merges the branch into `development` and pushes `development`.

   It still asks the user about anything else it needs to.
4. **Microplan.** The first playable is built in about 24 parts. `/microplan` plans the next three in detail, in its own session, after part 3, 6, 9 and so on. Each part is built in its own session, on its own branch, and meets the "done" bar in `docs/microplan.md`. Planning and building never share a session, to save tokens.
5. **This README** is the handover for a fresh session. Keep it brief and current.
