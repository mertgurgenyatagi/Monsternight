# Tech

## Engine

- **Godot 4.7.2**
- Development is AI-assisted ("vibe coding"). A single developer leads it.
- The Godot project lives at the root of the repository, and assets go in `assets/`.
- The game is made for a 1920 × 1080 screen and scaled to fit.

## Multiplayer

- Each player runs their own copy of the game. One player hosts and the others join. Anyone can host.
- The players live in different cities in Turkey.
- Duels are real-time 1v1 games, and everyone else watches them live.
- **Decisions have timers.** When one runs out, a random valid choice is made (see [game_rules.md](game_rules.md#decision-timers)). This also covers disconnected and AFK players.
- **If the host drops, the match ends.** This is accepted.
- **Online play is built last** (Q15). How players connect is still open. The options are port forwarding, a VPN tool like ZeroTier or Radmin VPN, or a browser build on itch.io (which needs a relay server).
- The first playable doesn't depend on that choice. Keep the match state in one place and change it only through the rules code. Later, the host can run the rules and send the results to everyone.

## Language

- English only for now.
- Build it so other languages are easy to add: keep every player-facing string out of the code, using Godot's translation system.

## Input

The board is all mouse clicks, and minigames use the keyboard. See [screens.md](screens.md#mouse-controls) and [minigames.md](minigames.md#controls).

## Assets

- Claude lists every asset in [assets.md](assets.md), with its file name, what it shows, a rough size, and its format. The user drops the files into `assets/` under those names, and Claude wires them in.
- Images are PNG with transparency. Sounds are OGG.
- Claude doesn't need to worry about where assets come from. Real assets are used from the start.

## Open questions

- How do players connect online? This gets decided when online play is built.
