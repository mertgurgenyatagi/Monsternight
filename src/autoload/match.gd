extends Node
## The one place match state lives. Only the rules code changes it. Part 3 holds the players
## and their names; later parts add monster, blood, coins, position, trophies and stats to each
## player. Online play will have the host run this and send the results to everyone.

const MIN_PLAYERS := 2
const MAX_PLAYERS := 8
const NAME_LENGTH := 12

## One dictionary per player. Right after `start` this is the seating order; `roll_turn_order`
## reshuffles it, and from then on the array order is the turn order.
var players: Array[Dictionary] = []


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
		players.append({"name": clean_name(raw_names[i], i), "monster": "", "space": BoardPath.START})
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


## Puts the player on this space of the path, the one rules call that changes where they stand.
## Returns false, changing nothing, if there's no such space.
func move_to(player: Dictionary, id: String) -> bool:
	if BoardPath.node(id).is_empty():
		return false
	player.space = id
	print("Moved: ", player.name, " to ", id)
	return true


## The names the setup screen shows again after a match, or an empty list at first.
func names() -> Array[String]:
	var result: Array[String] = []
	for player in players:
		result.append(player.name)
	return result
