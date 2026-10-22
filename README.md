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
- **Images:** all 83 Gemini images are made and approved, in `images_raw/` as `.jfif` (JPEG). `paper_texture.png` is already finished in `assets/`.
- **Sounds:** all 60 effects, voices and ambience loops are made and approved, in `audio_raw/` as WAV.
- **Missing:** the 11 music tracks, which the user makes separately, and the 2 fonts.
- **No code yet.**
- **Next, on the `asset-processing` branch:** turn the raw files into the game's assets (see below).
- **After that:** build the [first playable](docs/roadmap.md#1-first-playable).

## Next: asset processing

Write scripts in `tools/` that turn the raw files into the files listed in [assets.md](docs/assets.md). The steps for each file are in its prompt doc.

- **Images:** read `images_raw/<name>.jfif` and write `assets/art/<folder>/<name>.png`. The folder and the processing line for each image are in [asset_prompts.md](docs/asset_prompts.md): remove the background, mirror where needed, fix the seams of tiling strips, and set the size. The raws are JPEGs, so the background color needs a tolerance and the edges need cleaning.
- **Sounds:** read `audio_raw/<folder>/<name>.wav` and write `assets/audio/<folder>/<name>.ogg`. The steps are in [sound_prompts.md](docs/sound_prompts.md#processing): trim, cut to length, join the thief's two parts, loop the ambience, even out loudness, and convert to mono OGG. This needs ffmpeg, which isn't installed. Ask the user before installing it.
- **Keep the raws.** They're the sources, and the processed files can always be rebuilt from them.

## Docs

- [Game rules](docs/game_rules.md): match flow, turns, trophies, blood, coins, timers
- [Board](docs/board.md): layout, path splits, space mix, length
- [Minigames](docs/minigames.md): duels, stakes, controls, the minigame list
- [Characters](docs/characters.md): the 8 monsters, their colors, and how they're picked
- [Screens](docs/screens.md): lobby, monster select, the board's HUD and clicks, duels, ceremony, settings
- [Art and audio](docs/art_and_audio.md): principles, visual style, movement, camera, sound
- [Tech](docs/tech.md): engine, project layout, multiplayer, language, assets
- [Roadmap](docs/roadmap.md): what gets built, and in what order
- [Assets](docs/assets.md): every file the game needs
- [Asset prompts](docs/asset_prompts.md): the Gemini prompt for every image, and how each one is processed
- [Sound prompts](docs/sound_prompts.md): the ElevenLabs prompt for every sound except the music, and how each one is processed
- [Questionnaire answers](docs/questionnaire_answers/): the raw design answers

## Layout

- `assets/`: the game's finished assets, which Godot uses
- `images_raw/`, `audio_raw/`: the raw images and sounds. Each has a `.gdignore`, so Godot skips them.
- `tools/sounds/`: sound scripts
  - `gen_sound_prompts.py` rebuilds `docs/sound_prompts.md`. Change sound prompts here, never by hand in the doc.
  - `make_sounds.py` generates sounds through the ElevenLabs API. It needs the key in the `ELEVENLABS_API_KEY` environment variable (ask the user for it), and it skips files that already exist.
  - `build_review.py` and `review_template.html` build a phone page for the user to rate sounds.
- `docs/`: the design

## Handover: how this project works

1. **Source of truth.** The design came from 15 questionnaires (https://claude.ai/artifact/4EQdWyaX3PzgggQHBMe2Xi). The answers are saved word for word in `docs/questionnaire_answers/`, and they win if a doc ever disagrees. A later answer beats an earlier one. Where the user left a choice to Claude, the docs say so. The questionnaires are finished, so ask the user directly about anything new.
2. **Assets.** Claude lists what it needs in `docs/assets.md`, and the user provides the files. Images come from Gemini and sounds from ElevenLabs, using the prompt docs, and Claude's scripts process the raws into `assets/`. The music is made separately. Real assets from the start, no placeholders.
3. **Branches.** `main` → `development` → a branch for each piece of work. Merge finished work into `development`.
4. **This README** is the handover for a fresh session. Keep it brief and current.
