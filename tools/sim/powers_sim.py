"""Monte Carlo simulation of Monsternight matches with powers.

Plays hundreds of thousands of whole matches (3 to 6 players, one random power each, no repeats)
and reports how each power does: average placement, win rate, trophy rates and so on.

    python tools/sim/powers_sim.py [--matches N] [--seed N] [--map-seed N] [--csv out.csv] [--control-only]

Needs numpy and numba. The matches run in parallel on the CPU (see the notes at the bottom of
the file for why not the GPU). The same seed always gives the same result.

Rules come from docs/game_rules.md, docs/board.md and docs/minigames.md: 17 turns, one die, the
real board (its own rolled map, not the game's: 1:1 empty to filled, 1:1 quick to minigame; two forks), blood 3, gold 0,
duels settled by chance, the swap handicap, death, and trophies. The assumptions the docs and the
user's power list leave open are listed under ASSUMPTIONS below, and the knobs sit just under it.

ASSUMPTIONS
- Everything that is a choice is random (die timing, fork path, whom to challenge), except the
  stake, which is "clever": the challenger picks the valid stake with the best expected value
  (swap wants a target ahead, gold and blood weigh the odds, deaths count heavily).
- Duels are one round. The challenger wins 60/40; an advantage power adds its points (15 or 20)
  to its holder's chance, as challenger or defender; two holders cancel out.
- Power 15: +2 blood and +2 gold at start, max blood 5, plus +1 to rolls. "Can't earn gold" means
  every gold gain is 0 (coins, empty spaces, duel winnings); thieves and stakes can still take.
- Power 10 can't go below 1 blood from anything, spikes included. It still can't be staked at 1. A swap duel
  is won by the challenger with probability p ** wins_needed.
- The finish is a node after the last space, so a piece needs to step one past it (progress
  >= spaces + 1). Passing the finish with a big roll counts.
- Finished players sit out; they can't be challenged or hit or stunned, and keep their gold.
- Gold and minigame trophies need at least 1 gold / 1 win, and ties share them.
- Landing effects (stun, hit) fire before the space itself. A swap is not a landing.
- Gold multipliers apply to what the holder gains. The payer still pays the base amount.
- Power 14 works when the holder is the challenger: gold and blood stakes are 2, and the "valid
  stake" restrictions (both need 1 coin, death matches) are lifted. A player with power 6 at
  1 blood still can't be staked for blood.
- Power 16: when the holder is the challenger and loses, nothing is lost.
- Power 1 and 2: "both max" is read as max blood 4/5. Gold has no cap (set GOLD_CAP_BONUS_MAX to
  cap it too).
- TO BE IMPLEMENTED (rule change, not in the sim): if only swap is available as a stake, the
  challenger may choose not to challenge. In the sim the challenger still has to swap.
"""
import argparse
import re
import sys
import time
from pathlib import Path

import numpy as np
from numba import njit, prange

# ---- knobs ----------------------------------------------------------------------------------
TURNS = 17
BASE_BLOOD = 3
ROUND_ODDS = 0.55         # chance the challenger wins one round (55 / 45 for the challenger)
SWAP_WINS_DEFAULT = 3
GOLD_CAP_BONUS_MAX = False  # True: powers 1 and 2 also cap gold at their max blood (4 / 5)
# Value of one thing in "spaces", only used by the clever staking.
U_GOLD = 2.0
U_BLOOD = 3.0

# ---- powers ---------------------------------------------------------------------------------
# name, then the properties. Columns of PROPS follow PROP_NAMES.
PROP_NAMES = ["start_blood", "start_gold", "max_blood", "roll", "advantage", "no_kill", "safe",
              "stun_range", "swap_wins", "gold_mult", "empty_gold", "hit", "double", "no_cost",
              "gold_cap", "coin_extra", "turn_gold", "win_gold", "lose_gold", "keep_gold",
              "respawn", "mini_gold", "trap", "early_roll", "adv_c", "adv_d", "no_blood_stake",
              "regen", "die2", "six_again"]
