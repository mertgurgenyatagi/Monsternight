# itch.io page

- **Build:** `python tools/release/build_release.py --web` makes `build/monsternight_web.zip` (index.html at the top, 9 files, 74.6 MB, zip 44.5 MB; itch limits: files under 200 MB, at most 1000). Upload it with the web upload or `butler push` (the user's step), kind "HTML", "This file will be played in the browser".
- **Embed:** 1920 x 1080, fullscreen button on.
- **Title:** Monsternight
- **One-liner:** A classic-horror online party board game for 3 to 8 friends, with paper-cutout monsters and duels.
- **Description:** Roll the dice, race across a paper-cutout board and duel in Pong, Sumo, Head Soccer and Tug of War. Each monster has a power. Play online in the browser, or on one screen.
- **Tags:** party game, local multiplayer, online multiplayer, Halloween, paper, board game
- **Controls:** left player WASD + Q E R, right player arrows + K L ;. The board is played with the mouse.
- **Cover (630 x 500) and thumbnail (315 x 250):** the user makes them by hand, prompts in `docs/asset_prompts.md`.
- Test builds: `--web --debug` keeps `?bot`, `?turns`, `?group` (release builds ignore them).
