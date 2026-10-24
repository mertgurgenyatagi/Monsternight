extends Control
## The title screen. The curtain opens on the logo under the night sky, and Play, Settings and
## Quit pop in. Quit closes the curtain before the window closes.

const CURTAIN_OPEN := 0.19 # how much of each half still shows when the curtain is open

@onready var _curtain: Curtain = $Curtain
@onready var _hanger: Node2D = $Hanger
@onready var _buttons: Array[PaperButton] = [$Play, $Settings, $Quit]


func _ready() -> void:
	Sound.play_music("title")
	for piece: CanvasItem in [$Hanger/Logo]:
		PaperShadow.add(piece)
	$Quit.pressed.connect(_quit)
	$Settings.pressed.connect(Settings.open)
	$Play.pressed.connect(Scenes.change_to.bind("res://src/setup/setup.tscn"))
	_lightning_loop()

	_curtain.move(CURTAIN_OPEN, 2.4, 0.9)
	PaperMotion.drop_in(_hanger, 900.0, 1.8, 1.9).finished \
			.connect(PaperMotion.sway.bind(_hanger, 1.2, 6.0))
	for i in _buttons.size():
		_buttons[i].enter(4.2 + i * 0.35)


func _quit() -> void:
	Sound.play_music("")
	for i in _buttons.size():
		_buttons[-1 - i].leave(i * 0.12)
	await _curtain.move(1.0, 1.4, 0.4).finished
	await get_tree().create_timer(0.35).timeout
	Sound.quit()


# Lightning strikes now and then, never at the same pace twice.
func _lightning_loop() -> void:
	await get_tree().create_timer(randf_range(6.0, 9.0), false).timeout
	while is_inside_tree():
		$Sky.flash()
		await get_tree().create_timer(randf_range(8.0, 16.0), false).timeout