(SB, SG, MB, RB, ADV, NOKILL, SAFE, STUN, SWAPW, GMULT, EGOLD, HIT, DBL, NOCOST, GCAP,
 COINX, TURNG, WING, LOSEG, KEEPG, RESP, MINIG, TRAP, EARLY, ADVC, ADVD, NOBS, REGEN, DIE2,
 SIXAG) = range(30)
BIG = 1_000_000

POWERS = [
    ("Dracula", "steal 1 blood from players within 1 space", dict(hit=3)),
    ("Medusa", "players within 1 space miss a turn", dict(stun_range=1)),
    ("Frankenstein", "challenger loses nothing", dict(no_cost=1)),
    ("Death", "cannot be killed, cannot earn gold", dict(no_kill=2, gold_mult=0)),
    ("Mr. Hyde", "+10 in every duel (65/35 / 55/45)", dict(advantage=10)),
    ("Cthulhu", "+1 blood, +1 gold at start (cap 4 each)",
     dict(start_blood=1, start_gold=1, max_blood=1, gold_cap=4)),
    ("Wolfman", "+1 to every roll", dict(roll=1)),
    ("Dorian Gray", "swap needs 1 win", dict(swap_wins=1)),
]
NPOW = len(POWERS)
CONTROL = 0  # only used by --control-only (which gives everyone the first power)


def build_props():
    props = np.zeros((NPOW, len(PROP_NAMES)), np.int32)
    props[:, SWAPW] = SWAP_WINS_DEFAULT
    props[:, GMULT] = 1
    props[:, GCAP] = BIG
    for i, (_, _, d) in enumerate(POWERS):
        for k, v in d.items():
            props[i, PROP_NAMES.index(k)] = v
        if GOLD_CAP_BONUS_MAX and d.get("max_blood"):
            props[i, GCAP] = BASE_BLOOD + d["max_blood"]
    return props


# ---- board ----------------------------------------------------------------------------------
KIND_CODES = {".": 0, "c": 1, "s": 2, "h": 4, "t": 3, "p": 5, "x": 5, "r": 5, "f": 5}
# 0 empty, 1 coin, 2 spikes, 3 thief, 4 church, 5 minigame (all four minigames play the same)


def roll_map(seed):
    """The sim's own map: half of every bag empty, and half of the filled ones minigames.

    The game's real board (src/board/board_path.gd) is not touched. Bags: the main road
    (village, forest, castle) as one, then church, graveyard, boardwalk and bog. Odd counts give
    the extra space to the minigames in the bog and the main road, and to the quick ones in the
    boardwalk and church, so the whole map stays level.
    """
    import random
    rng = random.Random(seed)

    def bag(length, mini, quick_kinds, quick_count):
        quick = [quick_kinds[i % len(quick_kinds)] for i in range(quick_count)]
        rng.shuffle(quick_kinds)
        cells = ["."] * (length - mini - quick_count) + ["p"] * mini + quick
        rng.shuffle(cells)
        return cells

    allq = ["c", "s", "t", "h"]
    main = bag(39, 10, list(allq), 9)               # 20 empty, 10 minigames, 9 quick
    out = {"village": "".join(main[:12]), "forest": "".join(main[12:24]),
           "castle": "".join(main[24:])}
    out["church"] = "".join(bag(12, 3, ["h", "c"], 3))     # 6 empty, 3 minigames, 3 quick
    out["graveyard"] = "".join(bag(8, 2, ["s", "t"], 2))   # 4 empty, 2 minigames, 2 quick
    out["boardwalk"] = "".join(bag(10, 2, list(allq), 3))  # 5 empty, 2 minigames, 3 quick
    out["bog"] = "".join(bag(10, 3, list(allq), 2))        # 5 empty, 3 minigames, 2 quick
    return out


