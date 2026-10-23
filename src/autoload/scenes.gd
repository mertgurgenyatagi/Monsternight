extends Node
## What's on screen: changes scenes behind one paper sheet, lays the paper texture over
## everything, and shows the skeleton-hand cursor. Music carries on through a change; a scene that wants another track asks
## Sound for it in its _ready.

const SHEET_COLOR := Color("3a2140")
const PAPER_STRENGTH := 0.4

var _sheet: NinePatchRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_custom_mouse_cursor(preload("res://assets/art/ui/cursor.png"))

	var sheet_layer := CanvasLayer.new()
	sheet_layer.layer = 90
	add_child(sheet_layer)
	_sheet = NinePatchRect.new()
	_sheet.texture = preload("res://assets/art/ui/panel.png")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_sheet.set_patch_margin(side, 72)
	_sheet.self_modulate = SHEET_COLOR
	_sheet.size = Vector2(2300, 1460)
	_sheet.pivot_offset = _sheet.size / 2
	_sheet.visible = false
	sheet_layer.add_child(_sheet)
	PaperShadow.add(_sheet)

	var paper_layer := CanvasLayer.new()
	paper_layer.layer = 100
	add_child(paper_layer)
	var paper := TextureRect.new()
	paper.texture = preload("res://assets/art/scenery/paper_texture.png")
	paper.stretch_mode = TextureRect.STRETCH_TILE
	paper.set_anchors_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.modulate.a = PAPER_STRENGTH
	paper_layer.add_child(paper)


# Set from here rather than in the project settings, which leak the cursor texture at exit.
func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)


## Slides the paper sheet down over the screen, swaps the scene behind it, and slides it on
## and away.
func change_to(path: String) -> void:
	if _busy:
		return
	_busy = true
	var screen := get_viewport().get_visible_rect().size
	var center := (screen - _sheet.size) / 2
	_sheet.position = center - Vector2(0, _sheet.size.y + 100)
	_sheet.rotation_degrees = -5.0
	_sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	_sheet.visible = true
	Sound.play("flip")

	var cover := create_tween().set_parallel()
	cover.tween_property(_sheet, "position", center, 0.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cover.tween_property(_sheet, "rotation_degrees", 0.0, 0.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await cover.finished

	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed

	var reveal := create_tween().set_parallel()
	reveal.tween_property(_sheet, "position", center + Vector2(0, _sheet.size.y + 100), 0.55) \
			.set_delay(0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	reveal.tween_property(_sheet, "rotation_degrees", 5.0, 0.55) \
			.set_delay(0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await reveal.finished
	_sheet.visible = false
	_busy = false
