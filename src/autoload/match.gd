extends Node
## The one place match state lives. Only the rules code changes it. Part 3 holds the players
## and their names; later parts add monster, blood, coins, position, trophies and stats to each
## player. Online play will have the host run this and send the results to everyone.

const MIN_PLAYERS := 2
const MAX_PLAYERS := 8
const NAME_LENGTH := 12
const TURNS := 17
const MAX_BLOOD := 3

## One dictionary per player. Right after `start` this is the seating order; `roll_turn_order`
## reshuffles it, and from then on the array order is the turn order.
var players: Array[Dictionary] = []

## The turn the match is on, from 1 to `TURNS`.
var turn := 1

## The index in `players` of the player whose turn it is.
var current := 0

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
## valid.
func start(raw_names: Array[String]) -> bool:
	if raw_names.size() < MIN_PLAYERS or raw_names.size() > MAX_PLAYERS or not duplicates(raw_names).is_empty():
		return false
	players.clear()
	for i in raw_names.size():
		players.append({"name": clean_name(raw_names[i], i), "monster": "", "space": BoardPath.START,
				"blood": MAX_BLOOD, "coins": 0, "finished": false, "deaths": 0, "arrived": 0})
	_arrivals = 0
	turn = 1
	current = 0
	print("Match started: ", players)
	return true


## Rolls the turn order: shuffles `players` so the array order is the turn order from here on,
## and returns the seating order it started from. The animation only shows the result.
func roll_turn_order() -> Array[Dictionary]:
	var seating := players.duplicate()
	players.shuffle()
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
	print("Monster picked: ", player.name, " is ", id)
	return true


## The player whose turn it is.
func active() -> Dictionary:
	return players[current]


## The die: 1 to 6. The rules decide the number; the die only shows it.
func roll() -> int:
	var value := randi_range(1, 6)
	print("Rolled: ", active().name, " ", value)
	return value


## Passes the turn to the next player who hasn't finished, and to the next turn after the last
## player. Returns false, changing nothing, when turn `TURNS` is over or everyone has finished.
func next_player() -> bool:
	var index := current
	var wrapped := false
	for _step in players.size():
		index += 1
		if index >= players.size():
			index = 0
			wrapped = true
		if wrapped and turn >= TURNS:
			return false
		if not players[index].finished:
			if wrapped:
				turn += 1
			current = index
			print("Next: ", players[index].name, ", turn ", turn)
			return true
	return false


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
	var result := {"coins": player.coins, "blood": MAX_BLOOD - player.blood}
	player.coins = 0
	player.blood = MAX_BLOOD
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
## have blood and "swap" if the two stand on different spaces. Part 18 refines the swap.
func stakes(challenger: Dictionary, opponent: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if opponent.coins > 0:
		result.append("gold")
	if opponent.blood > 0:
		result.append("blood")
	if challenger.space != opponent.space:
		result.append("swap")
	return result


## Adds `delta` to the player's blood, kept between 0 and `MAX_BLOOD`. Returns the change that
## really happened. Reaching 0 is a death, which `die` settles and the board shows.
func change_blood(player: Dictionary, delta: int) -> int:
	var before: int = player.blood
	player.blood = clampi(before + delta, 0, MAX_BLOOD)
	print("Blood: ", player.name, " ", before, " -> ", player.blood)
	return player.blood - before


## Adds `delta` to the player's coins, never below 0. Returns the change that really happened.
func change_coins(player: Dictionary, delta: int) -> int:
	var before: int = player.coins
	player.coins = maxi(before + delta, 0)
	print("Coins: ", player.name, " ", before, " -> ", player.coins)
	return player.coins - before


## The names the setup screen shows again after a match, or an empty list at first.
func names() -> Array[String]:
	var result: Array[String] = []
	for player in players:
		result.append(player.name)
	return result


# How far along the road a player is: a finished player is past everyone.
func _progress(player: Dictionary) -> float:
	return INF if player.finished else BoardPath.node(player.space).pos.x
