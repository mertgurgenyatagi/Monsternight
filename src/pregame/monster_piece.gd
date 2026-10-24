class_name MonsterPiece
extends MonsterFigure
## One monster on its paper stand in the select row. Its origin is the middle of the stand, on
## the ground. Its name always shows under the stand. It lifts on hover, stays lifted while it is the
## picker's selection, and greys out once it's taken.

signal clicked(piece: MonsterPiece)

const BODY_SCALE := 0.58
const STAND_SCALE := 0.85
const HIT := Rect2(-95, -310, 190, 340)
const CREAM := Color("efe4cc")
const GREY_TIME := 0.3
const NAME_FONT := preload("res://assets/fonts/display.ttf")
const NAME_WIDTH := 230.0
const NAME_SIZE := 40
const NAME_MIN := 26

var taken := false
## Only a free monster answers the mouse, and only while a player is picking.
var enabled := false : set = set_enabled

## The picker's choice, shown lifted until they confirm it or pick another.
var selected := false : set = set_selected

var _name: Label
var _hit: Control
var _grey: Array[ShaderMaterial] = []
var _hovered := false


func _init(monster_id := "") -> void:
	super(monster_id)
	body_scale = BODY_SCALE
	stand_scale = STAND_SCALE
	feet = Vector2(0, -10)


func _ready() -> void:
	super()

	# The name stays under the stand. Frankenstein's Monster is too long for one line, so it takes two.
	_name = Label.new()
	_name.size = Vector2(NAME_WIDTH, 100)
	_name.position = Vector2(-NAME_WIDTH / 2.0, 38)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_override("font", NAME_FONT)
	_name.add_theme_color_override("font_color", Monsters.color(id))
	_name.add_theme_color_override("font_outline_color", Color("1a1022"))
	_name.add_theme_constant_override("outline_size", 6)
	_name.add_theme_constant_override("line_spacing", -34)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_name(Monsters.display_name(id).replace(" ", "
") if id == "frankenstein" else Monsters.display_name(id))
	add_child(_name)

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


func set_selected(value: bool) -> void:
	if selected == value:
		return
	selected = value
	if value:
		PaperMotion.lift(self, true)
	elif get_meta("raised", false) and not _hovered:
		PaperMotion.lift(self, false)


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
	selected = false
	_set_name(picker_name)
	_name.add_theme_color_override("font_color", CREAM)
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


# Sets the name and shrinks it until the longest line fits under the stand.
func _set_name(text: String) -> void:
	_name.text = text
	var size := NAME_SIZE
	while size > NAME_MIN:
		var widest := 0.0
		for line in text.split("
"):
			widest = maxf(widest, NAME_FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
		if widest <= NAME_WIDTH - 8.0:
			break
		size -= 1
	_name.add_theme_font_size_override("font_size", size)


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
	_hovered = true
	if selected:
		return
	Sound.play("ui_hover")
	PaperMotion.lift(self, true)


func _on_mouse_exited() -> void:
	_hovered = false
	if not taken:
		_lower()


func _lower() -> void:
	if get_meta("raised", false) and not selected:
		PaperMotion.lift(self, false)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if taken:
			deny()
		elif enabled:
			clicked.emit(self)
