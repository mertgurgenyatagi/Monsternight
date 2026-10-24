extends Node
## The one place match state lives. Only the rules code changes it. Part 3 holds the players
## and their names; later parts add monster, blood, coins, position, trophies and stats to each
## player. Online play will have the host run this and send the results to everyone.

const MIN_PLAYERS := 3
const MAX_PLAYERS := 8
const NAME_LENGTH := 12
## The turns of a match by the number of players (game_rules.md).
const TURNS_BY_LOBBY := {3: 20, 4: 17, 5: 15, 6: 14, 7: 13, 8: 12}
## The most blood a player can have, and Cthulhu's (characters.md).
const MAX_BLOOD := 3
const CTHULHU_BLOOD := 4
## What the Wolf Man adds to every roll.
const WOLFMAN_BONUS := 1

## One dictionary per player. Right after `start` this is the seating order; `roll_turn_order`
## reshuffles it, and from then on the array order is the turn order.
var players: Array[Dictionary] = []

## The turns this match lasts, set by `start` from `TURNS_BY_LOBBY`. `reset` leaves it alone.
static var turns := 17

## The kinds of this match's board, rolled by `start` for the lobby's size (`BoardRoller`), as
## {stretch id: kinds string}. The board hands them to `BoardPath.configure`.
var board_kinds := {}

## Rolls the board. `start` seeds it fresh, or from `--seed N` after `--` on the command line.
var board_rng := RandomNumberGenerator.new()

## The turn the match is on, from 1 to `turns`.
var turn := 1

## The index in `players` of the player whose turn it is.
var current := 0

## The players who have reached the castle gate, in the order they got there.
var finish_order: Array[Dictionary] = []

## The players whose stone cracked in the last `next_player`: their turn was skipped. The board
## reads and clears this with `take_cracked` to show it.
var cracked: Array[Dictionary] = []

# Set once turn `turns` has been played to its end.
var _turns_done := false

# Counts every arrival on a space, so a tie in `leader` goes to whoever got there first.
var _arrivals := 0


## A typed name as it will be kept: trimmed, capped, and "Player N" when blank.
static func clean_name(raw: String, index: int) -> String:
	var cleaned := raw.strip_edges().left(NAME_LENGTH).strip_edges()
	return cleaned if cleaned else TranslationServer.translate("PLAYER_DEFAULT") % (index + 1)


## The seats whose cleaned name is already taken by an earlier seat. Names are compared
## without regard to case, so players can always tell each other apart.
static func duplicates(raw_names: Array[String]) -> Array[int]:
	var seen := {}
	var result: Array[int] = []
	for i in raw_names.size():
		var key := clean_name(raw_names[i], i).to_lower()
		if key in seen:
			result.append(i)
		else:
			seen[key] = true
	return result


## Begins a match with these typed names. Returns false, changing nothing, if the setup isn't
## valid. Online, every copy passes the host's `seed`, so all of them roll the same board and the
## same turn order; -1 seeds at random (or from `--seed N`).
func start(raw_names: Array[String], seed := -1) -> bool:
	if raw_names.size() < MIN_PLAYERS or raw_names.size() > MAX_PLAYERS or not duplicates(raw_names).is_empty():
		return false
	players.clear()
	for i in raw_names.size():
		players.append({"name": clean_name(raw_names[i], i), "monster": "", "space": BoardPath.START,
				"blood": MAX_BLOOD, "coins": 0, "finished": false, "deaths": 0, "arrived": 0,
					"duels_started": 0, "challenged": 0, "duels_won": 0, "spike_blood": 0,
					"stone": false, "just_missed": false})
	_arrivals = 0
	_turns_done = false
	turns = TURNS_BY_LOBBY[raw_names.size()]
	var short := Net.debug_value("turns") # a short match, to test with
	if short.is_valid_int():
		turns = maxi(1, short.to_int())
	_seed_board(seed)
	board_kinds = BoardRoller.roll(raw_names.size(), board_rng)
	finish_order.clear()
	cracked.clear()
	turn = 1
	current = 0
	print("Match started: ", players)
	return true


# Seeds the board's dice: from the host's seed, or from `--seed N` in the user arguments so a
# board can be reproduced, or at random.
func _seed_board(seed: int) -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--seed")
	if seed >= 0:
		board_rng.seed = seed
	elif at >= 0 and at + 1 < args.size() and args[at + 1].is_valid_int():
		board_rng.seed = args[at + 1].to_int()
	else:
		board_rng.randomize()


## Clears the whole match, so the next lobby starts fresh. The autoload is never recreated.
func reset() -> void:
	players.clear()
	finish_order.clear()
	cracked.clear()
	turn = 1
	current = 0
	_arrivals = 0
	_turns_done = false


