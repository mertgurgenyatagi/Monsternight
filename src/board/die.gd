class_name Die
extends Node2D
## The pair of paper dice. They drop in above the active piece and wait to be clicked (`clicked`, a
## click on either one), then tumble together and land one after the other on the numbers the rules
## rolled, and the total pops above them. Its origin is the middle of the pair. It only shows numbers:
## `Match.roll` decides them.

## The dice have landed after dropping in, and take clicks.
signal offered
## The player clicked a die while they were offered.
signal clicked
## Both tumbles have ended on their faces and the total shows.
signal settled

const GAP := 100.0 # from the middle to each die
const LAND_GAP := 0.15 # the second die lands this long after the first
const DROP_GAP := 0.1
const TOTAL_RISE := 150.0
const TOTAL_SIZE := 96
const INK := Color("2a1a22")
const DISPLAY := preload("res://assets/fonts/display.ttf")

## False when another player rolls these dice online: they are only watched.
var clickable := true:
	set(value):
		clickable = value
		for cube in _cubes:
			cube.clickable = value

var _cubes: Array[DieCube] = []
var _total: Label


func _ready() -> void:
	for i in 2:
		var cube := DieCube.new()
		cube.clickable = clickable
		cube.clicked.connect(_on_clicked)
		add_child(cube)
		cube.place(Vector2((i * 2 - 1) * GAP, 0))
		_cubes.append(cube)
	_total = Label.new()
	_total.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_total.size = Vector2(200, 120)
	_total.pivot_offset = _total.size / 2
	_total.position = Vector2(-100, -TOTAL_RISE - 60)
	_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_total.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_total.add_theme_font_override("font", DISPLAY)
	_total.add_theme_font_size_override("font_size", TOTAL_SIZE)
	_total.add_theme_color_override("font_color", Color("fbe9d0"))
	_total.add_theme_color_override("font_outline_color", INK)
	_total.add_theme_constant_override("outline_size", 14)
	_total.visible = false
	add_child(_total)
	visible = false


## Sets where the pair rests, in its parent's space.
func place(at: Vector2) -> void:
	position = at
	rotation = 0.0
	scale = Vector2.ONE / BoardCamera.ZOOM # stays the size it was before the zoom
	set_meta("rest_position", at)
	set_meta("rest_scale", scale)
	_total.visible = false


## Drops in from above the screen, the second die a beat after the first, and wobbles until one is
## clicked. Awaiting the signal waits for both landings; from then on the dice take clicks.
func offer() -> Signal:
	visible = true
	_total.visible = false
	_offer()
	return offered


## Stops taking clicks (the click has been sent, and the host's answer is on its way).
func lock() -> void:
	for cube in _cubes:
		cube.lock()


## A small shake: the player's time ran out, so the dice roll by themselves.
func nudge() -> Tween:
	lock()
	var tween := PaperMotion.shake(_cubes[0])
	PaperMotion.shake(_cubes[1])
	return tween


## Tumbles both dice, spinning through random faces, and lands them on `values` ([first, second]) one
## after the other. The total pops when both are down. Awaiting the signal waits for the end.
func tumble(values: Array) -> Signal:
	_tumble(values)
	return settled


## Pops away.
func leave() -> Tween:
	lock()
	return PaperMotion.pop_out(self)


func _offer() -> void:
	_cubes[0].offer()
	_cubes[1].offer(DROP_GAP)
	await _cubes[1].offered
	offered.emit()


func _tumble(values: Array) -> void:
	_cubes[0].tumble(int(values[0]))
	_cubes[1].tumble(int(values[1]), LAND_GAP)
	await _cubes[0].settled
	await _cubes[1].settled
	_total.text = str(int(values[0]) + int(values[1]))
	_total.visible = true
	_total.scale = Vector2.ONE
	Sound.play("die_land", -4.0)
	PaperMotion.pop_in(_total)
	settled.emit()


func _on_clicked() -> void:
	lock()
	clicked.emit()
