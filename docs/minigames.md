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

A normal duel is **one round**. A round ends at the **first point** and should take about **20 to 30 seconds**. There is **no time limit** (Q17).

If there's nobody to duel, the space acts as a coin space. With the early end (see [game_rules.md](game_rules.md#match)) there's always someone left, so this is only a fallback.

**Walking away** (the brief): when swap is the only valid stake against every opponent, the challenger may walk away instead. A "Walk away" button sits beside the stake cards, and the space then does nothing, like an empty one (Claude's call, Q18).

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
  - **Blood** is never allowed while Death has 1 blood, on either side (see [characters.md](characters.md#death)).
  - **Swap** is always allowed.
- **Swap handicap:** in a swap duel, the challenger has to win **3 rounds** before the opponent wins **1**. Dorian Gray needs only 1.
- Frankenstein's Monster loses nothing as the challenger, and Mr. Hyde gets an edge when he challenges. See [characters.md](characters.md#powers).
- Whoever loses their last drop of blood in a duel dies (see [game_rules.md](game_rules.md#blood-health)).
- Every duel win counts toward the "most minigames won" trophy, including swap duels.

### Absent players

A player who is away or disconnected simply doesn't send any input. The duel plays out anyway, and they'll most likely lose.

### Draws

If both players lose in the same frame (both out of the Sumo ring at once), the round is played again (Claude's call).

## Controls

- The board is played with the mouse (see [screens.md](screens.md#mouse-controls)). Minigames use the keyboard. No gamepads.
- Every minigame uses the **arrow keys** to move, plus three keys with fixed names. Not every game uses all of them:

| Key | Job |
|---|---|
| A | Action |
| S | Special |
| D | Dash |

- **The one-computer mode** puts two players on one keyboard, so it has two key sets. The minigame frame part picks them (Claude's call, Q18).

## Minigame list

The four games (the brief, Q17). Each has one table (Claude's call) and no music, only its sounds (Q17).

| Minigame | View | Keys | The first point is |
|---|---|---|---|
| Pong | From above | Up and down | the first goal |
| Sumo | From above | Arrows | pushing the other out of the ring |
| Head Soccer | From the side | Left and right, S to jump, D to kick | the first goal |
| Tug of War | From the side | S only | pulling the marker past your line |

### Pong

A paddle on the left and one on the right. The ball starts in the middle toward a random side and speeds up a little with every hit. Arrows only (Claude's call, Q17).

### Sumo

Two round pieces on a round ring, pushing each other with the arrow keys. A, S and D do nothing, the ring never shrinks, and nothing changes over time (Q17).

### Head Soccer

The user's "kafa topu". Each player is a big head with little feet, with one goal at each end and a bouncy ball. S jumps and D kicks. The ball doesn't speed up (Q17).

### Tug of War

A rope with a marker in the middle. Each S press pulls it your way, and pulling it past your line wins (Q17).

### Out

Haxball, the racing game, the first-person shooter, the sword fight, and Run n Dodge (Q17) are out. The board's duel spaces are now the four games (part 29).