def build_board(map_seed):
    s = roll_map(map_seed)
    # Order: village, split 1 (graveyard / church), forest, split 2 (boardwalk / bog), castle.
    # Route r = c1 * 2 + c2, with c1: 0 graveyard, 1 church; c2: 0 boardwalk, 1 bog.
    names1, names2 = ["graveyard", "church"], ["boardwalk", "bog"]
    phys_ids = {}
    nxt = 1
    for stretch in ["village", "graveyard", "church", "forest", "boardwalk", "bog", "castle"]:
        phys_ids[stretch] = nxt
        nxt += len(s[stretch])
    finish_id = nxt
    kind = np.zeros((4, 80), np.int8)
    phys = np.full((4, 80), -1, np.int16)
    length = np.zeros(4, np.int32)
    start2 = np.zeros(2, np.int32)  # first progress of split 2, by c1
    for c1 in range(2):
        start2[c1] = len(s["village"]) + len(s[names1[c1]]) + len(s["forest"]) + 1
        for c2 in range(2):
            r = c1 * 2 + c2
            p = 0
            phys[r, 0] = 0
            for stretch in ["village", names1[c1], "forest", names2[c2], "castle"]:
                for j, ch in enumerate(s[stretch]):
                    p += 1
                    kind[r, p] = KIND_CODES[ch]
                    phys[r, p] = phys_ids[stretch] + j
            length[r] = p
            phys[r, p + 1] = finish_id
    return kind, phys, length, start2, int(len(s["village"]) + 1), s


# ---- random numbers -------------------------------------------------------------------------
@njit(cache=True, inline="always")
def rnd(rs):
    rs[0] += np.uint64(0x9E3779B97F4A7C15)
    z = rs[0]
    z = (z ^ (z >> np.uint64(30))) * np.uint64(0xBF58476D1CE4E5B9)
    z = (z ^ (z >> np.uint64(27))) * np.uint64(0x94D049BB133111EB)
    z = z ^ (z >> np.uint64(31))
    return (z >> np.uint64(11)) * (1.0 / 9007199254740992.0)


@njit(cache=True, inline="always")
def rint(rs, n):
    return int(rnd(rs) * n)


# ---- state columns --------------------------------------------------------------------------
PROG, C1, C2, BLOOD, GOLD, PLACE, SKIP, WINS, DEATHS, DUELS, POWER = range(11)
NCOL = 11


@njit(cache=True, inline="always")
def route(st, i):
    c2 = st[i, C2]
    if c2 < 0:
        c2 = 0
    return st[i, C1] * 2 + c2


@njit(cache=True)
def max_blood(st, props, i):
    return BASE_BLOOD + props[st[i, POWER], MB]


@njit(cache=True)
def die(st, props, i):
    pw = st[i, POWER]
    st[i, PROG] = props[pw, RESP]
    st[i, C1] = -1
    st[i, C2] = -1
    st[i, BLOOD] = max_blood(st, props, i)
    if props[pw, KEEPG] == 1:
        st[i, GOLD] = st[i, GOLD] // 2
    else:
        st[i, GOLD] = 0
    st[i, DEATHS] += 1


@njit(cache=True)
def lose_blood(st, props, i, amount, by_player):
    nk = props[st[i, POWER], NOKILL]
    if nk == 3:
        return
    if nk == 2 or (by_player and nk == 1):
        st[i, BLOOD] = max(1, st[i, BLOOD] - amount)
        return
    st[i, BLOOD] -= amount
    if st[i, BLOOD] <= 0:
        die(st, props, i)


@njit(cache=True)
def gain_gold(st, props, i, amount):
    pw = st[i, POWER]
    g = st[i, GOLD] + amount * props[pw, GMULT]
    st[i, GOLD] = min(g, props[pw, GCAP])


@njit(cache=True)
def death_cost(st, i):
    return st[i, PROG] + U_GOLD * st[i, GOLD]


