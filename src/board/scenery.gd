extends Node2D
## The board's scenery: five paper locations side by side, built from `BoardLayout` across the
## parallax layers. Each location has a far strip, a ground strip and its props, and every
## piece is placed from the layout, so moving a lane or a location moves the scenery with it.
##
## Layers, back to front: Far (the skylines), Mid (houses, trees and the castle), Lanes (the
## ground, the road and what stands on it, at the camera's speed) and Fog (in front of it all,
## a little faster than the camera).

const ART := "res://assets/art/scenery/%s.png"
const STRIP_SHADER := preload("res://src/board/strip.gdshader")
const FAR_SCALE := 0.75
const FAR_Y := 380.0
const FAR_OVERLAP := 700.0 # how far neighbouring strips blend into each other, in world x
const GROUND_OVERLAP := 360.0
const FOG_OVERLAP := 900.0
## How thick the fog lies over each location: the foreground wisps, and a thick bank behind the
## houses where it's high.
const FOG := {"village": 0.75, "graveyard": 0.35, "forest": 0.0, "swamp": 0.7, "castle": 0.0}
## How much of the foreground fog stays, so the road and what stands on it read clearly.
const FOREGROUND_FOG := 0.5
## The brightness of the layers behind the road and of the ground itself: dimmer, so the spaces
## and the monsters stand out.
const DIM := {"far": 0.78, "mid": 0.74, "ground": 0.8}
const FOG_BANK_FROM := 0.6
## How much lower a location's ground lies than the others, to show what's behind it.
const GROUND_DROP := {"swamp": 110.0}
const WATER_Y := 700.0
const LAMP_LIGHT := Color(1.0, 0.78, 0.4, 0.55)
const TORCH_LIGHT := Color(1.0, 0.55, 0.25, 0.5)
const MUSHROOM_LIGHT := Color(0.35, 1.0, 0.85, 0.45)

@onready var _far: Parallax2D = $Far
@onready var _mid: Parallax2D = $Mid
@onready var _lanes: Parallax2D = $Lanes
@onready var _fog: Parallax2D = $Fog

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 6
	_far.modulate = Color.WHITE * DIM.far
	_mid.modulate = Color.WHITE * DIM.mid
	var locations := BoardLayout.locations()
	for i in locations.size():
		var location := locations[i]
		var first := i == 0
		var last := i == locations.size() - 1
		_strip(_far, location.id + "_far", location, FAR_Y, FAR_SCALE, FAR_OVERLAP, first, last)
		var fog: float = FOG[location.id]
		if fog >= FOG_BANK_FROM:
			_fog_band(_mid, "fog_2", location, 600.0, 1.0, fog * 0.7, -7.0)
	# The props stand behind their location's ground strip, so the strips come after them.
	_village(BoardLayout.location("village"))
	_graveyard(BoardLayout.location("graveyard"))
	_forest(BoardLayout.location("forest"))
	_swamp(BoardLayout.location("swamp"))
	_castle(BoardLayout.location("castle"))
	for i in locations.size():
		var location := locations[i]
		var ground := _strip(_lanes, location.id + "_ground", location, _ground_y(location), 1.0,
				GROUND_OVERLAP, i == 0, i == locations.size() - 1)
		ground.self_modulate = Color.WHITE * DIM.ground
		var fog: float = FOG[location.id]
		if fog > 0.0:
			_fog_band(_fog, "fog_1", location, 930.0, 0.75, fog * 0.6 * FOREGROUND_FOG, 11.0)
			_fog_band(_fog, "fog_2", location, 975.0, 0.6, fog * 0.5 * FOREGROUND_FOG, -6.0)


# ---- the locations ----


func _village(location: Dictionary) -> void:
	var houses := _spots(location, 0.1, 0.8, 580.0)
	for i in houses.size():
		_mid_prop(location, "village_house_%d" % (1 + i % 2), houses[i], _rng.randf_range(0.78, 0.82),
				(i / 2) % 2 == 1)
	for at in _spots(location, 0.2, 0.93, 600.0):
		# The post is left of the picture's middle, so the lamp stands on its foot there.
		var lamp := _prop(_lanes, "village_lamp", _x(location, at), BoardLayout.GROUND_Y + 40, 0.7, false, 50.0)
		var glow := Glow.new(LAMP_LIGHT, 110.0)
		glow.position = Vector2(0, -415)
		glow.scale /= lamp.scale
		lamp.add_child(glow)
		glow.flicker()


