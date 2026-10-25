# Tech

## Engine

- **Godot 4.7.2**
- Development is AI-assisted ("vibe coding"). A single developer leads it.
- The Godot project lives at the root of the repository, and assets go in `assets/`.
- The game is made for a 1920 × 1080 screen and scaled to fit.
- **The whole game runs at 25 FPS** (`application/run/max_fps`), for a stop-motion feel. Write motion for that rate, and record movies with `--fixed-fps 25`.

## Multiplayer

The brief settled the host: **itch.io, in the browser**. The user left the rest to Claude (part 25), and these are Claude's calls:

- **Browser only.** Players open the itch.io page and play there, with nothing to install. No Windows download is made for players. The one-computer mode lives inside the same game (see [screens.md](screens.md#lobby)).
- **The web build:** the project already uses the Compatibility renderer, which is the one that runs in browsers. Export it without threads, so itch.io needs no special settings.
- **The relay:** browsers can't connect to each other on their own, so every message goes through a small program on **Cloudflare Workers**, with one Durable Object per room, over WebSockets (Godot's `WebSocketMultiplayerPeer` works in the browser). The user makes a free Cloudflare account once, when it's built. The free plan allows 100,000 requests a day, and incoming WebSocket messages count 20 to 1, which is far more than a few matches a day. Use the WebSocket Hibernation API, so idle rooms cost nothing. The delay from Turkish cities should be about 30 to 60 ms (an estimate, to be measured). Peer to peer over WebRTC was turned down: faster, but more work, and some home networks need a paid relay anyway.
- **Spike result (part 32):** the protocol is our own JSON over a plain `WebSocketPeer` (relay in `tools/relay/`, see the part 32 notes in [microplan.md](microplan.md)). The web export without threads is about 74 MB (34 MB pck, 39.5 MB wasm), about 44 MB gzipped, and the title is ready in about 5 s on localhost. The Godot web export templates install with only the `web_nothreads` zips.
- Each player runs their own copy of the game. **The host's game runs the rules** and sends the results to everyone; the others send only their clicks and keys, and draw what the host sends. Anyone can host.
- The players live in different cities in Turkey.
- **A duel is a few messages, not a stream** (part 46). The host decides the question (`decided`), each duelist's copy sends its number only to the host (`shot_lock`), the host tells everyone who has locked (`shot_status`, never the number) and, when both have or 30 s plus 1 s of grace have passed, sends the answers (`shot_reveal`). Every copy then runs the same reveal and `ShotGame.judge`. Nothing real-time crosses the relay, which is what a free relay can carry. A duelist who is the host knows both numbers on their own computer (accepted: it is not hidden from their own client). A dropped or away duelist has no answer and holds the host up for 3 s at most; if the host leaves, a duelist's copy sends its locked number again to the new host, which restarts the clock with what is left (2 s at least).
- **Decisions have timers.** When one runs out, a random valid choice is made (see [game_rules.md](game_rules.md#decision-timers)). This also covers disconnected and away players.
- **Rejoining:** a player who drops or reloads keeps their seat, and gets it back by opening the room's link again. Until then, the timers play for them.
- **If the host drops,** everyone waits up to a minute for them to come back. If they don't, the match ends.
- **Testing:** two browser tabs on one computer are enough to build it. Two friends test once the board works online, and the whole group at the playtest part. Ask the user who and when, at that point.
- Keep the match state in one place and change it only through the rules code, as the first playable does.

## Language

- English only for now.
- Build it so other languages are easy to add: keep every player-facing string out of the code, using Godot's translation system.

## Input

The board is all mouse clicks, and Shot in the Dark uses the keyboard or its paper keypad. See [screens.md](screens.md#mouse-controls) and [minigames.md](minigames.md#controls).

## Assets

- Claude lists every asset in [assets.md](assets.md), with its file name, what it shows, a rough size, and its format. The user drops the files into `assets/` under those names, and Claude wires them in.
- Images are PNG with transparency. Sounds are OGG.
- Claude doesn't need to worry about where assets come from. Real assets are used from the start.

## Building a release

Players get the web build (above). The Windows release below stays for testing. The development project carries the Godot MCP (its plugin and the autoloads `MCPRuntimeBridge`, `MCPInputBridge` and `MCPScreenshotBridge`), which must not ship. `python tools/release/build_release.py [<out_dir>]`, run from the repository root, copies only `assets/`, `src/`, `locale/`, the bus layout and the project files into a scratch folder, cuts the MCP out of that copy's `project.godot`, imports it and exports the "Windows Desktop" preset of `export_presets.cfg` (`<out_dir>`, `build/` by default, gets one `Monsternight.exe` with the pack embedded). The preset also excludes `addons/godot_mcp`, `screenshots`, the raws, `tools` and `docs`. It needs the Godot 4.7.2 export templates installed (Editor > Manage Export Templates), and `--stage <empty_dir>` makes just the stripped copy to test. The window title is the project name and the icon is `moon.png`.

## Online deploy (part 42)

- **Relay:** `tools/relay/deploy.md` has the steps; not deployed yet (not logged in to Cloudflare). Local round trip through the relay: median 5.8 ms, p95 9.1 ms (200 samples); the real one is not measured.
- **Free plan (estimate, unmeasured):** a night of 8 players for 2 hours sends about 3 messages per duel, a few thousand for the night. Incoming WebSocket messages count 20 to 1 as requests, so well under 1,000 requests against the 100,000 a day. Rooms hibernate when quiet. Well inside the plan.
- **Web build:** `python tools/release/build_release.py --web` (zip for itch.io), `--web --debug` for browser tests. `web/shell.html` is the loading page. Release builds ignore `?bot`, `?turns` and `?group` (`?group=atlas|archive|lab|stage` makes every landing a duel of that category). The staging copy keeps `data/`, where the questions are.
- **Links on itch:** the iframe's address is not shareable, so `Net.PAGE_URL` is the page address Copy link uses. Whether itch forwards `?room=` to the iframe is untested; if not, a joiner types the code.
