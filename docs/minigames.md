# Minigames

## Philosophy

Minigames are very simple games people already know, dressed up in the horror theme. Familiar games are fun from the start. "Shitty" is the intended standard: a crude but working version of the genre is the target.

They keep the paper cutout look, like Pong played with cardboard paddles and a paper ball on a painted table. See [art_and_audio.md](art_and_audio.md#visual-style).

## Duels

Every minigame is a **1v1 duel**.

1. A player lands on a minigame space. Each minigame has its own space.
2. They challenge **any** other player who hasn't finished. The challenged player can't refuse.
3. They choose the stake (below). Picking the opponent and the stake share one 20-second timer.
4. The two players play that space's minigame. Everyone else watches. There is no text chat.

A normal duel is **one round**. A round ends at the **first point** and takes about **20 to 30 seconds**. Each game should push toward that first point (the Pong ball speeds up, for example) so rounds stay short.

If there's nobody to duel, the space acts as a coin space. With the early end (see [game_rules.md](game_rules.md#match)) there's always someone left, so this is only a fallback.

How a duel opens and closes is in [screens.md](screens.md#duels).

### Stakes

| Stake | If the challenger wins | If the challenger loses |
|---|---|---|
| Gold | Takes 1 coin from the opponent | Pays 1 coin to the opponent |
| Blood | Opponent loses 1 blood | Challenger loses 1 blood |
| Swap | Challenger and opponent swap places | Nothing happens |

- **Invalid stakes are greyed out** and can't be picked. Every rule applies to both players, the challenger included:
  - **Gold** needs both players to have at least 1 coin.
  - **Blood** against a player with 1 blood is a **death match**. It's only allowed if that player has **0 coins**. A challenger with 1 blood counts too.
  - **Swap** is always allowed.
- **Swap handicap:** in a swap duel, the challenger has to win **3 rounds** before the opponent wins **1**.
- Whoever loses their last drop of blood in a duel dies (see [game_rules.md](game_rules.md#blood-health)).
- Every duel win counts toward the "most minigames won" trophy, including swap duels.

### Absent players

A player who is AFK or disconnected simply doesn't send any input. The duel plays out anyway, and they'll most likely lose.

## Controls

- The board is played with the mouse (see [screens.md](screens.md#mouse-controls)). Minigames use the keyboard. No gamepads.
- Every minigame uses the **arrow keys** to move, plus three keys that do the same job in every game:

| Key | Job |
|---|---|
| A | Action |
| S | Special |
| D | Dash |

- **The FPS** is the exception: mouse to aim and shoot, WASD to move.

## Minigame list

| Minigame | The first point is | Status |
|---|---|---|
| Pong | the first goal | In |
| Haxball | the first goal | In |
| Racing game | crossing the finish line first | Wanted |
| First-person shooter | the first kill | Wanted |
| Sword-fighting game | a fight to the death (no first point) | Wanted, on hold |

More can be added later. Other candidates that were suggested but not picked: air hockey, Tron light cycles, Snake, Bomberman, a tank battle, sumo, a quickdraw, a Flappy Bird race, tug of war, a typing race, Connect Four, memory, and top-down racing.

Until a minigame is built, a duel on its space is settled by a **coin flip**. That's how every duel works in the [first playable](roadmap.md).

## Open questions

- How does the sword fight to the death play (hit points, blocking, round length)? The user shelved this in Q15.
- Does each minigame have one arena, or a few picked at random? Asked in Q14, not answered.
