class_name PaperButton
extends Button
## A paper tag button. It lifts on hover and squashes on click, each with its sound. It ignores
## the mouse until it has popped in.


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	PaperShadow.add(self)
	scale = Vector2.ZERO
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(PaperMotion.lift.bind(self, false))
	button_down.connect(_on_button_down)


# A disabled button is greyed out and ignores the mouse's hover.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED:
		self_modulate = Color(0.55, 0.55, 0.58, 0.8)
	elif what == NOTIFICATION_ENABLED:
		self_modulate = Color.WHITE


## Pops in after `delay` seconds, then answers the mouse.
func enter(delay := 0.0) -> void:
	await PaperMotion.pop_in(self, delay).finished
	mouse_filter = Control.MOUSE_FILTER_STOP


## Stops answering the mouse and pops away.
func leave(delay := 0.0) -> Tween:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return PaperMotion.pop_out(self, delay)


func _on_mouse_entered() -> void:
	if disabled:
		return
	Sound.play("ui_hover")
	PaperMotion.lift(self, true)


func _on_button_down() -> void:
	Sound.play("ui_click")
	PaperMotion.squash(self)
