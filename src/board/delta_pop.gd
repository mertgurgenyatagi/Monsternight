class_name DeltaPop
extends Node2D
## A small paper tag that says what a player just gained or lost, like "-1" beside a blood drop or a
## coin: it pops in over their piece, rises a little, then pops out and frees itself. Red for a loss,
## green for a gain. Its origin is the tag's middle. `kind` is "blood", "coins" or "turn" (no icon).

const HEIGHT := 72.0
const SIDE_PAD := 40.0
const ICON_SIZE := 48.0
const FONT_SIZE := 52
const RISE := 64.0
const GAIN := Color("2c7a42")
const LOSS := Color("b0243a")
const CREAM := Color(1.0, 0.93, 0.78)
const DISPLAY := preload("res://assets/fonts/display.ttf")
const ICONS := {
	"blood": preload("res://assets/art/icons/blood.png"),
	"coins": preload("res://assets/art/icons/coin.png"),
}


func _init(amount := 0, kind := "blood") -> void:
	var text := ("+%d" if amount > 0 else "%d") % amount
	if kind == "turn":
		text += " " + TranslationServer.translate("POP_TURN")
	var text_width := DISPLAY.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var icon_width := ICON_SIZE + 8.0 if ICONS.has(kind) else 0.0
	var size := Vector2(text_width + icon_width + SIDE_PAD, HEIGHT)
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
	label.add_theme_color_override("font_color", GAIN if amount > 0 else LOSS)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(text_width + 8.0, HEIGHT)
	label.position = Vector2(-size.x / 2.0 + SIDE_PAD / 2.0 - 4.0, -HEIGHT / 2.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	if ICONS.has(kind):
		var icon := Sprite2D.new()
		icon.texture = ICONS[kind]
		icon.scale = Vector2.ONE * ICON_SIZE / maxf(icon.texture.get_width(), icon.texture.get_height())
		icon.position = Vector2(size.x / 2.0 - SIDE_PAD / 2.0 - ICON_SIZE / 2.0 + 2.0, 0.0)
		add_child(icon)


## Pops a tag for `amount` of `kind` in at `at`, in `parent`'s space, `scale_factor` times its size.
## It frees itself once it's gone, and the board goes on while it floats.
static func show_over(parent: Node, at: Vector2, amount: int, kind: String, scale_factor := 1.0,
		hold := 1.1) -> DeltaPop:
	var pop := DeltaPop.new(amount, kind)
	pop.position = at
	pop.scale = Vector2.ONE * scale_factor
	pop.set_meta("rest_scale", pop.scale)
	pop.rotation_degrees = 3.0
	parent.add_child(pop)
	PaperMotion.pop_in(pop)
	var rise := pop.create_tween()
	rise.tween_property(pop, "position:y", at.y - RISE * scale_factor, hold + 0.45) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	rise.parallel().tween_callback(func() -> void:
			PaperMotion.pop_out(pop, 0.0).finished.connect(pop.queue_free)).set_delay(hold)
	return pop
