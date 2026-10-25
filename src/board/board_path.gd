class_name BoardPath
## The road as rules data, which `Match` and the board both read. Every node has an `id`, a world
## `pos`, a `lane`, a `kind`, its `stretch` and `next`: the ids that follow it, the upper path
## first at a fork. The start and the finish are nodes too, but they aren't counted among the
## spaces. Positions come from `BoardLayout`, so moving a lane there moves the path with it.

const START := "start"
const FINISH := "finish"

## What each letter of a stretch's kinds stands for. The four Shot in the Dark groups are the duel spaces.
const KINDS := {
	".": "empty", "c": "coin", "s": "spikes", "t": "thief", "h": "church",
	"a": "atlas", "r": "archive", "l": "lab", "g": "stage",
}

## The stretches in order. Their kinds are rolled fresh for every match by `BoardRoller` and handed
## to `configure`; board.md has the bags. A dot is an empty space, where nothing happens: one of
## every two spaces is empty. The spaces lie evenly along the lane's curve between `from` and `to`,
## which are inset from the location's ends.
const STRETCHES := [
	{"id": "village", "prefix": "v", "location": "village", "lane": BoardLayout.Lane.MAIN,
			"from": BoardLayout.LEAD_IN, "to": 0.0},
	{"id": "church", "prefix": "c", "location": "graveyard", "lane": BoardLayout.Lane.UPPER,
			"from": 100.0, "to": 100.0},
	{"id": "graveyard", "prefix": "g", "location": "graveyard", "lane": BoardLayout.Lane.LOWER,
			"from": 250.0, "to": 250.0},
	{"id": "forest", "prefix": "f", "location": "forest", "lane": BoardLayout.Lane.MAIN,
			"from": 0.0, "to": 0.0},
	{"id": "boardwalk", "prefix": "b", "location": "swamp", "lane": BoardLayout.Lane.UPPER,
			"from": 220.0, "to": 220.0},
	{"id": "bog", "prefix": "m", "location": "swamp", "lane": BoardLayout.Lane.LOWER,
			"from": 220.0, "to": 220.0},
	{"id": "castle", "prefix": "k", "location": "castle", "lane": BoardLayout.Lane.MAIN,
			"from": 0.0, "to": BoardLayout.LEAD_OUT},
]

## Where the start token lies, in the village's lead-in.
const START_X := BoardLayout.LEAD_IN * 0.56

static var _nodes := {}
static var _stretch_ids := {} # stretch id -> its space ids in order
static var _kinds := {} # stretch id -> its kinds string, from `configure`
static var _previous := {} # id -> the ids that lead to it, built with `_nodes`


## Sets up the road for a lobby of `size` players with these rolled `kinds` (`BoardRoller.roll`),
## and drops the old one. Also configures `BoardLayout`, so the two always agree.
static func configure(size: int, kinds: Dictionary) -> void:
	BoardLayout.configure(size)
	_kinds = kinds
	_nodes.clear()
	_stretch_ids.clear()
	_previous.clear()


static func node(id: String) -> Dictionary:
	_build()
	return _nodes.get(id, {})


static func start() -> Dictionary:
	return node(START)


static func finish() -> Dictionary:
	return node(FINISH)


## The ids that follow this one: nothing at the finish, two at a fork, the upper path first.
static func next(id: String) -> Array:
	return node(id).get("next", [])


static func is_fork(id: String) -> bool:
	return next(id).size() > 1


## The ids that lead to this one: two where the paths join, nothing at the start.
static func previous(id: String) -> Array:
	_build()
	return _previous.get(id, [])


## The ids that count as nearby for a landing on `id`: the space itself, one behind and one ahead,
## following the road (characters.md). At a fork, ahead is the first space of both paths; where the
## paths join, behind is the last space of both. The start and the finish are safe, so they are never
## nearby, and nothing is nearby for a landing on them.
static func nearby(id: String) -> Array:
	var node_ := node(id)
	if node_.is_empty() or id == START or id == FINISH:
		return []
	var result := [id]
	for other in previous(id) + next(id):
		if other != START and other != FINISH and other not in result:
			result.append(other)
	return result


## Every node's id, the start first.
static func ids() -> Array:
	_build()
	return _nodes.keys()


