extends Node2D
## The board. It opens on the castle gate, so everyone sees where the race ends, then glides
## back to the village start. Wherever the camera's centre is, the sky takes that location's
## tint and its ambience plays. It lays the road across the scenery, sets every player's monster down
## on the start, and walks the pieces along the road. The turns come in later parts.

## Every piece has landed on the start.
signal pieces_landed

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
const DROP_GAP := 0.45 # between one piece dropping onto the start and the next
const HOP_BEAT := 0.12 # between two hops, so a roll of 6 can be counted by ear
const BRANCH_BEAT := 0.5 # how long the placeholder takes to pick a path
const CROWD_STEP := 52.0 # across a space, from one piece to the next
const CROWD_ROW := 4 # pieces in a row, then the next row stands behind
const CROWD_FRONT := Vector2(0, 16) # the front row's feet, from the token's middle
const CROWD_BACK := 34.0 # how far each row further back stands higher

@onready var _camera: BoardCamera = $Camera
@onready var _sky: Control = $SkyLayer/Sky
@onready var _bats: Array[Node] = $Bats.get_children()

var _location := ""
var _intro := false
var _skipped := false
var _pieces: Node2D
var _by_monster := {} # monster id -> its BoardPiece
var _crowds := {} # path id -> the pieces standing there, in the order they arrived


func _ready() -> void:
	Sound.play_music("")
	print("Board: ", Match.players)
	for line in BoardPath.report():
		print("Path ", line)
	var lanes := $Scenery/Lanes
	lanes.add_child(BoardPathView.new())
	# The monsters stand here: sorted by y, so a piece on the lower lane is in front.
	_pieces = Node2D.new()
	_pieces.name = "Pieces"
	_pieces.y_sort_enabled = true
	lanes.add_child(_pieces)
	for player in Match.players:
		_add_piece(player)
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
	_land_pieces()


## The piece that is this player's monster.
func piece_for(player: Dictionary) -> BoardPiece:
	return _by_monster.get(player.monster)


## Walks the player's piece along the road, hopping from space to space, `steps` spaces, or
## until it reaches the finish. The camera follows it. The rules decide each step through
## `BoardPath.next`; the piece only shows it, and `Match.move_to` records where it stopped.
## Awaiting the signal waits for the end of the walk.
func walk(player: Dictionary, steps: int) -> Signal:
	var piece := piece_for(player)
	_walk(player, piece, steps)
	return piece.walked


## PLACEHOLDER (part 13 replaces it with the signpost and its arrows): a piece that reaches a
## fork takes a random path after a short beat. Awaiting the signal gives the chosen id.
func choose_branch(player: Dictionary, fork: String) -> Signal:
	var piece := piece_for(player)
	var chosen: String = BoardPath.next(fork).pick_random()
	get_tree().create_timer(BRANCH_BEAT, false).timeout.connect(
			func() -> void: piece.branch_chosen.emit(chosen))
	return piece.branch_chosen


func _add_piece(player: Dictionary) -> void:
	var piece := BoardPiece.new(player)
	piece.name = player.monster
	piece.position = _slot(player.space, 0, 1)
	piece.visible = false # it drops in once the intro glide is over
	_pieces.add_child(piece)
	_by_monster[player.monster] = piece


# Sets every piece down on the start, one at a time in turn order, each with a hop sound and a
# squash. The ones already there shuffle over to make room.
func _land_pieces() -> void:
	for player in Match.players:
		var piece := piece_for(player)
		_crowds[player.space] = _crowds.get(player.space, []) + [piece]
		piece.set_meta("rest_position", _slot_of(piece, player.space))
		_settle(player.space, piece)
		piece.visible = true
		PaperMotion.set_down(piece, _touch_down.bind(piece), 700.0, 0.5)
		await get_tree().create_timer(DROP_GAP, false).timeout
	pieces_landed.emit()


func _touch_down(piece: BoardPiece) -> void:
	Sound.play("hop")
	PaperMotion.squash(piece)


func _walk(player: Dictionary, piece: BoardPiece, steps: int) -> void:
	await get_tree().process_frame # so a caller can await the signal this returns
	piece.stop_sway()
	_camera.follow(piece)
	var here: String = player.space
	# The piece steps out in front of its crowd, which closes up behind it.
	_leave(here, piece)
	await PaperMotion.move_to(piece, _slot(here, 0, 1), 0.18).finished
	var left := steps
	while left > 0 and not BoardPath.next(here).is_empty():
		var to: String = BoardPath.next(here)[0]
		if BoardPath.is_fork(here):
			to = await choose_branch(player, here)
		left -= 1
		var last := left == 0 or BoardPath.next(to).is_empty()
		var target: Vector2 = BoardPath.node(to).pos + CROWD_FRONT
		if last:
			_crowds[to] = _crowds.get(to, []) + [piece]
			target = _slot_of(piece, to)
			_settle(to, piece)
		await PaperMotion.hop_to(piece, target, func() -> void: Sound.play("hop"), last).finished
		here = to
		if not last:
			await get_tree().create_timer(HOP_BEAT, false).timeout
	Match.move_to(player, here)
	piece.start_sway()
	_camera.glide_to(piece.global_position.x, 0.6)
	piece.walked.emit()


# Takes the piece out of its space's crowd; the others close up.
func _leave(id: String, piece: BoardPiece) -> void:
	_crowds[id].erase(piece)
	_settle(id)


# Moves everyone standing on a space to their place in the crowd, except `skip`, who is on their
# way there already.
func _settle(id: String, skip: BoardPiece = null) -> void:
	for piece: BoardPiece in _crowds[id]:
		if piece != skip:
			PaperMotion.move_to(piece, _slot_of(piece, id), 0.3)


func _slot_of(piece: BoardPiece, id: String) -> Vector2:
	var crowd: Array = _crowds[id]
	return _slot(id, crowd.find(piece), crowd.size())


# Where the `index`th of `count` pieces on a space stands. Up to 4 stand in a row across the
# token, and the rest in rows behind, each row a little higher and between the one in front.
func _slot(id: String, index: int, count: int) -> Vector2:
	var row := floori(index / float(CROWD_ROW))
	var in_row := mini(CROWD_ROW, count - row * CROWD_ROW)
	var x := (index % CROWD_ROW - (in_row - 1) / 2.0) * CROWD_STEP
	if row % 2 == 1 and in_row % 2 == 0:
		x += CROWD_STEP / 2.0
	return BoardPath.node(id).pos + CROWD_FRONT + Vector2(x, -CROWD_BACK * row)


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
