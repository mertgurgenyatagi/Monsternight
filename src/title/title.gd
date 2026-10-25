extends Control
## The title screen. The curtain opens on the logo under the night sky, and Online, Same screen,
## Settings and Quit pop in. Quit closes the curtain before the window closes.

const CURTAIN_OPEN := 0.19 # how much of each half still shows when the curtain is open

@onready var _curtain: Curtain = $Curtain
@onready var _hanger: Node2D = $Hanger
@onready var _buttons: Array[PaperButton] = [$Play, $SameScreen, $Settings, $Quit]


func _ready() -> void:
	Sound.play_music("title")
	for piece: CanvasItem in [$Hanger/Logo]:
		PaperShadow.add(piece)
	$Quit.pressed.connect(_quit)
	$Settings.pressed.connect(Settings.open)
	$Play.pressed.connect(Scenes.change_to.bind("res://src/lobby/lobby.tscn"))
	$SameScreen.pressed.connect(Scenes.change_to.bind("res://src/setup/setup.tscn"))
	_add_version()
	if OS.has_feature("web"): # a page cannot close itself
		_buttons.erase($Quit)
		$Quit.hide()
	_lightning_loop()
	_offer_rejoin()
	if Net.room_from_link() != "": # a shared link lands in its room, past the buttons
		get_tree().create_timer(1.0).timeout.connect(Scenes.change_to.bind("res://src/lobby/lobby.tscn"))

	_curtain.move(CURTAIN_OPEN, 2.4, 0.9)
	PaperMotion.drop_in(_hanger, 900.0, 1.8, 1.9).finished \
			.connect(PaperMotion.sway.bind(_hanger, 1.2, 6.0))
	for i in _buttons.size():
		_buttons[i].enter(4.2 + i * 0.35)


# The build's version, small in the bottom corner, so a bug report can say which one it came from.
func _add_version() -> void:
	var label := Label.new()
	label.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0")
	label.add_theme_font_override("font", preload("res://assets/fonts/body.ttf"))
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("efe4cc", 0.55))
	label.position = Vector2(760, 1030)
	label.size = Vector2(400, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


# A tab that was in an online match when it reloaded offers to go back: the room and the name are
# in the tab's sessionStorage. The buttons below it make room.
func _offer_rejoin() -> void:
	var seat := Online.saved_seat()
	if seat.room == "" or seat.name == "":
		return
	var button := PaperButton.new()
	button.size = Vector2(400, 104)
	button.text = tr("TITLE_REJOIN")
	button.add_theme_font_size_override("font_size", 48)
	add_child(button)
	var all: Array[PaperButton] = [button]
	all.append_array(_buttons)
	for i in all.size():
		all[i].size = Vector2(400, 90)
		all[i].position = Vector2(760, 560.0 + i * 100.0)
	_buttons.push_front(button)
	button.pressed.connect(_rejoin.bind(seat.room, seat.name))
	Online.rejoin_failed.connect(_on_rejoin_failed)


func _rejoin(room: String, player_name: String) -> void:
	_show_banner(tr("REJOINING"), false)
	Online.start_rejoin(room, player_name)


func _on_rejoin_failed(_reason: String) -> void:
	_show_banner(tr("REJOIN_FAILED"), true)


func _show_banner(text: String, red: bool) -> void:
	var banner := PaperBanner.new(text, red)
	banner.position = Vector2(960, 140)
	add_child(banner)
	Sound.play("ui_denied" if red else "ui_click", -4.0)
	await PaperMotion.drop_in(banner, 500.0, 0.5).finished
	await get_tree().create_timer(2.2, false).timeout
	if is_instance_valid(banner):
		await PaperMotion.lift_away(banner).finished
		if is_instance_valid(banner):
			banner.queue_free()


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

