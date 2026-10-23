class_name BoardPathView
extends Node2D
## The road drawn from `BoardPath`: the path dots, the signposts at the forks, the spaces and the
## flag at the gate. It goes in the Lanes layer after the ground, so the foreground fog lies
## over it. The signposts and dots are drawn first, so every token is in front of them.

const DOT := preload("res://assets/art/board/path_dot.png")
const SIGNPOST := preload("res://assets/art/board/signpost.png")
const DOTS_BETWEEN := 3
const DOT_SIZE := Vector2(0.28, 0.4) # the smallest and biggest scale of a dot
const SIGNPOST_SCALE := 0.62
const FLAG_SCALE := 1.8
const ROAD_WIDTH := 78.0
const ROAD_COLOR := Color(0.1, 0.06, 0.16, 0.5)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	var road := Node2D.new()
	road.name = "Road"
	add_child(road)
	var dots := Node2D.new()
	dots.name = "Dots"
	add_child(dots)
	var signposts := Node2D.new()
	signposts.name = "Signposts"
	add_child(signposts)
	var spaces := Node2D.new()
	spaces.name = "Spaces"
	spaces.y_sort_enabled = true
	add_child(spaces)
	for id in BoardPath.ids():
		var node := BoardPath.node(id)
		for to in node.next:
			_ribbon(road, node, BoardPath.node(to))
			_dots(dots, node, BoardPath.node(to))
		if BoardPath.is_fork(id):
			_signpost(signposts, node)
		var space := Space.new(node.kind)
		space.name = id
		space.position = node.pos
		spaces.add_child(space)
	_flag()


# A dark, worn strip of road under the spaces, along the lane's curve, so the tokens stand out from
# whatever the ground is.
func _ribbon(parent: Node2D, from: Dictionary, to: Dictionary) -> void:
	var lane: BoardLayout.Lane = from.lane if from.lane != BoardLayout.Lane.MAIN else to.lane
	var line := Line2D.new()
	line.width = ROAD_WIDTH
	line.default_color = ROAD_COLOR
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	var steps := maxi(2, int(absf(to.pos.x - from.pos.x) / 30.0))
	for i in steps + 1:
		var x := lerpf(from.pos.x, to.pos.x, float(i) / steps)
		line.add_point(Vector2(x, BoardLayout.lane_y(lane, x)))
	parent.add_child(line)


# Scraps of paper between two neighbouring spaces, along the lane's curve. They lie in the gap
# between the two tokens, each a little different in size and turn.
func _dots(parent: Node2D, from: Dictionary, to: Dictionary) -> void:
	var lane: BoardLayout.Lane = from.lane if from.lane != BoardLayout.Lane.MAIN else to.lane
	var reach := Space.TOKEN.get_width() / 2.0 + 3.0
	var start: float = from.pos.x + reach
	var end: float = to.pos.x - reach
	for i in DOTS_BETWEEN:
		var x := lerpf(start, end, (i + 1.0) / (DOTS_BETWEEN + 1.0))
		var dot := Sprite2D.new()
		dot.texture = DOT
		dot.position = Vector2(x, BoardLayout.lane_y(lane, x))
		dot.rotation_degrees = _rng.randf_range(-40.0, 40.0)
		dot.scale = Vector2.ONE * _rng.randf_range(DOT_SIZE.x, DOT_SIZE.y)
		parent.add_child(dot)
		PaperShadow.add(dot)


# A signpost just behind the road, beside the fork's space, where the two paths part.
func _signpost(parent: Node2D, fork: Dictionary) -> void:
	var post := Sprite2D.new()
	post.texture = SIGNPOST
	post.centered = false
	post.offset = Vector2(-SIGNPOST.get_width() / 2.0, -SIGNPOST.get_height())
	post.scale = Vector2.ONE * SIGNPOST_SCALE
	post.position = fork.pos + Vector2(130.0, -34.0)
	parent.add_child(post)
	PaperShadow.add(post)
	var period := _rng.randf_range(4.0, 6.0)
	PaperMotion.sway(post, _rng.randf_range(0.5, 0.8), period).custom_step(_rng.randf_range(0.0, period))


# The flag planted beside the gate.
func _flag() -> void:
	var flag := Flag.new()
	flag.scale = Vector2.ONE * FLAG_SCALE
	flag.position = BoardPath.finish().pos + Vector2(230.0, -10.0)
	add_child(flag)
	PaperShadow.add(flag)
