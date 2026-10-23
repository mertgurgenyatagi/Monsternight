extends Node2D
## The board. It opens on the castle gate, so everyone sees where the race ends, then glides
## back to the village start. Wherever the camera's centre is, the sky takes that location's
## tint and its ambience plays. The path, the pieces and the turns come in later parts.

## Each location's sky, top and bottom: colorful, never bleak.
const TINTS := {
	"village": [Color("1c1a4a"), Color("5f5ca8")], # misty violet-blue
	"graveyard": [Color("2a1746"), Color("3f7a62")], # green-violet
	"forest": [Color("0a2530"), Color("1b6f6c")], # deep teal
	"swamp": [Color("1c2612"), Color("7e912f")], # sickly olive-green
	"castle": [Color("2c0b36"), Color("a5182f")], # blood red and purple
}
const BAT_LOCATIONS := ["graveyard", "castle"]
const INTRO_HOLD := 2.0 # on the castle gate, counted from when the board starts to show
const INTRO_GLIDE := 6.0
const SKIP_GLIDE := 0.9

@onready var _camera: BoardCamera = $Camera
@onready var _sky: Control = $SkyLayer/Sky
@onready var _bats: Array[Node] = $Bats.get_children()

var _location := ""
var _intro := false
var _skipped := false


func _ready() -> void:
	Sound.play_music("")
	print("Board: ", Match.players)
	_camera.jump_to(BoardLayout.width())
	_track()
	_lightning_loop()
	_intro = true
	await get_tree().create_timer(INTRO_HOLD, false).timeout
	if not _skipped:
		_glide_home(INTRO_GLIDE)


func _process(_delta: float) -> void:
	_track()


# A click during the intro skips it: the camera hurries home instead.
func _unhandled_input(event: InputEvent) -> void:
	if _intro and not _skipped and event is InputEventMouseButton and event.pressed:
		_skipped = true
		get_viewport().set_input_as_handled()
		_glide_home(SKIP_GLIDE)


func _glide_home(duration: float) -> void:
	_camera.glide_to(0.0, duration).finished.connect(_intro_done)


func _intro_done() -> void:
	_intro = false
	print("Board ready")


# When the camera's centre crosses into another location, the sky and the ambience follow.
func _track() -> void:
	var location := BoardLayout.location_at(_camera.center_x())
	if location.id == _location:
		return
	var first := _location == ""
	_location = location.id
	var tint: Array = TINTS[_location]
	_sky.tint(tint[0], tint[1], 0.01 if first else 1.2)
	Sound.play_ambience(_location)
	for bat in _bats:
		bat.active = _location in BAT_LOCATIONS
	print("Location: %s at x %d" % [_location, _camera.center_x()])


# Over the castle, lightning strikes now and then, never at the same pace twice.
func _lightning_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(5.0, 11.0), false).timeout
		if _location == "castle":
			_sky.flash()
