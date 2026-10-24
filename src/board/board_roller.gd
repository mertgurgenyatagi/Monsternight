class_name BoardRoller
## Rolls the kinds of the board's spaces, fresh for every match (board.md, Space mix). Each stretch
## of the road is a bag with exact counts, shuffled with no other rule on the order: half of its
## spaces are empty, half of the rest are minigames and the others are quick spaces. The minigames
## are the four games in equal numbers, and so are the quick kinds the stretch allows. Whenever a
## count doesn't split evenly, the odd space goes to a random side or a random kind.

## The minigames' letters, as in `BoardPath.KINDS`.
const MINIGAMES: Array[String] = ["p", "u", "e", "w"]
const QUICK: Array[String] = ["c", "s", "t", "h"]

## Each stretch's length when it doesn't come from the lobby's size, and the quick kinds it allows.
## The graveyard has only spikes and thieves, and the church path only churches and coins.
const FIXED := {"church": 12, "graveyard": 8, "boardwalk": 10, "bog": 10}
const ONLY := {"church": ["h", "c"], "graveyard": ["s", "t"]}
const ORDER := ["village", "church", "graveyard", "forest", "boardwalk", "bog", "castle"]


## Every stretch's kinds for a lobby of `size` players: {stretch id: its kinds string}.
static func roll(size: int, rng: RandomNumberGenerator) -> Dictionary:
	var counts := BoardLayout.counts(size)
	var result := {}
	for id: String in ORDER:
		var length: int = FIXED[id] if id in FIXED else counts[id]
		var quick: Array = ONLY.get(id, QUICK)
		result[id] = "".join(_bag(length, quick, rng))
	return result


# One stretch's shuffled bag of `length` letters.
static func _bag(length: int, quick: Array, rng: RandomNumberGenerator) -> Array[String]:
	var empty := _half(length, rng)
	var filled := length - empty
	var games := _half(filled, rng)
	var bag: Array[String] = []
	for _i in empty:
		bag.append(".")
	bag.append_array(_shared(games, MINIGAMES, rng))
	bag.append_array(_shared(filled - games, quick, rng))
	for i in range(bag.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held := bag[i]
		bag[i] = bag[j]
		bag[j] = held
	return bag


# Half of `count`, the odd one going either way.
static func _half(count: int, rng: RandomNumberGenerator) -> int:
	return count / 2 + (rng.randi_range(0, 1) if count % 2 == 1 else 0)


# `count` letters shared equally among `kinds`; the odd ones go to random, different kinds.
static func _shared(count: int, kinds: Array, rng: RandomNumberGenerator) -> Array[String]:
	var letters: Array[String] = []
	for kind: String in kinds:
		for _i in count / kinds.size():
			letters.append(kind)
	var left := kinds.duplicate()
	for _i in count % kinds.size():
		var pick := rng.randi_range(0, left.size() - 1)
		letters.append(left[pick])
		left.remove_at(pick)
	return letters
