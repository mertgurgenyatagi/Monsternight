# Minigames

There is one minigame: **Shot in the Dark** (Microplan 15, 2026-10-25). It replaced Pong, Sumo, Head Soccer and Tug of War, which the user threw out after playing 1.0.0: real-time games over a free relay do not work. The questions are in [`sitd_questions/`](../sitd_questions/) (the user's 1000), served from `data/questions.json`.

## Shot in the Dark

A question with a number for an answer ("How tall is the Eiffel Tower, in meters?"). Both players type a guess in secret and lock it in, the answer is revealed, and **the closest guess wins**.

- Each side has **20 seconds**, or until it locks in. A guess typed when the time runs out is locked as it is; no guess loses to any guess.
- **Typing:** digits, a minus (first only), one decimal mark (`.` or `,` both work), Backspace, Enter to lock. Up to 9 digits. A paper keypad does the same with the mouse. Numbers are shown with a thin space between thousands, and the decimal comma in Turkish.
- **The score:** the smaller `|guess - answer|` wins. **Mr. Hyde, when he starts the duel, has his distance multiplied by 0.8** ("20% closer"). An exact tie, or two blanks, is a draw.
- **A draw** asks a new question. A swap duel's round only counts when someone wins. After **3 draws in a row** the challenger loses, so a duel cannot hang.
- A match never asks the same question twice (`Match.asked`); a group that runs dry starts over.
- **One screen (pass the keyboard):** the challenger types first behind a cover card ("Name: look, the others look away" and an "I'm ready" button), then the cover passes to the opponent. Online, both type at once on their own computers (part 46).
- **Online, until part 46:** the host flips a fair coin for each round ("Fate decides").

### The four spaces

A minigame space shows a **category**, and the question comes from its group (`data/question_groups.json`):

| Space | Name | What it asks about |
|---|---|---|
| `atlas` | The Atlas | Places, transport, the sea, space, the Earth (210 questions) |
| `archive` | The Archive | History, art, books, languages, science, inventions, business (240) |
| `lab` | The Lab | Science, the body, animals, plants (220) |
| `stage` | The Stage | Cinema, TV, music, games, toys, the internet, sport, food (330) |

Their icons are by the user (`docs/asset_prompts.md`, "Category icons"). Until they arrive the game uses hue-shifted coin stand-ins.

## Duels

Every minigame is a **1v1 duel**.

1. A player lands on a minigame space.
2. They challenge **any** other player who hasn't finished. The challenged player can't refuse.
3. They choose the stake (below). Picking the opponent and the stake share one 20-second timer.
4. The two players play Shot in the Dark. Everyone else watches. There is no text chat.

If there's nobody to duel, the space acts as a coin space.

**Walking away** (the brief): when swap is the only valid stake against every opponent, the challenger may walk away instead. A "Walk away" button sits beside the stake cards, and the space then does nothing, like an empty one (Claude's call, Q18).

How a duel opens and closes is in [screens.md](screens.md#duels).

### Stakes

| Stake | If the challenger wins | If the challenger loses |
|---|---|---|
| Gold | Takes 1 coin from the opponent | Pays 1 coin to the opponent |
| Blood | Opponent loses 1 blood | Challenger loses 1 blood |
| Swap | Challenger and opponent swap places | Nothing happens |

(Part 47 changes the stakes to zero-sum, and the swap handicap to 2 wins before 1 loss.)

- **Invalid stakes are greyed out** and can't be picked. Every rule applies to both players, the challenger included:
  - **Gold** needs both players to have at least 1 coin.
  - **Blood** against a player with 1 blood is a **death match**. It's only allowed if that player has **0 coins**. A challenger with 1 blood counts too.
  - **Blood** is never allowed while Death has 1 blood, on either side (see [characters.md](characters.md#death)).
  - **Swap** is always allowed.
- **Swap handicap:** in a swap duel, the challenger has to win **3 rounds** before the opponent wins **1**. Dorian Gray needs only 1.
- Frankenstein's Monster loses nothing as the challenger, and Mr. Hyde's guess counts as closer when he challenges. See [characters.md](characters.md#powers).
- Whoever loses their last drop of blood in a duel dies (see [game_rules.md](game_rules.md#blood-health)).
- Every duel win counts toward the "most minigames won" trophy, including swap duels.

### Absent players

A player who is away or disconnected types nothing, so they have no guess and lose (online).

## Controls

The board is played with the mouse (see [screens.md](screens.md#mouse-controls)). Shot in the Dark uses the keyboard or the paper keypad. No gamepads.

## Out

Pong, Sumo, Head Soccer and Tug of War (parts 34 to 37, removed in part 45), Haxball, the racing game, the first-person shooter, the sword fight, and Run n Dodge.