@njit(cache=True)
def blood_loss_value(st, props, i, amount):
    """What a player loses (in spaces) when stakes take `amount` blood."""
    if props[st[i, POWER], NOKILL] == 3:
        return 0.0
    if props[st[i, POWER], NOKILL] > 0:
        return min(amount, st[i, BLOOD] - 1) * U_BLOOD
    if st[i, BLOOD] - amount <= 0:
        return death_cost(st, i)
    return amount * U_BLOOD


@njit(cache=True)
def duel(st, props, rs, c, o):
    pc, po = st[c, POWER], st[o, POWER]
    bonus_c = props[pc, ADV] + props[pc, ADVC]
    bonus_o = props[po, ADV] + props[po, ADVD]
    p_round = ROUND_ODDS + 0.01 * (bonus_c - bonus_o)
    wins_needed = props[pc, SWAPW]
    p_swap = p_round ** wins_needed
    dbl = props[pc, DBL] == 1
    amt = 2 if dbl else 1
    nocost = props[pc, NOCOST] == 1
    gm = props[pc, GMULT]

    best = -1
    best_ev = -1e18

    # gold
    ok = dbl or (st[c, GOLD] >= 1 and st[o, GOLD] >= 1)
    if ok:
        t_win = min(amt, st[o, GOLD])
        t_lose = 0 if nocost else min(amt, st[c, GOLD])
        win_v = t_win * gm * U_GOLD + t_win * U_GOLD
        lose_v = t_lose * U_GOLD + t_lose * props[po, GMULT] * U_GOLD
        ev = p_round * win_v - (1.0 - p_round) * lose_v + rnd(rs) * 1e-6
        if ev > best_ev:
            best_ev = ev
            best = 0

    # blood
    def_ok_c = st[c, BLOOD] > 1 or st[c, GOLD] == 0
    def_ok_o = st[o, BLOOD] > 1 or st[o, GOLD] == 0
    ok = dbl or (def_ok_c and def_ok_o)
    if props[pc, NOKILL] > 0 and st[c, BLOOD] == 1:
        ok = False
    if props[po, NOKILL] > 0 and st[o, BLOOD] == 1:
        ok = False
    if props[po, NOBS] == 1:
        ok = False
    if ok:
        win_v = blood_loss_value(st, props, o, amt)
        lose_v = 0.0 if nocost else blood_loss_value(st, props, c, amt)
        ev = p_round * win_v - (1.0 - p_round) * lose_v + rnd(rs) * 1e-6
        if ev > best_ev:
            best_ev = ev
            best = 1

    # swap: a win swaps the places, so both the gain and the opponent's loss count
    delta = float(st[o, PROG] - st[c, PROG])
    ev = p_swap * 2.0 * delta + rnd(rs) * 1e-6
    if ev > best_ev:
        best_ev = ev
        best = 2

    st[c, DUELS] += 1
    if best == 2:
        win = rnd(rs) < p_swap
    else:
        win = rnd(rs) < p_round
    winner = c if win else o
    loser = o if win else c
    st[winner, WINS] += 1

    free = loser == c and nocost
    if best == 0:
        if not free:
            t = min(amt, st[loser, GOLD])
            st[loser, GOLD] -= t
            gain_gold(st, props, winner, t)
    elif best == 1:
        if not free:
            lose_blood(st, props, loser, amt, True)
    elif win:
        for col in (PROG, C1, C2):
            tmp = st[c, col]
            st[c, col] = st[o, col]
            st[o, col] = tmp
    gain_gold(st, props, winner, props[st[winner, POWER], WING])
    gain_gold(st, props, loser, props[st[loser, POWER], LOSEG])