## Rolls the turn order: shuffles `players` so the array order is the turn order from here on,
## and returns the seating order it started from. The animation only shows the result.
func roll_turn_order() -> Array[Dictionary]:
	var seating := players.duplicate()
	for i in range(players.size() - 1, 0, -1): # a shuffle that follows the match's seed
		var j := board_rng.randi_range(0, i)
		var swapped := players[i]
		players[i] = players[j]
		players[j] = swapped
	print("Turn order: ", names())
	return seating


## The monsters nobody has picked yet, in the order of characters.md.
func free_monsters() -> Array[String]:
	var result: Array[String] = []
	for id in Monsters.IDS:
		if not players.any(func(p: Dictionary) -> bool: return p.monster == id):
			result.append(id)
	return result


## Gives the player this monster. Returns false, changing nothing, if it's taken, if there's no
## such monster, or if the player already has one.
func pick_monster(player: Dictionary, id: String) -> bool:
	if id not in free_monsters() or player.monster != "":
		return false
	player.monster = id
	if id == "cthulhu": # starts with a full 4 blood and 1 coin
		player.blood = max_blood(player)
		player.coins = 1
	print("Monster picked: ", player.name, " is ", id)
	return true


## The player whose turn it is.
func active() -> Dictionary:
	return players[current]


## The die's face, 1 to 6. The rules decide the number; the die only shows it. Online, the host
## rolls and every copy passes that face as `forced`.
func roll(forced := 0) -> int:
	var value := forced if forced >= 1 and forced <= 6 else randi_range(1, 6)
	print("Rolled: ", active().name, " ", value)
	return value


## What a roll adds for this player: 1 for the Wolf Man, 0 for everyone else. The spaces moved are
## the face plus this.
func roll_bonus(player: Dictionary) -> int:
	return WOLFMAN_BONUS if player.monster == "wolfman" else 0


## The most blood this player can have: 4 for Cthulhu, 3 for everyone else.
func max_blood(player: Dictionary) -> int:
	return CTHULHU_BLOOD if player.monster == "cthulhu" else MAX_BLOOD


## The least blood this player can have: 1 for Death, who can't be killed, 0 for everyone else.
func min_blood(player: Dictionary) -> int:
	return 1 if player.monster == "death" else 0


## True when the match is over: turn `turns` has been played out, or no more than one player is
## left who hasn't reached the gate.
func over() -> bool:
	return _turns_done or players.filter(func(p: Dictionary) -> bool: return not p.finished).size() <= 1


## Passes the turn to the next player who hasn't finished, and to the next turn after the last
## player. A player turned to stone (Medusa) is passed over: the stone cracks, they are safe from the
## next one until they have moved, and they go into `cracked` for the board to show. Returns false,
## changing nothing but that, when the match is `over`.
func next_player() -> bool:
	if over():
		return false
	players[current].just_missed = false # they have moved since the last stone
	var index := current
	var wrapped := false
	for _step in players.size():
		index += 1
		if index >= players.size():
			index = 0
			wrapped = true
		if wrapped and turn >= turns:
			_turns_done = true
			return false
		var candidate: Dictionary = players[index]
		if candidate.finished:
			continue
		if candidate.stone:
			candidate.stone = false
			candidate.just_missed = true
			cracked.append(candidate)
			print("Stone cracked: ", candidate.name, ", turn skipped")
			if wrapped:
				turn += 1
				wrapped = false
			current = index
			continue
		if wrapped:
			turn += 1
		current = index
		print("Next: ", candidate.name, ", turn ", turn)
		return true
	return false


## The players whose turn was just skipped by their stone cracking, in the order it happened. Clears
## the list.
func take_cracked() -> Array[Dictionary]:
	var result := cracked.duplicate()
	cracked.clear()
	return result


## The other players near the one who has just landed (`BoardPath.nearby`): not finished, and none
## while the lander is on the start or the finish. Only a landing from a roll calls this.
func nearby_players(player: Dictionary) -> Array[Dictionary]:
	var near := BoardPath.nearby(player.space)
	var result: Array[Dictionary] = []
	for other in players:
		if not is_same(other, player) and not other.finished and other.space in near:
			result.append(other)
	return result


## Dracula landed: each player nearby with 2 or more blood loses 1 (through `change_blood`, so
## Death's floor holds) and Dracula gains 1 for each, up to his most. The victims lose even when
## he is full. Returns the victims who really lost blood.
func drain(player: Dictionary) -> Array[Dictionary]:
	var victims: Array[Dictionary] = []
	for other in nearby_players(player):
		if other.blood >= 2 and change_blood(other, -1) != 0:
			change_blood(player, 1)
			victims.append(other)
	print("Drain: ", player.name, " took blood from ", victims.map(func(p: Dictionary) -> String: return p.name))
	return victims