## The space ids of one stretch, in order.
static func stretch(id: String) -> Array:
	_build()
	return _stretch_ids[id]


## Every way from the start to the finish, as lists of ids.
static func routes(from := START) -> Array:
	var result := []
	var following := next(from)
	if following.is_empty():
		return [[from]]
	for id in following:
		for route in routes(id):
			result.append([from] + route)
	return result


## A line for each stretch with its space count and kinds, for the log.
static func report() -> Array[String]:
	_build()
	var lines: Array[String] = []
	for each in STRETCHES:
		var kinds := []
		for id in _stretch_ids[each.id]:
			kinds.append(_nodes[id].kind)
		lines.append("%s: %d spaces: %s" % [each.id, kinds.size(), ", ".join(kinds)])
	return lines


static func _build() -> void:
	if not _nodes.is_empty():
		return
	_previous.clear()
	if _kinds.is_empty():
		configure(4, BoardRoller.roll(4, RandomNumberGenerator.new()))
	_add(START, Vector2(START_X, BoardLayout.lane_y(BoardLayout.Lane.MAIN, START_X)),
			BoardLayout.Lane.MAIN, "start", "village")
	for each in STRETCHES:
		var location := BoardLayout.location(each.location)
		var xs := _spread(each.lane, location.from + each.from, location.to - each.to, _kinds[each.id].length())
		var ids := []
		for i in xs.size():
			var id: String = "%s%d" % [each.prefix, i + 1]
			_add(id, Vector2(xs[i], BoardLayout.lane_y(each.lane, xs[i])), each.lane,
					KINDS[_kinds[each.id][i]], each.id)
			ids.append(id)
		_stretch_ids[each.id] = ids
	var x := BoardLayout.gate_x()
	_add(FINISH, Vector2(x, BoardLayout.lane_y(BoardLayout.Lane.MAIN, x)),
			BoardLayout.Lane.MAIN, "finish", "castle")
	_link(START, [_stretch_ids.village[0]])
	for each in STRETCHES:
		var ids: Array = _stretch_ids[each.id]
		for i in ids.size() - 1:
			_link(ids[i], [ids[i + 1]])
	_link(_stretch_ids.village[-1], [_stretch_ids.church[0], _stretch_ids.graveyard[0]])
	_link(_stretch_ids.church[-1], [_stretch_ids.forest[0]])
	_link(_stretch_ids.graveyard[-1], [_stretch_ids.forest[0]])
	_link(_stretch_ids.forest[-1], [_stretch_ids.boardwalk[0], _stretch_ids.bog[0]])
	_link(_stretch_ids.boardwalk[-1], [_stretch_ids.castle[0]])
	_link(_stretch_ids.bog[-1], [_stretch_ids.castle[0]])
	_link(_stretch_ids.castle[-1], [FINISH])


static func _add(id: String, pos: Vector2, lane: BoardLayout.Lane, kind: String, stretch_id: String) -> void:
	_nodes[id] = {"id": id, "pos": pos, "lane": lane, "kind": kind, "stretch": stretch_id, "next": []}


static func _link(id: String, following: Array) -> void:
	_nodes[id].next = following
	for other in following:
		_previous[other] = _previous.get(other, []) + [id]


# The x of `count` spaces spread evenly along a lane's curve, by its length, not just by x, so a
# ramp doesn't bunch them up. Each space sits in the middle of its share of the way.
static func _spread(lane: BoardLayout.Lane, from: float, to: float, count: int) -> Array[float]:
	const STEPS := 400
	var along: Array[float] = [0.0]
	var last := Vector2(from, BoardLayout.lane_y(lane, from))
	for i in range(1, STEPS + 1):
		var x := lerpf(from, to, float(i) / STEPS)
		var point := Vector2(x, BoardLayout.lane_y(lane, x))
		along.append(along[-1] + last.distance_to(point))
		last = point
	var result: Array[float] = []
	var step := 0
	for i in count:
		var target: float = along[-1] * (i + 0.5) / count
		while along[step + 1] < target:
			step += 1
		var share := inverse_lerp(along[step], along[step + 1], target)
		result.append(lerpf(from, to, (step + share) / STEPS))
	return result