func _graveyard(location: Dictionary) -> void:
	_tall(location, "graveyard_tree", 0.0, 0.85, false, 1.0) # on the seam with the village
	_tall(location, "graveyard_tree", 0.3, 0.8, true, 1.0)
	_tall(location, "graveyard_tree", 0.74, 0.88, false, 1.0)
	# The church path runs over the hill, with the church on top behind it.
	var hill_x: float = location.from
	var church_x := hill_x + BoardLayout.hill_width() * 0.56
	_prop(_lanes, "church_building", church_x, BoardLayout.HILL_TOP_Y + 30, 0.42)
	var hill := Sprite2D.new()
	hill.texture = load(ART % "church_hill")
	hill.centered = false
	hill.position = Vector2(hill_x, BoardLayout.HILL_TOP_Y - 140)
	hill.scale.x = BoardLayout.hill_width() / BoardLayout.HILL_IMAGE_WIDTH # stretched to the church path
	_lanes.add_child(hill)
	PaperShadow.add(hill)
	# Tombstones lean this way and that in front of the hill, below the church path.
	var stones := ["graveyard_stone_1", "graveyard_stone_2"]
	var spots := _spots(location, 0.07, 0.95, 300.0)
	for i in spots.size():
		var stone := _prop(_lanes, stones[i % 2], _x(location, spots[i]), BoardLayout.GROUND_Y + 45,
				_rng.randf_range(0.5, 0.62), _rng.randf() < 0.5)
		stone.rotation_degrees = _rng.randf_range(-6.0, 6.0)


func _forest(location: Dictionary) -> void:
	_tall(location, "forest_tree_1", 0.0, 0.78, false, 0.8) # on the seam with the graveyard
	var trees := _spots(location, 0.24, 0.76, 515.0)
	for i in trees.size():
		_tall(location, "forest_tree_%d" % (2 - i % 2), trees[i], _rng.randf_range(0.7, 0.78), i % 3 != 2, 0.8)
	for at in _spots(location, 0.1, 0.9, 530.0):
		var mushrooms := _prop(_lanes, "forest_mushrooms", _x(location, at), BoardLayout.GROUND_Y + 35,
				_rng.randf_range(0.55, 0.75), _rng.randf() < 0.5)
		var glow := Glow.new(MUSHROOM_LIGHT, 120.0)
		glow.position = Vector2(0, -110)
		glow.scale /= mushrooms.scale
		mushrooms.add_child(glow)
		glow.pulse(0.2, 0.5, _rng.randf_range(2.4, 3.6))


func _swamp(location: Dictionary) -> void:
	_tall(location, "swamp_tree", 0.0, 0.75, false, 0.9) # on the seam with the forest
	_tall(location, "swamp_tree", 0.4, 0.68, true, 0.9)
	_tall(location, "swamp_tree", 0.82, 0.72, false, 0.9)
	# The boardwalk carries the upper path, and the water laps at its posts.
	var walk_from: float = location.from + location.ramp * 0.5
	var walk_to: float = location.to - location.ramp * 0.5
	PaperShadow.add(_tiled(_lanes, "swamp_boardwalk", walk_from, walk_to, BoardLayout.UPPER_Y - 1.0, 1.0))
	var water := _tiled(_lanes, "swamp_water", location.from - 150.0, location.to + 150.0, WATER_Y, 1.0, 200.0, 200.0, 9.0)
	water.scale.y = 1.4 # deep enough to reach under the bank's ragged edge
	var bob := water.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(water, "position:y", water.position.y + 7.0, 2.2)
	bob.tween_property(water, "position:y", water.position.y - 3.0, 2.2)
	for at in _spots(location, 0.05, 0.88, 330.0):
		var reeds := _prop(_lanes, "swamp_reeds", _x(location, at), _ground_y(location) + 45,
				_rng.randf_range(0.5, 0.65), _rng.randf() < 0.5)
		_sway(reeds, 2.2)


func _castle(location: Dictionary) -> void:
	_tall(location, "graveyard_tree", 0.0, 0.82, true, 1.0) # on the seam with the swamp
	_mid_prop(location, "castle", 0.4, 0.52, false)
	for at in _spots(location, 0.12, 0.78, 665.0):
		_torch(_x(location, at), BoardLayout.GROUND_Y + 50, 0.8)
	# The castle gate is the finish, at the very end of the road, with a torch on either side.
	var gate_x := BoardLayout.gate_x()
	_prop(_lanes, "castle_gate", gate_x, BoardLayout.PROP_BASE_Y, 0.8)
	for side in [-1.0, 1.0]:
		_torch(gate_x + side * 150.0, BoardLayout.PROP_BASE_Y - 220.0, 0.7, side > 0.0)


# ---- the pieces ----


# Shares of the way across a location from `first` to `last`, about `gap` px apart, so a longer
# location gets more props and keeps the density it was drawn for.
func _spots(location: Dictionary, first: float, last: float, gap: float) -> Array[float]:
	var count := maxi(2, roundi((last - first) * (location.to - location.from) / gap) + 1)
	var result: Array[float] = []
	for i in count:
		result.append(lerpf(first, last, float(i) / (count - 1)))
	return result


# A tall prop in the mid layer, swaying gently from its base if `sway` is more than 0.
func _tall(location: Dictionary, art: String, at: float, size: float, flipped: bool, sway: float) -> Sprite2D:
	var prop := _mid_prop(location, art, at, size, flipped)
	_sway(prop, sway)
	return prop