## Medusa landed: each player nearby who isn't stone already turns to stone and will miss their next
## turn, except one who just missed a turn. Returns the players turned to stone.
func petrify(player: Dictionary) -> Array[Dictionary]:
	var turned: Array[Dictionary] = []
	for other in nearby_players(player):
		if not other.stone and not other.just_missed:
			other.stone = true
			turned.append(other)
	print("Petrify: ", player.name, " turned ", turned.map(func(p: Dictionary) -> String: return p.name))
	return turned


## Puts the player on this space of the path, the one rules call that changes where they stand.
## Returns false, changing nothing, if there's no such space.
func move_to(player: Dictionary, id: String) -> bool:
	if BoardPath.node(id).is_empty():
		return false
	player.space = id
	_arrivals += 1
	player.arrived = _arrivals
	print("Moved: ", player.name, " to ", id)
	return true


## The player has reached the castle gate: they are finished from here on, and take the next place.
## Returns the place, 1 for the first. A player who has finished already keeps the place they have.
func finish(player: Dictionary) -> int:
	for i in finish_order.size():
		if is_same(finish_order[i], player):
			return i + 1
	player.finished = true
	finish_order.append(player)
	print("Finished: ", player.name, " in place ", finish_order.size())
	return finish_order.size()


## The player furthest along the road. A finished player counts as furthest, and on a tie the one
## who got there first leads. Empty before there are players.
func leader() -> Dictionary:
	var best := {}
	for player in players:
		if best.is_empty() or _progress(player) > _progress(best) 				or (_progress(player) == _progress(best) and player.arrived < best.arrived):
			best = player
	return best


## The player dies for real: coins go to 0, blood is full again and they stand on the start,
## and their death count goes up. Returns the `coins` lost and the `blood` refilled, or nothing
## at all for a finished player, who can't die. The board shows the death (`Board.die`).
func die(player: Dictionary) -> Dictionary:
	if player.finished:
		return {}
	var result := {"coins": player.coins, "blood": max_blood(player) - player.blood}
	player.coins = 0
	player.blood = max_blood(player)
	player.deaths += 1
	move_to(player, BoardPath.START)
	print("Died: ", player.name, " (death ", player.deaths, ") ", result)
	return result


## The rules for the space the player stands on: a coin gives 1 coin, spikes take 1 blood, a thief
## takes 1 coin and a church gives 1 blood. Every other space does nothing. Returns the space's
## `kind` and the real `coins` and `blood` changes, so a thief on 0 coins or a church on full blood
## changes nothing.
func land(player: Dictionary) -> Dictionary:
	var kind: String = BoardPath.node(player.space).kind
	var result := {"kind": kind, "coins": 0, "blood": 0}
	match kind:
		"coin":
			result.coins = change_coins(player, 1)
		"spikes":
			result.blood = change_blood(player, -1)
			player.spike_blood -= result.blood
		"thief":
			result.coins = change_coins(player, -1)
		"church":
			result.blood = change_blood(player, 1)
	print("Landed: ", player.name, " on ", player.space, " (", kind, ") ", result)
	return result