@njit(cache=True)
def land_effects(st, props, rs, kind, phys, length, i, p):
    """Stun, hit, then the space itself. `p` is where player i just landed."""
    pw = st[i, POWER]
    r = route(st, i)
    k = props[pw, STUN]
    hit = props[pw, HIT]
    n = st.shape[0]
    if True:
        my_phys = phys[r, p]
        for j in range(n):
            if j == i or st[j, PLACE] != 0:
                continue
            pj = phys[route(st, j), st[j, PROG]]
            if k > 0:
                for d in range(-k, k + 1):
                    q = p + d
                    if q >= 0 and q <= length[r] and phys[r, q] == pj:
                        st[j, SKIP] = 1
                        break
            if hit == 1 and pj == my_phys:
                lose_blood(st, props, j, 1, True)
            if hit >= 2 and st[j, BLOOD] > 1:
                for d in range(-1, 2):
                    q = p + d
                    if q >= 0 and q <= length[r] and phys[r, q] == pj:
                        st[j, BLOOD] -= 1
                        if hit == 3:
                            st[i, BLOOD] = min(max_blood(st, props, i), st[i, BLOOD] + 1)
                        break
            if pj == my_phys and props[st[j, POWER], TRAP] == 1 and st[i, GOLD] > 0:
                st[i, GOLD] -= 1
                gain_gold(st, props, j, 1)
    kd = kind[r, p]
    if kd == 1:
        gain_gold(st, props, i, 1 + props[pw, COINX])
    elif kd == 2:
        if props[pw, SAFE] == 0:
            lose_blood(st, props, i, 1, False)
    elif kd == 3:
        if (props[pw, SAFE] == 0 or props[pw, SAFE] == 2) and st[i, GOLD] > 0:
            st[i, GOLD] -= 1
    elif kd == 4:
        st[i, BLOOD] = min(max_blood(st, props, i), st[i, BLOOD] + 1)
    elif kd == 0:
        if props[pw, EGOLD] == 1:
            gain_gold(st, props, i, 1)
    else:
        gain_gold(st, props, i, props[pw, MINIG])
        n_opp = 0
        for j in range(n):
            if j != i and st[j, PLACE] == 0:
                n_opp += 1
        if n_opp == 0:
            gain_gold(st, props, i, 1)
        else:
            pick = rint(rs, n_opp)
            for j in range(n):
                if j != i and st[j, PLACE] == 0:
                    if pick == 0:
                        duel(st, props, rs, i, j)
                        break
                    pick -= 1