# A prop in the mid layer at a share of the way across its location (0 stands on the seam with
# the location before).
func _mid_prop(location: Dictionary, art: String, at: float, size: float, flipped: bool) -> Sprite2D:
	var x := BoardLayout.layer_x(_x(location, at), _mid.scroll_scale.x)
	return _prop(_mid, art, x, BoardLayout.PROP_BASE_Y, size, flipped)


# A paper cutout whose origin is its foot, with its shadow. `x` is in the layer's own
# coordinates. The foot is the middle of the picture's base, or `foot_x` pixels from its left.
func _prop(layer: Node2D, art: String, x: float, base_y: float, size: float, flipped := false,
		foot_x := -1.0) -> Sprite2D:
	var prop := Sprite2D.new()
	prop.texture = load(ART % art)
	var width := prop.texture.get_width()
	if foot_x < 0.0:
		foot_x = width / 2.0
	prop.centered = false
	prop.offset = Vector2(-(width - foot_x if flipped else foot_x), -prop.texture.get_height())
	prop.flip_h = flipped
	prop.position = Vector2(x, base_y)
	prop.scale = Vector2.ONE * size
	layer.add_child(prop)
	PaperShadow.add(prop)
	return prop


func _torch(x: float, base_y: float, size: float, flipped := false) -> void:
	var torch := _prop(_lanes, "castle_torch", x, base_y, size, flipped)
	var cup := Vector2(48.0 - 40.5, 6.0 - 250.0) # the top of the cup, from the base's middle
	if flipped:
		cup.x = -cup.x
	var glow := Glow.new(TORCH_LIGHT, 120.0)
	glow.position = cup + Vector2(0, -40)
	glow.scale /= torch.scale
	glow.jitter = 0.25
	torch.add_child(glow)
	var flame := Flame.new()
	flame.position = cup
	flame.scale = Vector2.ONE * 0.85
	torch.add_child(flame)


# Sways very slightly from its base, out of step with every other piece.
func _sway(prop: Sprite2D, degrees: float) -> void:
	var period := _rng.randf_range(3.5, 6.0)
	PaperMotion.sway(prop, degrees * _rng.randf_range(0.7, 1.0), period).custom_step(_rng.randf_range(0.0, period))


# A location's strip, tiled across it in a layer, blending into its neighbours. The first and
# last strips run past the board's ends, far enough to fill the screen at the camera's limits.
func _strip(layer: Parallax2D, art: String, location: Dictionary, y: float, size: float,
		overlap: float, first: bool, last: bool) -> Sprite2D:
	var beyond := 960.0 / layer.scroll_scale.x - 960.0 + 200.0
	var from: float = location.from - (beyond if first else overlap / 2)
	var to: float = location.to + (beyond if last else overlap / 2)
	var scroll := layer.scroll_scale.x
	return _tiled(layer, art, BoardLayout.layer_x(from, scroll), BoardLayout.layer_x(to, scroll), y, size,
			0.0 if first else overlap * scroll / 2, 0.0 if last else overlap * scroll / 2)


# Fog over a location, drifting sideways and fading out at its ends.
func _fog_band(layer: Parallax2D, art: String, location: Dictionary, y: float, size: float,
		alpha: float, drift: float) -> void:
	var scroll := layer.scroll_scale.x
	var from := BoardLayout.layer_x(location.from - FOG_OVERLAP / 2, scroll)
	var to := BoardLayout.layer_x(location.to + FOG_OVERLAP / 2, scroll)
	var fade := FOG_OVERLAP * scroll
	var band := _tiled(layer, art, from, to, y, size, fade, fade, drift)
	band.modulate.a = alpha


# A strip tiled from `from` to `to` in a layer's coordinates, its top at `y`. The fades and the
# drift are in the layer's pixels.
func _tiled(layer: Node2D, art: String, from: float, to: float, y: float, size: float,
		fade_in := 0.0, fade_out := 0.0, drift := 0.0) -> Sprite2D:
	var strip := Sprite2D.new()
	strip.texture = load(ART % art)
	strip.centered = false
	strip.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	strip.region_enabled = true
	var width := (to - from) / size
	strip.region_rect = Rect2(_rng.randf_range(0.0, strip.texture.get_width()), 0, width, strip.texture.get_height())
	strip.position = Vector2(from, y)
	strip.scale = Vector2.ONE * size
	var material := ShaderMaterial.new()
	material.shader = STRIP_SHADER
	material.set_shader_parameter("width", width)
	material.set_shader_parameter("fade_in", fade_in / size)
	material.set_shader_parameter("fade_out", fade_out / size)
	material.set_shader_parameter("drift", drift)
	strip.material = material
	layer.add_child(strip)
	return strip


func _ground_y(location: Dictionary) -> float:
	return BoardLayout.GROUND_Y + GROUND_DROP.get(location.id, 0.0)


# World x at a share of the way across a location.
func _x(location: Dictionary, at: float) -> float:
	return lerpf(location.from, location.to, at)
