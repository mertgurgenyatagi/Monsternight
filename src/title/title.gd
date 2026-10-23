extends Control
## The title screen. The curtain opens on the logo under the night sky, and Play, Settings and
## Quit pop in. Quit closes the curtain before the window closes.

const CURTAIN_OPEN := 0.19 # how much of each half still shows when the curtain is open

@onready var _halves: Array[Sprite2D] = [$Curtain/Left, $Curtain/Right]
@onready var _curtain_top: Sprite2D = $Curtain/Top
@onready var _hanger: Node2D = $Hanger
@onready var _buttons: Array[PaperButton] = [$Play, $Settings, $Quit]


func _ready() -> void:
	Sound.play_music("title")
	for piece: CanvasItem in [$Hanger/Logo, $Curtain/Left, $Curtain/Right, _curtain_top]:
		PaperShadow.add(piece)
	$Quit.pressed.connect(_quit)
	_lightning_loop()

	_move_curtain(CURTAIN_OPEN, 2.4, 0.9)
	PaperMotion.drop_in(_hanger, 900.0, 1.8, 1.9).finished \
			.connect(PaperMotion.sway.bind(_hanger, 1.2, 6.0))
	for i in _buttons.size():
		_buttons[i].enter(4.2 + i * 0.35)


func _quit() -> void:
	Sound.play_music("")
	for i in _buttons.size():
		_buttons[-1 - i].leave(i * 0.12)
	await _move_curtain(1.0, 1.4, 0.4).finished
	await get_tree().create_timer(0.35).timeout
	get_tree().quit()


# The halves gather toward the sides (or spread back), easing to a stop past the mark and
# settling onto it, while their hems trail behind and swing back. The rod jolts as they go.
func _move_curtain(spread: float, duration: float, delay: float) -> Tween:
	var opening := spread < _halves[0].scale.x
	var past := spread + (-0.025 if opening else 0.0)
	var tween := create_tween().set_parallel()
	for half in _halves:
		var side := 1.0 if half == _halves[0] else -1.0
		var lean := 0.06 * side * (1.0 if opening else -1.0)
		tween.tween_property(half, "scale:x", past, duration).set_delay(delay) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if opening else Tween.EASE_IN_OUT)
		tween.tween_property(half, "scale:x", spread, 0.5).set_delay(delay + duration) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(half, "skew", lean, duration * 0.5).set_delay(delay) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(half, "skew", -lean * 0.4, duration * 0.5).set_delay(delay + duration * 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(half, "skew", 0.0, 0.6).set_delay(delay + duration) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_curtain_top, "position:y", -7.0, 0.15).set_delay(delay) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_curtain_top, "position:y", 0.0, 0.5).set_delay(delay + 0.15) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween


# Lightning strikes now and then, never at the same pace twice.
func _lightning_loop() -> void:
	await get_tree().create_timer(randf_range(6.0, 9.0), false).timeout
	while is_inside_tree():
		$Sky.flash()
		await get_tree().create_timer(randf_range(8.0, 16.0), false).timeout