## Everyone the challenger can duel: every other player who hasn't finished.
func opponents(player: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for other in players:
		if not is_same(other, player) and not other.finished:
			result.append(other)
	return result


## The stakes the challenger can ask of this opponent: "gold" if they have a coin, "blood" if they
## have blood and "swap" if the two stand on different spaces. Blood is off the table whenever Death
## is in the duel with 1 blood, whichever side they are on.
func stakes(challenger: Dictionary, opponent: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if opponent.coins > 0:
		result.append("gold")
	if opponent.blood > 0 and not blood_is_safe(challenger) and not blood_is_safe(opponent):
		result.append("blood")
	if challenger.space != opponent.space:
		result.append("swap")
	return result


## True for Death at 1 blood, whose blood can't be staked or spiked.
func blood_is_safe(player: Dictionary) -> bool:
	return player.monster == "death" and player.blood <= min_blood(player)


## Applies a finished duel. The loser pays the stake: gold is 1 coin from the loser to the winner, and
## blood is 1 of the loser's blood. A swap happens only if the challenger won, and then the two trade
## `space`; a challenger who lost a swap loses nothing. The challenger's `duels_started`, the
## opponent's `challenged` and the winner's `duels_won` go up. Returns the real changes: `coins` that
## moved, `blood` the loser lost, whether they `swapped`, and whether the loser `died` (blood at 0,
## which the board shows through `Board.die`, which settles it). A Frankenstein's Monster who lost as
## the challenger pays nothing, and `free` says that a real stake was waived.
func duel_result(winner: Dictionary, loser: Dictionary, challenger: Dictionary, stake: String) -> Dictionary:
	var opponent: Dictionary = winner if is_same(loser, challenger) else loser
	challenger.duels_started += 1
	opponent.challenged += 1
	winner.duels_won += 1
	var result := {"coins": 0, "blood": 0, "swapped": false, "died": false, "free": false}
	if is_same(loser, challenger) and loser.monster == "frankenstein":
		result.free = (stake == "gold" and loser.coins > 0) or (stake == "blood" and loser.blood > 0)
		print("Duel: ", winner.name, " beat ", loser.name, " for ", stake, " ", result)
		return result
	match stake:
		"gold":
			result.coins = -change_coins(loser, -1)
			change_coins(winner, result.coins)
		"blood":
			result.blood = -change_blood(loser, -1)
			result.died = loser.blood == 0 and result.blood != 0 and not loser.finished
		"swap":
			if is_same(winner, challenger) and challenger.space != opponent.space:
				var there: String = opponent.space
				move_to(opponent, challenger.space)
				move_to(challenger, there)
				result.swapped = true
	print("Duel: ", winner.name, " beat ", loser.name, " for ", stake, " ", result)
	return result


## Adds `delta` to the player's blood, kept between `min_blood` and `max_blood`. Returns the change
## that really happened. Reaching 0 is a death, which `die` settles and the board shows.
func change_blood(player: Dictionary, delta: int) -> int:
	var before: int = player.blood
	player.blood = clampi(before + delta, min_blood(player), max_blood(player))
	print("Blood: ", player.name, " ", before, " -> ", player.blood)
	return player.blood - before


## Adds `delta` to the player's coins, never below 0. Returns the change that really happened.
func change_coins(player: Dictionary, delta: int) -> int:
	var before: int = player.coins
	player.coins = maxi(before + delta, 0)
	print("Coins: ", player.name, " ", before, " -> ", player.coins)
	return player.coins - before


## Every player ranked by trophies, best first: `{player, trophies, finish, gold, duels, rank, by}`.
## `finish` is the place at the gate (0 for none), `gold` the coins and `duels` the duels won. `by` says
## what each trophy kind gave: `{finish, gold, duels}`. 1 trophy for the first finisher only, 1 for the
## most gold and 1 for the most duels won, a tie giving all of them the trophy and
## a count of 0 none. Equal trophies are split by the finishing trophy, then the gold trophy, then the
## duel trophy; players still equal share a rank (and keep turn order in the list).
func results() -> Array:
	var most_gold := 0
	var most_duels := 0
	for player in players:
		most_gold = maxi(most_gold, player.coins)
		most_duels = maxi(most_duels, player.duels_won)
	var rows: Array = []
	for i in players.size():
		var player: Dictionary = players[i]
		var place := _place(player)
		var by := {"finish": 1 if place == 1 else 0,
				"gold": 1 if most_gold > 0 and player.coins == most_gold else 0,
				"duels": 1 if most_duels > 0 and player.duels_won == most_duels else 0}
		rows.append({"player": player, "trophies": by.finish + by.gold + by.duels, "finish": place,
				"gold": player.coins, "duels": player.duels_won, "rank": 0, "by": by, "seat": i})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ka := _rank_key(a)
		var kb := _rank_key(b)
		return ka > kb if ka != kb else a.seat < b.seat)
	for i in rows.size():
		rows[i].rank = 1 if i == 0 else (rows[i - 1].rank if _rank_key(rows[i]) == _rank_key(rows[i - 1]) else i + 1)
	for row in rows:
		row.erase("seat")
	return rows


## The four fun stats, each `{key, players, value}`: `deaths`, `duels_started`, `challenged` and
## `spike_blood`, with the players who have the highest count (all of them on a tie). A stat nobody
## scored 1 in is left out.
func stats() -> Array:
	var result: Array = []
	for key in ["deaths", "duels_started", "challenged", "spike_blood"]:
		var best := 0
		for player in players:
			best = maxi(best, player[key])
		if best < 1:
			continue
		var holders := players.filter(func(p: Dictionary) -> bool: return p[key] == best)
		result.append({"key": key, "players": holders, "value": best})
	return result


## The names the setup screen shows again after a match, or an empty list at first.
func names() -> Array[String]:
	var result: Array[String] = []
	for player in players:
		result.append(player.name)
	return result


# The player's place at the gate, 1 for the first, or 0 for not having finished.
func _place(player: Dictionary) -> int:
	for i in finish_order.size():
		if is_same(finish_order[i], player):
			return i + 1
	return 0


# What ranks a row: trophies, then the finishing, gold and duel trophies, compared as an array.
func _rank_key(row: Dictionary) -> Array:
	return [row.trophies, row.by.finish, row.by.gold, row.by.duels]


# How far along the road a player is: a finished player is past everyone.
func _progress(player: Dictionary) -> float:
	return INF if player.finished else BoardPath.node(player.space).pos.x