@njit(cache=True)
def run_match(m, seed, props, kind, phys, length, start2, split1, control_only, second_trophy,
              o_n, o_power, o_rank, o_troph, o_place, o_gt, o_mt, o_gold, o_deaths, o_wins,
              o_duels, o_prog):
    rs = np.empty(1, np.uint64)
    rs[0] = np.uint64(seed) + np.uint64(m) * np.uint64(0xD1342543DE82EF95)
    rnd(rs)
    n = 3 + rint(rs, 4)
    o_n[m] = n

    st = np.zeros((n, NCOL), np.int32)
    pool = np.arange(NPOW)
    for i in range(n):
        if control_only:
            pw = CONTROL
        else:
            j = i + rint(rs, NPOW - i)
            pool[i], pool[j] = pool[j], pool[i]
            pw = pool[i]
        st[i, POWER] = pw
        st[i, C1] = -1
        st[i, C2] = -1
        st[i, BLOOD] = BASE_BLOOD + props[pw, SB]
        st[i, GOLD] = props[pw, SG]

    finished = 0
    for turn in range(TURNS):
        if n - finished <= 1:
            break
        for i in range(n):
            if st[i, PLACE] != 0:
                continue
            if st[i, SKIP] == 1:
                st[i, SKIP] = 0
                continue
            pw = st[i, POWER]
            gain_gold(st, props, i, props[pw, TURNG])
            if props[pw, REGEN] == 1 and turn % 4 == 3:
                st[i, BLOOD] = min(max_blood(st, props, i), st[i, BLOOD] + 1)
            move = 0
            for _ in range(6):
                d = 1 + rint(rs, 6)
                if props[pw, DIE2] == 1:
                    d = 2 + rint(rs, 5)
                move += d
                if props[pw, SIXAG] == 0 or d != 6:
                    break
            if turn < 5:
                move += props[pw, EARLY]
            newp = st[i, PROG] + move + props[pw, RB]
            if newp >= split1 and st[i, C1] < 0:
                st[i, C1] = rint(rs, 2)
            if st[i, C1] >= 0 and newp >= start2[st[i, C1]] and st[i, C2] < 0:
                st[i, C2] = rint(rs, 2)
            r = route(st, i)
            if newp >= length[r] + 1:
                finished += 1
                st[i, PROG] = length[r] + 1
                st[i, PLACE] = finished
            else:
                st[i, PROG] = newp
                land_effects(st, props, rs, kind, phys, length, i, newp)
            if n - finished <= 1:
                break

    # trophies
    maxg = 0
    maxw = 0
    for i in range(n):
        maxg = max(maxg, st[i, GOLD])
        maxw = max(maxw, st[i, WINS])
    key = np.zeros(n, np.int32)
    for i in range(n):
        tf = 1 if (st[i, PLACE] == 1 or (st[i, PLACE] == 2 and second_trophy == 1)) else 0
        tg = 1 if (maxg > 0 and st[i, GOLD] == maxg) else 0
        tm = 1 if (maxw > 0 and st[i, WINS] == maxw) else 0
        tot = tf + tg + tm
        key[i] = tot * 8 + (4 if tf > 0 else 0) + tg * 2 + tm
        o_troph[m, i] = tot
        o_gt[m, i] = tg
        o_mt[m, i] = tm
    for i in range(n):
        better = 0
        same = 0
        for j in range(n):
            if key[j] > key[i]:
                better += 1
            elif key[j] == key[i]:
                same += 1
        o_rank[m, i] = 1.0 + better + (same - 1) * 0.5
        o_power[m, i] = st[i, POWER]
        o_place[m, i] = st[i, PLACE]
        o_gold[m, i] = st[i, GOLD]
        o_deaths[m, i] = st[i, DEATHS]
        o_wins[m, i] = st[i, WINS]
        o_duels[m, i] = st[i, DUELS]
        o_prog[m, i] = st[i, PROG]


@njit(parallel=True, cache=True)
def run_all(matches, seed, props, kind, phys, length, start2, split1, control_only, second_trophy,
            o_n, o_power, o_rank, o_troph, o_place, o_gt, o_mt, o_gold, o_deaths, o_wins,
            o_duels, o_prog):
    for m in prange(matches):
        run_match(m, seed, props, kind, phys, length, start2, split1, control_only, second_trophy,
                  o_n, o_power, o_rank, o_troph, o_place, o_gt, o_mt, o_gold, o_deaths,
                  o_wins, o_duels, o_prog)


# ---- reporting ------------------------------------------------------------------------------
def simulate(matches, seed, control_only, map_seed, second_trophy=1):
    kind, phys, length, start2, split1, _ = build_board(map_seed)
    props = build_props()
    o_n = np.zeros(matches, np.int8)
    shape = (matches, 6)
    o_power = np.full(shape, -1, np.int8)
    o_rank = np.zeros(shape, np.float32)
    o_troph = np.zeros(shape, np.int8)
    o_place = np.zeros(shape, np.int8)
    o_gt = np.zeros(shape, np.int8)
    o_mt = np.zeros(shape, np.int8)
    o_gold = np.zeros(shape, np.int16)
    o_deaths = np.zeros(shape, np.int16)
    o_wins = np.zeros(shape, np.int16)
    o_duels = np.zeros(shape, np.int16)
    o_prog = np.zeros(shape, np.int16)
    run_all(matches, seed, props, kind, phys, length, start2, split1, control_only, second_trophy,
            o_n, o_power, o_rank, o_troph, o_place, o_gt, o_mt, o_gold, o_deaths, o_wins,
            o_duels, o_prog)
    return dict(n=o_n, power=o_power, rank=o_rank, troph=o_troph, place=o_place, gt=o_gt,
                mt=o_mt, gold=o_gold, deaths=o_deaths, wins=o_wins, duels=o_duels, prog=o_prog)


