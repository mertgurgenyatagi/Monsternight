# itch.io page

- **Build:** `python tools/release/build_release.py --web` makes `build/monsternight_web.zip` (index.html at the top, 9 files, 72.4 MB, zip 42.0 MB; itch limits: files under 200 MB, at most 1000). Upload it with the web upload or `butler push` (the user's step), kind "HTML", "This file will be played in the browser".
- **Embed:** 1920 x 1080, fullscreen button on.
- **Title:** Monsternight
- **One-liner:** A classic-horror online party board game for 3 to 8 friends, with paper-cutout monsters and duels.
- **Description:** Roll the dice, race across a paper-cutout board and duel in Shot in the Dark: a number question, both players guess in secret, the closest wins. Each monster has a power. Play online in the browser, or on one screen.
- **Tags:** party game, local multiplayer, online multiplayer, Halloween, paper, board game
- **Controls:** the board is played with the mouse; Shot in the Dark uses the keyboard (digits, minus, decimal mark, Enter) or its paper keypad.
- **Cover (630 x 500) and thumbnail (315 x 250):** the user makes them by hand, prompts in `docs/asset_prompts.md`.
- Test builds: `--web --debug` keeps `?bot`, `?turns`, `?group` (release builds ignore them).
