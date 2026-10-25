class_name Space
extends Node2D
## One space on the road. Its origin is the middle of its token, which lies flat on the ground
## as a squashed oval; the icon stands up on it like a small cutout. The token takes a tint from
## its kind, so every space reads at a glance: the quick spaces each have their own color, the
## four duel spaces share one, and an empty space, where nothing happens, is plain paper. The
## token wears a dark outline and the icon a cream one, so both stand out from the scenery.
##
## The token and the icons are baked at the size they're drawn, outline and all, by
## `tools/images/make_outlines.py`: the token is `space.png` squashed into a flat oval, as seen
## from a low angle. Change a size there and here together.

const TOKEN := preload("res://assets/art/board/space_rim.png")
const ICON := "res://assets/art/icons/%s_rim.png"
const ICON_PAD := 6.0 # the outline's room under an icon's feet
const ICON_FOOT := 9.0 # how far below the token's middle the icon stands
const PLAIN := Color("e4dccb")
const DUEL := Color("9a62e8")
const TINTS := {
	"start": PLAIN, "finish": PLAIN, "empty": PLAIN,
	"coin": Color("ffc21f"),
	"spikes": Color("4f8ad8"),
	"thief": Color("2fb06f"),
	"church": Color("fff0c8"),
	"atlas": DUEL, "archive": DUEL, "lab": DUEL, "stage": DUEL,
}
const DUELS := ["atlas", "archive", "lab", "stage"]
const JUMP := 22.0 # how high an icon jumps when a piece lands
const CHURCH_LIGHT := Color(1.0, 0.78, 0.4, 0.5)

static var _pool: GradientTexture2D

var kind := ""
var token: Sprite2D
var icon: Sprite2D
var glow: Glow # a church's light

var _breathing: Tween
var _rise := 3.0
var _period := 2.6


func _init(kind_: String = "") -> void:
	kind = kind_


func _ready() -> void:
	token = Sprite2D.new()
	token.texture = TOKEN
	token.modulate = TINTS[kind]
	add_child(token)
	PaperShadow.add(token)
	# A token lies on the ground, so its shadow is small and close.
	token.get_node("Shadow").position = Vector2(2.5, 4.0)
	if kind in ["start", "finish", "empty"]:
		return
	if kind == "church":
		glow = Glow.new(CHURCH_LIGHT, 105.0)
		glow.scale.y *= 0.6
		glow.position = Vector2(0, -26)
		add_child(glow)
		glow.pulse(0.1, 0.5, 3.2)
	_stand_icon()


func _stand_icon() -> void:
	var texture: Texture2D = load(ICON % kind)
	var foot := Vector2(0, ICON_FOOT)
	# A small dark pool where the icon's feet touch the token.
	var pool := Sprite2D.new()
	pool.texture = _pool_texture()
	pool.position = foot
	pool.scale = Vector2(texture.get_width() * 1.1 / pool.texture.get_width(), 0.2)
	add_child(pool)
	icon = Sprite2D.new()
	icon.texture = texture
	icon.centered = false
	# The origin is the middle of the base of the picture, so the icon stands on it.
	icon.offset = Vector2(-texture.get_width() / 2.0, -(texture.get_height() - ICON_PAD))
	icon.position = foot
	add_child(icon)
	PaperShadow.add(icon)
	_rise = randf_range(2.5, 4.0)
	_period = randf_range(2.4, 3.4)
	rest()
	if kind in DUELS:
		_repeat(func() -> void: PaperMotion.tilt(icon, randf_range(5.0, 8.0)), Vector2(2.5, 6.0))
	elif kind == "coin":
		_repeat(func() -> void: PaperMotion.squash(icon), Vector2(3.0, 7.0))


## The icon stops breathing and jumps a little, as the piece lands on its space.
func wake() -> Tween:
	_breathing.kill()
	icon.position = Vector2(0, ICON_FOOT)
	icon.set_meta("rest_position", icon.position)
	return PaperMotion.hop(icon, JUMP)


## The icon breathes again, after `wake`.
func rest() -> void:
	_breathing = PaperMotion.breathe(icon, _rise, _period)


## Where the top of the icon is on screen, for things that fly from or to it.
func icon_top() -> Vector2:
	return icon.get_global_transform_with_canvas() * Vector2(0, -icon.texture.get_height() * 0.8)


# Does `action` now and then, never at the same pace twice.
func _repeat(action: Callable, wait: Vector2) -> void:
	await get_tree().create_timer(randf_range(0.0, wait.y), false).timeout
	while is_inside_tree():
		action.call()
		await get_tree().create_timer(randf_range(wait.x, wait.y), false).timeout


# A soft dark round spot, squashed flat into a pool where an icon touches its token.
static func _pool_texture() -> GradientTexture2D:
	if _pool == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(0.1, 0.05, 0.15, 0.55))
		gradient.set_color(1, Color(0.1, 0.05, 0.15, 0.0))
		_pool = GradientTexture2D.new()
		_pool.gradient = gradient
		_pool.fill = GradientTexture2D.FILL_RADIAL
		_pool.fill_from = Vector2(0.5, 0.5)
		_pool.fill_to = Vector2(1.0, 0.5)
		_pool.width = 128
		_pool.height = 128
	return _pool
