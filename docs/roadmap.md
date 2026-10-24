# Roadmap

## 1. First playable

**Done** (parts 1 to 24, see [microplan_first_playable.md](microplan_first_playable.md)).

A local version for testing the board rules. **One person controls every player** with the mouse on one computer.

- Title screen and settings.
- A setup screen in place of the lobby: the number of players and their names.
- Turn order roll and monster select.
- Full board rules: blood, coins, the four quick spaces, both path splits, 17 turns, the early end, and the decision timers.
- Duels with an opponent and a stake chosen as normal, and the VS card. A **coin flip** decides the winner instead of a minigame.
- Trophy ceremony with fun stats, then back to the setup screen.
- **Real assets** from the start, no placeholders. See the [asset list](assets.md).
- No minigames, no abilities, no networking.

## 2. Final game

**In progress** (parts 25 on, see [microplan.md](microplan.md)). The user's [brief](questionnaire_answers/final_game_brief.md) of 2026-10-24 starts it, questionnaires 16 to 18 settled most of the rest, and Claude made the remaining calls. This is the last phase.

- **3 to 8 players.** The turn limit and the board's length depend on the lobby's size, from 20 turns and 65 spaces for 3 players down to 12 turns and 46 spaces for 8 (see [game_rules.md](game_rules.md#match) and [board.md](board.md#length)).
- **The board:** one empty space for every filled one, and one minigame space for every quick one, shuffled fresh every match.
- **Trophies:** the first finisher gets one, and nobody else gets a finishing trophy. The most-gold and most-duels-won trophies stay.
- **A challenger may walk away** when swap is the only valid stake.
- **Powers,** one for each monster (see [characters.md](characters.md#powers)).
- **Four minigames:** Pong, Sumo, Head Soccer and Tug of War (see [minigames.md](minigames.md#minigame-list)).
- **The camera** zooms out slightly and looks from slightly higher.
- **Online play in the browser, on itch.io,** through a Cloudflare relay (see [tech.md](tech.md#multiplayer)). The one-computer mode stays.
