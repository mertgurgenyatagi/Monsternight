"""Rolls the kinds of the board's spaces and writes them into src/board/board_path.gd.

Only the kinds are rolled. Each part of the road has a bag with exact counts, and the bag is
shuffled uniformly, with no other rule on the order. The stretch lengths, the forks and their
places are fixed in BoardPath and aren't touched. The same seed always gives the same board.

    python tools/board/roll_board.py [<repo root>] [--seed N]

Run it from the repository root. It changes only the `kinds` strings of BoardPath's STRETCHES.
The game never rolls the board at runtime, so every match and every online player has the same.
"""
import random
import re
import sys
from collections import Counter

DEFAULT_SEED = 1031
LETTERS = {"coin": "c", "spikes": "s", "thief": "t", "church": "h"}
MINIGAMES = ["p", "x", "r", "f"]  # pong, haxball, racing, the FPS
QUICK = ["c", "s", "t", "h"]

# The stretches of each bag, in road order, and how long each is.
MAIN = [("village", 12), ("forest", 12), ("castle", 15)]


def roll(rng):
    """Returns {stretch id: kinds string}, and the bags for the checks."""
    bags = {}

    # Main road: 39 spaces, 20 empty, one of each minigame, 15 quick (4 of each but one, 3).
    quick = QUICK * 4
    quick.remove(rng.choice(QUICK))
    bags["main"] = ["."] * 20 + MINIGAMES + quick

    # Church: 12 spaces, 6 empty, one minigame, 3 + 2 of church and coin, which way rolled.
    three, two = rng.sample(["h", "c"], 2)
    bags["church"] = ["."] * 6 + [rng.choice(MINIGAMES)] + [three] * 3 + [two] * 2

    # Graveyard: 8 spaces, 4 empty, 2 spikes, 2 thieves. No minigame.
    bags["graveyard"] = ["."] * 4 + ["s"] * 2 + ["t"] * 2

    # Boardwalk and bog: 10 spaces, 5 empty, the two minigames, and 3 quick of any kind.
    bags["boardwalk"] = ["."] * 5 + ["p", "x"] + [rng.choice(QUICK) for _ in range(3)]
    bags["bog"] = ["."] * 5 + ["r", "f"] + [rng.choice(QUICK) for _ in range(3)]

    for bag in bags.values():
        rng.shuffle(bag)

    kinds = {}
    taken = 0
    for stretch, length in MAIN:
        kinds[stretch] = "".join(bags["main"][taken:taken + length])
        taken += length
    for stretch in ["church", "graveyard", "boardwalk", "bog"]:
        kinds[stretch] = "".join(bags[stretch])
    return kinds


def check(kinds):
    """Every bag's counts came out exact."""
    main = Counter(kinds["village"] + kinds["forest"] + kinds["castle"])
    assert sum(main.values()) == 39 and main["."] == 20, main
    assert all(main[m] == 1 for m in MINIGAMES), main
    quick = sorted(main[q] for q in QUICK)
    assert quick == [3, 4, 4, 4], main
    church = Counter(kinds["church"])
    assert sum(church.values()) == 12 and church["."] == 6, church
    assert sum(church[m] for m in MINIGAMES) == 1, church
    assert sorted([church["h"], church["c"]]) == [2, 3] and church["s"] == church["t"] == 0, church
    graveyard = Counter(kinds["graveyard"])
    assert graveyard == Counter({".": 4, "s": 2, "t": 2}), graveyard
    for stretch, games in [("boardwalk", "px"), ("bog", "rf")]:
        counts = Counter(kinds[stretch])
        assert sum(counts.values()) == 10 and counts["."] == 5, counts
        assert all(counts[g] == 1 for g in games), counts
        assert sum(counts[q] for q in QUICK) == 3, counts


def main():
    args = sys.argv[1:]
    seed = DEFAULT_SEED
    if "--seed" in args:
        i = args.index("--seed")
        seed = int(args[i + 1])
        del args[i:i + 2]
    root = args[0] if args else "."
    path = root + "/src/board/board_path.gd"

    kinds = roll(random.Random(seed))
    check(kinds)

    with open(path, newline="") as f:
        text = f.read()
    for stretch, line in kinds.items():
        pattern = re.compile(r'("id": "%s",.*?"kinds": ")[^"]*(")' % stretch, re.DOTALL)
        text, count = pattern.subn(lambda m: m.group(1) + line + m.group(2), text, count=1)
        assert count == 1, stretch
    with open(path, "w", newline="") as f:
        f.write(text)

    print("seed", seed)
    for stretch, line in kinds.items():
        print("%-10s %2d  %s" % (stretch, len(line), line))
    graveyard_way = kinds["village"] + kinds["graveyard"] + kinds["forest"] + kinds["boardwalk"] + kinds["castle"]
    church_way = kinds["village"] + kinds["church"] + kinds["forest"] + kinds["boardwalk"] + kinds["castle"]
    for name, way in [("graveyard way", graveyard_way), ("church way", church_way)]:
        print("%s: %d spaces, %d empty, %d filled" % (name, len(way), way.count("."), len(way) - way.count(".")))


main()
