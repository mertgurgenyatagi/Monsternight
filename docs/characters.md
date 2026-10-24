# Characters

There are 8 playable classic horror monsters. Each one has its own color, which marks its player everywhere: the portrait frame, the board piece, and so on. The user decided that colors come from the monster (Q14). Claude picked the colors.

| Monster | Color | Power |
|---|---|---|
| Dracula | Red | Landing steals 1 blood from each player nearby |
| Medusa | Green | Players nearby when she lands miss their next turn |
| Frankenstein's Monster | Yellow | Loses nothing as the challenger |
| Death (Grim Reaper) | Violet | Can't be killed |
| Mr. Hyde | Orange | An edge in every duel he starts |
| Cthulhu | Teal | Starts with 4 blood and 1 coin, and 4 is the cap |
| The Wolf Man | Blue | +1 to every roll |
| Dorian Gray | Pink | Wins a swap duel with 1 win instead of 3 |

## Selection

- Each monster can only be picked once per match. Monsters that are already taken are greyed out.
- Players pick in reverse turn order, so the player who moves last picks first.
- Each player has 30 seconds to pick. If time runs out, a random monster is picked.

## Powers

The user set the eight powers in the brief, and Hyde's edge in Q16. The details below were left to Claude (Q16).

### Nearby

Dracula's and Medusa's powers reach the space they land on, one space behind it, and one space ahead, **following the road**:

- At a fork, "ahead" is the first space of both paths, and where the paths join, "behind" is the last space of both.
- Only a landing from a roll counts. Being moved by a swap is not a landing.
- Players who have finished, and players still on the start, are safe.
- The power fires first, then the space they landed on.

### Dracula

- Each player nearby with 2 or more blood loses 1, and Dracula gains 1 for each, up to 3.
- The steal happens even when Dracula is at full blood: the victims lose, and Dracula stays at 3.
- Players with 1 blood are safe (the brief).

### Medusa

- Each player nearby misses their next turn. Their piece turns to grey stone, and on their turn it cracks back with a sound and the turn passes on.
- A player who just missed a turn is safe from the stone until they've moved once, so nobody misses two turns in a row.
- A stone player can still be challenged to duels as usual.

### Frankenstein's Monster

- Losing a duel as the challenger costs nothing: no coin, no blood, not even the last drop in a death match.
- The stake rules don't change, and a lost duel still counts as a loss in the fun stats.
- As the one challenged, Frankenstein's Monster wins and loses like anyone.

### Death

- Death's blood never drops below 1. Spikes at 1 blood do nothing.
- A blood stake is greyed out whenever Death has 1 blood, as the challenger or the one challenged.
- Death earns and loses gold like everyone else (the brief).

### Mr. Hyde

Only when he is the challenger (Q16):

| Minigame | Hyde's edge |
|---|---|
| Pong | A very slightly faster paddle |
| Sumo | Slightly faster and heavier |
| Head Soccer | Slightly faster |
| Tug of War | A slightly stronger pull |

Each minigame's part tunes the numbers, starting at about 10%.

### Cthulhu

- Starts with 4 blood and 1 coin. Blood can't go above 4: the church heals up to 4.
- A respawn comes back with 4 blood, but no extra coin.
- Gold has no cap.

### The Wolf Man

- Every roll gets +1, so he moves 2 to 7. The die shows its face, and a "+1" pops beside it.

### Dorian Gray

- In a swap duel Dorian Gray starts, 1 win is enough instead of 3. Challenged to a swap, the challenger still needs 3.

## Learning the powers

- In monster select, every monster's name always shows under its stand. Clicking a monster selects it (it lifts) and writes its power on the screen in one short line (the table's wording); a Confirm button, greyed out until something is selected, picks it. When the candle runs out the selected monster is picked, or a random one if none is.
- When a power fires on the board, a small word pops over the piece with a sound: "+1" by the Wolf Man's die, "Stone!" over Medusa's victims, and so on. Dracula's drain and Medusa's gaze also shoot a paper wedge in the monster's color from them to each victim.
- Every gain or loss of blood or coins, from a space, a duel or a power, shows as a tag over the piece, like "-1" with a blood drop, red for a loss and green for a gain. Medusa's victims get "-1 turn".
- There is no list of the powers anywhere else.