FIELDS = ["cnt", "rank", "rank2", "pct", "win", "fin1", "fin2", "finish", "gtro", "mtro",
          "trophies", "gold", "deaths", "duels", "wins", "prog"]


def sums(res):
    """Per-power sums over one chunk of matches, shape (NPOW, len(FIELDS))."""
    valid = res["power"] >= 0
    power = res["power"][valid].astype(np.int64)
    nn = np.broadcast_to(res["n"][:, None], res["power"].shape)[valid].astype(np.float64)
    rk = res["rank"]
    best = np.where(res["power"] >= 0, rk, 99.0).min(axis=1, keepdims=True)
    is_top = (rk == best) & (res["power"] >= 0)
    win = (is_top / np.maximum(is_top.sum(axis=1, keepdims=True), 1))[valid].astype(np.float64)
    rank = rk[valid].astype(np.float64)
    place = res["place"][valid]
    cols = [np.ones_like(rank), rank, rank * rank, (rank - 1.0) / (nn - 1.0), win,
            (place == 1) * 1.0, (place == 2) * 1.0, (place > 0) * 1.0,
            res["gt"][valid] * 1.0, res["mt"][valid] * 1.0, res["troph"][valid] * 1.0,
            res["gold"][valid] * 1.0, res["deaths"][valid] * 1.0, res["duels"][valid] * 1.0,
            res["wins"][valid] * 1.0, res["prog"][valid] * 1.0]
    out = np.zeros((NPOW, len(FIELDS)))
    for f, col in enumerate(cols):
        out[:, f] = np.bincount(power, weights=col, minlength=NPOW)
    # expected win share if all were equal: mean of 1/n, kept as an extra column
    exp = np.bincount(power, weights=1.0 / nn, minlength=NPOW)
    return np.hstack([out, exp[:, None]])


def table(total):
    rows = []
    for p in range(NPOW):
        t = total[p]
        c = t[0]
        if c == 0:
            continue
        mean = t[1] / c
        se = np.sqrt(max(t[2] / c - mean * mean, 0.0) / c)
        rows.append(dict(
            id=POWERS[p][0], name=POWERS[p][1], games=int(c),
            place=mean, se=se, pct=t[3] / c, win=t[4] / c * 100.0, lift=t[4] / t[-1],
            fin1=t[5] / c * 100.0, fin2=t[6] / c * 100.0, finish=t[7] / c * 100.0,
            gtro=t[8] / c * 100.0, mtro=t[9] / c * 100.0, trophies=t[10] / c, gold=t[11] / c,
            deaths=t[12] / c, duels=t[13] / c, wins=t[14] / c, prog=t[15] / c))
    return rows


