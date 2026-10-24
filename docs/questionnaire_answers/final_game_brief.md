# Final game brief

The user's direction for the final game, pasted into chat on 2026-10-24 to start Microplan 9. Saved word for word. It wins over any doc that disagrees, until the questionnaires that follow it (16 on) refine it.

---

The first playable part is over. Now we move on to the next phase. This calls for another microplanning session, a new microplanning plan altogether.

1. The turn limits and map size will be different based on the size of the lobby.

lobby_size,turn_limit,average_of_longest_and_shortest_paths
3,20,65
4,17,60
5,15,55
6,14,51
7,13,48
8,12,46

we don't allow for 2 players.

2. The character powers are the following:

Dracula: When you land, any players that is either in the spot you land on, or is one behind or is one forward, you steal 1 hp from each. You cannot steal from anyone with 1 hp, and your hp cannot go above 3.
Medusa: When you land, any players that is either in the spot you land on, or is one behind or is one forward, they miss their next turn.
Frankenstein's Monster: You don't lose anything when you are the challenger.
Death: Cannot be killed.
Mr. Hyde: Duel advantage.
Cthulhu: +1 blood and +1 gold at start. cap is 4 for hp.
Wolfman: +1 to every roll.
Dorian Gray: Swap needs 1 win instead.

3. If only swap is available for a minigame, the challenger is able to not challenge.

4. Only the first place finisher gets a trophy, and they get a single trophy.

5. We will host on itch.io

6. We will have Pong, Sumo, "kafa topu", Tug of War (where you just mash "S"), Run n Dodge (where the players are in place with obstacles coming and they can only jump and duck)

7. 1 to 1 ratio of empty to filled. 1 to 1 ratio of non-minigame to minigame.

8. Zoom out slightly and raise the angle slightly. Make sure the existing assets play nice by it.

This will be the final game. If I missed anything, ask me about it. Make sure the first microplan step is about questionnaires and the second microplan step is about asset retrieval and the third one is also something not too committal, so we can adjust based on the next microplan invocation after part 3.

---

## Answers in chat, 2026-10-24

- **The third part:** the camera tweak.
- **Trophies:** the most-gold and most-duels-won trophies stay. Only the finishing trophies change: the first finisher gets 1, the second gets none.
- **Death:** "cannot be killed" only. Death earns gold like everyone else (unlike `tools/sim/powers_sim.py`, which also stopped Death's gold).
