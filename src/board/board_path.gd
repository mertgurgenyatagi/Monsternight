class_name BoardPath
## The road as rules data, which `Match` and the board both read. Every node has an `id`, a world
## `pos`, a `lane`, a `kind`, its `stretch` and `next`: the ids that follow it, the upper path
## first at a fork. The start and the finish are nodes too, but they aren't counted among the
## spaces. Positions come from `BoardLayout`, so moving a lane there moves the path with it.

const START := "start"
const FINISH := "finish"

## What each letter of a stretch's kinds stands for.
const KINDS := {
	".": "empty", "c": "coin", "s": "spikes", "t": "thief", "h": "church",
	"p": "pong", "x": "haxball", "r": "racing", "f": "fps",
}

## The stretches in order. `kinds` is the type sequence, rolled once by `tools/board/roll_board.py`
## (seed 1031), never written by hand, so the board is the same every match. board.md has the
## bags it is rolled from. A dot is an empty space, where nothing happens: one of every two
## spaces is empty. The spaces lie evenly along the lane's curve between `from` and `to`, which
## are inset from the location's ends.
const STRETCHES := [
	{"id": "village", "prefix": "v", "location": "village", "lane": BoardLayout.Lane.MAIN,
			"kinds": ".hf..x..ssct", "from": BoardLayout.LEAD_IN, "to": 0.0},
	{"id": "church", "prefix": "c", "location": "graveyard", "lane": BoardLayout.Lane.UPPER,
			"kinds": ".hc.chr.h...", "from": 100.0, "to": 100.0},
	{"id": "graveyard", "prefix": "g", "location": "graveyard", "lane": BoardLayout.Lane.LOWER,
			"kinds": ".s..stt.", "from": 250.0, "to": 250.0},
	{"id": "forest", "prefix": "f", "location": "forest", "lane": BoardLayout.Lane.MAIN,
			"kinds": ".t.st......h", "from": 0.0, "to": 0.0},
	{"id": "boardwalk", "prefix": "b", "location": "swamp", "lane": BoardLayout.Lane.UPPER,
			"kinds": "...x..ptct", "from": 220.0, "to": 220.0},
	{"id": "bog", "prefix": "m", "location": "swamp", "lane": BoardLayout.Lane.LOWER,
			"kinds": ".h...f.hhr", "from": 220.0, "to": 220.0},
	{"id": "castle", "prefix": "k", "location": "castle", "lane": BoardLayout.Lane.MAIN,
			"kinds": "t.cshr...c..h.p", "from": 0.0, "to": BoardLayout.LEAD_OUT},
]

## Where the start token lies, in the village's lead-in.
const START_X := BoardLayout.LEAD_IN * 0.56

static var _nodes := {}
static var _stretch_ids := {} # stretch id -> its space ids in order


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
	_add(START, Vector2(START_X, BoardLayout.lane_y(BoardLayout.Lane.MAIN, START_X)),
			BoardLayout.Lane.MAIN, "start", "village")
	for each in STRETCHES:
		var location := BoardLayout.location(each.location)
		var xs := _spread(each.lane, location.from + each.from, location.to - each.to, each.kinds.length())
		var ids := []
		for i in xs.size():
			var id: String = "%s%d" % [each.prefix, i + 1]
			_add(id, Vector2(xs[i], BoardLayout.lane_y(each.lane, xs[i])), each.lane,
					KINDS[each.kinds[i]], each.id)
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