def print_table(rows):
    rows = sorted(rows, key=lambda r: r["pct"])
    hdr = ("{:<13} {:<44} {:>6} {:>7} {:>6} {:>6} {:>6} {:>6} {:>6} {:>6} {:>6} {:>6} {:>6} {:>5} {:>5}"
           .format("pwr", "power", "place", "+-", "rank%", "win%", "lift", "1st%", "2nd%", "fin%",
                   "gold%", "mini%", "troph", "death", "duels"))
    print(hdr)
    print("-" * len(hdr))
    for r in rows:
        mark = ""
        print("{:<13} {:<44} {:>6.3f} {:>7.3f} {:>6.1f} {:>6.1f} {:>6.2f} {:>6.1f} {:>6.1f} {:>6.1f} "
              "{:>6.1f} {:>6.1f} {:>6.2f} {:>5.2f} {:>5.2f}{}".format(
                  r["id"], r["name"], r["place"], r["se"], r["pct"] * 100.0, r["win"], r["lift"],
                  r["fin1"], r["fin2"], r["finish"], r["gtro"], r["mtro"], r["trophies"],
                  r["deaths"], r["duels"], mark))
    print()
    print("place = average placement (1 = best, ties share the average rank); +- = std. error")
    print("rank% = average placement scaled so 0 is first and 100 is last (fair across 3-6 players)")
    print("win% = chance of finishing first (ties split); lift = win% / the 1/players you'd expect")
    print("1st%/2nd%/fin% = reached the end first / second / at all; gold%/mini% = won that trophy")
    print("troph = trophies per match; death = deaths per match; duels = duels started per match")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--matches", type=int, default=500_000)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--csv")
    ap.add_argument("--control-only", action="store_true",
                    help="everybody gets no power; checks the board and the 17 turns")
    ap.add_argument("--map-seed", type=int, default=1, help="seed for the sim's own map")
    a = ap.parse_args()
    simulate(1000, a.seed, a.control_only, a.map_seed, 1)  # compile first, so the timing is the sim
    stretches = build_board(a.map_seed)[5]
    for name, ks in stretches.items():
        print("%-10s %s" % (name, ks))
    for way, parts in (("graveyard way", ["village", "graveyard", "forest", "boardwalk", "castle"]),
                       ("church way", ["village", "church", "forest", "bog", "castle"])):
        w = "".join(stretches[x] for x in parts)
        print("%s: %d spaces, %d empty, %d minigames, %d quick" % (
            way, len(w), w.count("."), w.count("p"), len(w) - w.count(".") - w.count("p")))
    half = a.matches // 2
    for phase, (second, count) in enumerate(((1, half), (0, a.matches - half))):
        print()
        print("=" * 60)
        print("{}: {:,} matches. First to finish: 1 trophy. Second to finish: {}.".format(
            "PHASE %d" % (phase + 1), count, "1 trophy" if second else "NO trophy"))
        print("=" * 60)
        t0 = time.time()
        total = np.zeros((NPOW, len(FIELDS) + 1))
        fin_sum = np.zeros(7)
        cnt_n = np.zeros(7)
        duel_sum = np.zeros(7)
        chunk = 500_000
        done = 0
        k = 0
        while done < count:
            m = min(chunk, count - done)
            res = simulate(m, (a.seed * 10 + phase) * 1000 + k, a.control_only, a.map_seed, second)
            total += sums(res)
            n = res["n"].astype(int)
            fin = (res["place"] > 0).sum(axis=1)
            for q in range(3, 7):
                cnt_n[q] += (n == q).sum()
                fin_sum[q] += fin[n == q].sum()
                duel_sum[q] += res["duels"][n == q][:, :q].sum()
            done += m
            k += 1
        dt = time.time() - t0
        print("{:,} matches in {:.2f}s ({:,.0f} matches/s). Players: {}. Finishers per match: {:.3f}"
              .format(count, dt, count / dt,
                      ", ".join("%d: %.0f%%" % (q, cnt_n[q] / count * 100) for q in range(3, 7)),
                      fin_sum.sum() / count))
        for q in range(3, 7):
            print("  {} players: {:.3f} finish, {:.2f} duels each".format(
                q, fin_sum[q] / cnt_n[q], duel_sum[q] / cnt_n[q] / q))
        rows = table(total)
        print()
        print_table(rows)
        if a.csv:
            import csv
            path = a.csv.replace(".csv", "_phase%d.csv" % (phase + 1))
            with open(path, "w", newline="") as f:
                w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
                w.writeheader()
                w.writerows(rows)
            print("wrote", path)


if __name__ == "__main__":
    main()

# Why not the GPU: a match is a few hundred tiny, branchy steps (a duel here, a fork there) on
# 3 to 6 players, so a GPU thread per match would idle most of its warp on divergent branches.
# Measured on the CPU (8 threads): 500,000 matches in under a second after the one-time compile,
# so a GPU port would only add setup. The numba code can be moved to numba.cuda if that changes.
