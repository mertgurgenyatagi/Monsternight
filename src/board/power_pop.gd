class_name PowerPop
extends Node2D
## A small paper label that pops over a piece or the die when a power fires: it pops in with the
## `power` sound, rises a little while it holds, then pops out and frees itself. Its origin is the
## label's middle.

const HEIGHT := 64.0
const MIN_WIDTH := 120.0
const SIDE_PAD := 44.0
const FONT_SIZE := 44
const RISE := 56.0
const INK := Color("2a1746")
const CREAM := Color(1.0, 0.93, 0.78)
const DISPLAY := preload("res://assets/fonts/display.ttf")


func _init(text := "") -> void:
	var width := maxf(MIN_WIDTH, DISPLAY.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + SIDE_PAD)
	var size := Vector2(width, HEIGHT)
	var paper := Sprite2D.new()
	paper.texture = preload("res://assets/art/ui/panel.png")
	paper.scale = size / paper.texture.get_size()
	paper.self_modulate = CREAM
	add_child(paper)
	PaperShadow.add(paper)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", DISPLAY)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = size
	label.position = -size / 2.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


## Pops a label with `text` in at `at`, in `parent`'s space, `scale_factor` times its size (for the
## board's zoomed world). It frees itself once it's gone; awaiting `finished` on the result's
## tween isn't needed, since the board goes on while it floats.
static func show_over(parent: Node, at: Vector2, text: String, scale_factor := 1.0, hold := 0.9) -> PowerPop:
	var pop := PowerPop.new(text)
	pop.position = at
	pop.scale = Vector2.ONE * scale_factor
	pop.set_meta("rest_scale", pop.scale)
	pop.rotation_degrees = -4.0
	parent.add_child(pop)
	PaperMotion.pop_in(pop)
	Sound.play("power")
	var rise := pop.create_tween()
	rise.tween_property(pop, "position:y", at.y - RISE * scale_factor, hold + 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	rise.parallel().tween_callback(func() -> void:
			PaperMotion.pop_out(pop, 0.0).finished.connect(pop.queue_free)).set_delay(hold)
	return pop
