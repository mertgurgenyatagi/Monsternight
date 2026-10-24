class_name MonsterPiece
extends MonsterFigure
## One monster on its paper stand in the select row. Its origin is the middle of the stand, on
## the ground. It lifts and shows its name on hover, and greys out once it's taken.

signal clicked(piece: MonsterPiece)

const BODY_SCALE := 0.58
const STAND_SCALE := 0.85
const HIT := Rect2(-95, -310, 190, 340)
const CREAM := Color("efe4cc")
const GREY_TIME := 0.3
const POWER_FONT := preload("res://assets/fonts/display.ttf")
const POWER_WIDTH := 200.0
const POWER_HEIGHT := 64.0
const POWER_SIZE := 24
const POWER_MIN := 16

var taken := false
## Only a free monster answers the mouse, and only while a player is picking.
var enabled := false : set = set_enabled

var _name: Label
var _power: Label
var _hit: Control
var _grey: Array[ShaderMaterial] = []


func _init(monster_id := "") -> void:
	super(monster_id)
	body_scale = BODY_SCALE
	stand_scale = STAND_SCALE
	feet = Vector2(0, -10)


func _ready() -> void:
	super()

	_name = Label.new()
	_name.size = Vector2(240, 60)
	_name.position = Vector2(-120, 38)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_override("font", preload("res://assets/fonts/display.ttf"))
	_name.add_theme_font_size_override("font_size", 40)
	_name.add_theme_color_override("font_color", Monsters.color(id))
	_name.text = Monsters.display_name(id)
	_name.modulate.a = 0.0
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)

	# The power line stays under the stand, in the display font, so everyone can read all eight.
	_power = Label.new()
	_power.size = Vector2(POWER_WIDTH, POWER_HEIGHT)
	_power.position = Vector2(-POWER_WIDTH / 2.0, 96)
	_power.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_power.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_power.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_power.add_theme_font_override("font", POWER_FONT)
	_power.add_theme_color_override("font_color", CREAM)
	_power.add_theme_color_override("font_outline_color", Color("1a1022"))
	_power.add_theme_constant_override("outline_size", 6)
	_power.add_theme_constant_override("line_spacing", -4)
	_power.text = tr(Monsters.power_key(id))
	_power.add_theme_font_size_override("font_size", _fitting_power_size())
	_power.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_power)

	_hit = Control.new()
	_hit.position = HIT.position
	_hit.size = HIT.size
	_hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hit.mouse_entered.connect(_on_mouse_entered)
	_hit.mouse_exited.connect(_on_mouse_exited)
	_hit.gui_input.connect(_on_gui_input)
	add_child(_hit)


func set_enabled(value: bool) -> void:
	enabled = value
	if _hit:
		_hit.mouse_filter = Control.MOUSE_FILTER_STOP if value or taken else Control.MOUSE_FILTER_IGNORE
	if not value and not taken:
		_lower()


## Sways gently, out of step with the others. Rotates the body about its feet.
func start_sway(delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	if taken:
		return
	PaperMotion.sway(_body, randf_range(1.2, 2.2), randf_range(3.2, 5.0))


## Greys out and darkens, stops swaying, and puts the picker's name under it in plain paper ink.
func take(picker_name: String) -> void:
	taken = true
	_lower()
	PaperMotion.sway_stop(_body)
	_name.text = picker_name
	_name.add_theme_color_override("font_color", CREAM)
	_fade_name(1.0)
	create_tween().tween_property(_power, "modulate", Color(0.6, 0.6, 0.6, 0.55), GREY_TIME)
	create_tween().tween_method(func(amount: float) -> void:
			for mat in _grey:
				mat.set_shader_parameter("amount", amount), 0.0, 1.0, GREY_TIME)
	_hit.mouse_filter = Control.MOUSE_FILTER_STOP


## The point the monster's portrait flies up from.
func head_position() -> Vector2:
	return global_position + Vector2(0, -body_height() * 0.8)


## A click on a taken monster: refused with a sound and a shake.
func deny() -> void:
	Sound.play("ui_denied")
	PaperMotion.shake(self)


# The biggest size at which the power line fits its two lines.
func _fitting_power_size() -> int:
	var size := POWER_SIZE
	while size > POWER_MIN:
		var lines := POWER_FONT.get_multiline_string_size(_power.text, HORIZONTAL_ALIGNMENT_LEFT,
				POWER_WIDTH - 8.0, size)
		if lines.y <= POWER_HEIGHT and lines.x <= POWER_WIDTH - 8.0:
			break
		size -= 1
	return size


func _make_sprite(texture: Texture2D, centered: bool) -> Sprite2D:
	var sprite := super(texture, centered)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/pregame/grey.gdshader")
	sprite.material = mat
	_grey.append(mat)
	return sprite


func _on_mouse_entered() -> void:
	if taken or not enabled:
		return
	Sound.play("ui_hover")
	PaperMotion.lift(self, true)
	_fade_name(1.0)


func _on_mouse_exited() -> void:
	if not taken:
		_lower()


func _lower() -> void:
	if get_meta("raised", false):
		PaperMotion.lift(self, false)
	if not taken:
		_fade_name(0.0)


func _fade_name(alpha: float) -> void:
	create_tween().tween_property(_name, "modulate:a", alpha, 0.18)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if taken:
			deny()
		elif enabled:
			clicked.emit(self)
