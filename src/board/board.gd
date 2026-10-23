extends Node2D
## The board. It opens on the castle gate, so everyone sees where the race ends, then glides
## back to the village start. Wherever the camera's centre is, the sky takes that location's
## tint and its ambience plays. It lays the road across the scenery, sets every player's monster down
## on the start, walks the pieces along the road, and runs the turns: the camera glides to the
## active player, the die is offered, and the roll walks the piece.

## Every piece has landed on the start.
signal pieces_landed
## A turn's die was clicked (true), or the candle went out (false).
signal _decided(by_click: bool)

## Each location's sky, top and bottom: colorful, never bleak.
const TINTS := {
	"village": [Color("1c1a4a"), Color("5f5ca8")], # misty violet-blue
	"graveyard": [Color("2a1746"), Color("3f7a62")], # green-violet
	"forest": [Color("0a2530"), Color("1b6f6c")], # deep teal
	"swamp": [Color("1c2612"), Color("7e912f")], # sickly olive-green
	"castle": [Color("2c0b36"), Color("a5182f")], # blood red and purple
}
const QUICK := ["coin", "spikes", "thief", "church"]
const BAT_LOCATIONS := ["graveyard", "castle"]
const INTRO_HOLD := 2.0 # on the castle gate, counted from when the board starts to show
const INTRO_GLIDE := 7.5
const SKIP_GLIDE := 0.9
const DROP_GAP := 0.45 # between one piece dropping onto the start and the next
const HOP_BEAT := 0.12 # between two hops, so a roll of 6 can be counted by ear
const BRANCH_BEAT := 0.5 # how long the placeholder takes to pick a path
const CROWD_STEP := 52.0 # across a space, from one piece to the next
const CROWD_ROW := 4 # pieces in a row, then the next row stands behind
const CROWD_FRONT := Vector2(0, 16) # the front row's feet, from the token's middle
const CROWD_BACK := 34.0 # how far each row further back stands higher
const TURN_SECONDS := 5.0 # the candle for a roll
const DIE_RISE := 300.0 # from the piece's feet to the die's middle, over its head
const CANDLE_SCALE := 0.5
const CANDLE_SIDE := Vector2(126, 70) # from the die's middle to the candle's base
const SHOW_BEAT := 0.5 # the rolled number stays on show this long
const TURN_BEAT := 0.4 # after a piece lands, before the camera glides on
const COIN_ICON := preload("res://assets/art/icons/coin_rim.png")
const BLOOD_ICON := preload("res://assets/art/icons/blood.png")
const COIN_SIZE := 78.0 # a flying coin at the token, in px; the HUD's counter is 30
const COIN_HUD := 30.0
const BLOOD_SIZE := 60.0
const BLOOD_HUD := 28.0

@onready var _camera: BoardCamera = $Camera
@onready var _sky: Control = $SkyLayer/Sky
@onready var _bats: Array[Node] = $Bats.get_children()

var _location := ""
var _intro := false
var _skipped := false
var _pieces: Node2D
var _by_monster := {} # monster id -> its BoardPiece
var _hud: Hud
var _crowds := {} # path id -> the pieces standing there, in the order they arrived
var _die: Die
var _candle: Candle
var _path_view: BoardPathView
var _front: Node2D # over the pieces: an icon that springs up stands here, so no piece hides it
var _settling: Tween # the camera's glide onto a piece that has just stopped


func _ready() -> void:
	Sound.play_music("")
	print("Board: ", Match.players)
	for line in BoardPath.report():
		print("Path ", line)
	var lanes := $Scenery/Lanes
	_path_view = BoardPathView.new()
	lanes.add_child(_path_view)
	# The monsters stand here: sorted by y, so a piece on the lower lane is in front.
	_pieces = Node2D.new()
	_pieces.name = "Pieces"
	_pieces.y_sort_enabled = true
	lanes.add_child(_pieces)
	for player in Match.players:
		_add_piece(player)
	_front = Node2D.new()
	_front.name = "Front"
	lanes.add_child(_front)
	_hud = Hud.new()
	add_child(_hud)
	pieces_landed.connect(_hud.come_in)
	pieces_landed.connect(_play_turns)
	_die = Die.new()
	_candle = Candle.new()
	_candle.scale = Vector2.ONE * CANDLE_SCALE
	_candle.set_meta("rest_scale", _candle.scale)
	for node in [_die, _candle]:
		node.visible = false
		lanes.add_child(node) # over the pieces, so a crowd never hides them
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


## What happens to a player who has just stopped on space `id`. `Match.land` decides it; here the
## space springs to life and the coin or blood flies to or from the player's portrait. Empty spaces
## do nothing, at once. Awaiting it waits for the end of the effect.
func land(player: Dictionary, id: String) -> void:
	var result := Match.land(player)
	var kind: String = result.kind
	if kind in Space.DUELS:
		print("Duel here, part 15: ", player.name, " on ", id)
		return
	if kind not in QUICK:
		return
	var space := _path_view.space_at(id)
	var piece := piece_for(player)
	if _settling and _settling.is_running():
		await _settling.finished # the flight starts from a camera at rest, so it never jumps
	await space.wake().finished
	match kind:
		"coin":
			await _land_coin(player, space)
		"spikes":
			await _land_spikes(player, space, piece)
		"thief":
			await _land_thief(player, space, result.coins != 0)
		"church":
			await _land_church(player, space, piece, result.blood != 0)
	space.rest()
	if kind == "spikes" and result.blood != 0 and player.blood == 0:
		died(player)


## Hook for part 13: the player has lost their last blood. PLACEHOLDER: it only logs for now, and
## the player plays on at 0 blood.
func died(player: Dictionary) -> void:
	print("Died: ", player.name, " (part 13 makes the death)")


## The HUD over the board.
func hud() -> Hud:
	return _hud


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


# The turn loop: glide to the active player, offer the die with the candle, roll, walk, land, and
# pass the turn on, until `Match` says the last turn is over.
func _play_turns() -> void:
	await get_tree().create_timer(Match.players.size() * Hud.DROP_GAP + 1.2, false).timeout
	while true:
		var player := Match.active()
		var piece := piece_for(player)
		await _camera.glide_to(piece.global_position.x).finished
		_hud.set_active(player)
		Sound.play("turn_start")
		var by_click := await _offer_die(piece)
		var value := Match.roll()
		if not by_click:
			await _die.nudge().finished
		_lift_candle()
		await _die.tumble(value)
		await get_tree().create_timer(SHOW_BEAT, false).timeout
		_die.leave()
		await walk(player, value)
		await land(player, player.space)
		await get_tree().create_timer(TURN_BEAT, false).timeout
		var turn := Match.turn
		if not Match.next_player():
			print("Match over")
			return
		if Match.turn != turn:
			_hud.set_turn(Match.turn)
			await get_tree().create_timer(0.5, false).timeout


# A coin springs up from the token, spins like a flipped coin and glints, then flies to the
# player's coin counter, which ticks up as it arrives.
func _land_coin(player: Dictionary, space: Space) -> void:
	var coin := _flyer(COIN_ICON, space.icon_top(), COIN_SIZE)
	var base := coin.scale
	var rise := coin.create_tween().set_parallel()
	rise.tween_property(coin, "position:y", coin.position.y - 120.0, 0.4) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rise.tween_method(func(t: float) -> void: coin.scale.x = base.x * cos(t * TAU * 2.0),
			0.0, 1.0, 0.4)
	await rise.finished
	coin.scale = base
	_glint(coin)
	Sound.play("fly")
	await PaperMotion.fly_to(coin, _hud.anchor(player, "coins"),
			Vector2.ONE * COIN_HUD / COIN_ICON.get_width(), 0.5, 0.0, 70.0).finished
	coin.queue_free()
	_hud.show_coins(player)


# The spikes shoot up out of the token and sink back slowly, the piece jolts, and a drop falls
# off the portrait.
func _land_spikes(player: Dictionary, space: Space, piece: BoardPiece) -> void:
	Sound.play("spikes")
	var spikes := _stand_in(space)
	PaperMotion.stretch(spikes, 1.6, 0.1)
	var jolt := PaperMotion.hop(piece, 38.0)
	await get_tree().create_timer(0.15, false).timeout
	_hud.show_blood(player)
	await jolt.finished
	await PaperMotion.shake(piece).finished
	await PaperMotion.stretch(spikes, 1.0, 0.45, false).finished
	_put_back(space, spikes)


# The hand darts up. With a coin to take, one flies down from the counter into it, and the hand
# closes on it and ducks back into the token; without, it grabs at the air and sinks back empty.
func _land_thief(player: Dictionary, space: Space, steals: bool) -> void:
	Sound.play("thief")
	var hand := _stand_in(space)
	await PaperMotion.stretch(hand, 1.5, 0.12).finished
	if steals:
		var coin := _flyer(COIN_ICON, _hud.anchor(player, "coins"), COIN_HUD)
		Sound.play("fly")
		_hud.show_coins(player) # the count ticks down as the coin leaves
		await PaperMotion.fly_to(coin, space.icon_top(),
				Vector2.ONE * COIN_SIZE * 0.7 / COIN_ICON.get_width(), 0.4, 0.0, -40.0).finished
		coin.queue_free()
		await PaperMotion.stretch(hand, 0.7, 0.08, false).finished
	else:
		PaperMotion.tilt(hand, 14.0)
		await get_tree().create_timer(0.45, false).timeout
	await PaperMotion.stretch(hand, 0.05, 0.18, false).finished
	await get_tree().create_timer(0.12, false).timeout
	await PaperMotion.stretch(hand, 1.0, 0.3).finished
	_put_back(space, hand)


# The bell rings and the glow flares. A drop rises from the church and flies to the portrait, or,
# with full blood, rises above the piece and fades.
func _land_church(player: Dictionary, space: Space, piece: BoardPiece, gains: bool) -> void:
	Sound.play("church")
	space.glow.flare()
	await get_tree().create_timer(0.25, false).timeout
	var drop := _flyer(BLOOD_ICON, space.icon_top(), BLOOD_SIZE)
	var rise := drop.create_tween().set_parallel()
	rise.tween_property(drop, "position:y", drop.position.y - (70.0 if gains else 150.0), 0.35 if gains else 0.7) 			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if gains:
		await rise.finished
		Sound.play("fly")
		await PaperMotion.fly_to(drop, _hud.anchor(player, "blood"),
				Vector2.ONE * BLOOD_HUD / BLOOD_ICON.get_width(), 0.5, 0.0, 70.0).finished
		drop.queue_free()
		_hud.show_blood(player)
	else:
		rise.tween_property(drop, "modulate:a", 0.0, 0.7).set_delay(0.2)
		await rise.finished
		drop.queue_free()


# A copy of the space's icon, in front of the pieces, standing where the icon stands; the icon
# itself is hidden until `_put_back`.
func _stand_in(space: Space) -> Sprite2D:
	var copy := Sprite2D.new()
	copy.texture = space.icon.texture
	copy.centered = false
	copy.offset = space.icon.offset
	copy.position = _front.to_local(space.icon.global_position)
	_front.add_child(copy)
	PaperShadow.add(copy)
	space.icon.visible = false
	return copy


func _put_back(space: Space, copy: Sprite2D) -> void:
	space.icon.visible = true
	copy.queue_free()


# A picture that lives on the HUD's layer, so it can fly between the world and the portraits.
# It starts at `at` on screen, `size` px across.
func _flyer(texture: Texture2D, at: Vector2, size: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = at
	sprite.scale = Vector2.ONE * size / texture.get_width()
	_hud.add_child(sprite)
	PaperShadow.add(sprite)
	return sprite


# A quick bright flash on a flying picture.
func _glint(sprite: Sprite2D) -> void:
	var glint := Glow.new(Color(1.0, 0.9, 0.5, 0.5), 52.0)
	glint.scale /= sprite.scale
	sprite.add_child(glint)
	var tween := glint.create_tween().set_parallel()
	tween.tween_property(glint, "scale", glint.scale * 1.6, 0.25)
	tween.tween_property(glint, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(glint.queue_free)


# Sets the die and the candle over the piece, and waits for a click on the die (true) or for the
# candle to go out (false).
func _offer_die(piece: BoardPiece) -> bool:
	var rows := ceili(_crowds.get(piece.player.space, []).size() / float(CROWD_ROW))
	var at: Vector2 = piece.position - Vector2(0, DIE_RISE + CROWD_BACK * maxi(rows - 1, 0))
	_die.place(at)
	_candle.rotation = 0.0
	_candle.position = at + CANDLE_SIDE
	_candle.set_meta("rest_position", _candle.position)
	await _die.offer()
	_candle.visible = true
	PaperMotion.pop_in(_candle)
	_candle.start(TURN_SECONDS)
	var on_click := _decided.emit.bind(true)
	var on_out := _decided.emit.bind(false)
	_die.clicked.connect(on_click)
	_candle.timed_out.connect(on_out)
	var by_click: bool = await _decided
	_die.clicked.disconnect(on_click)
	_candle.timed_out.disconnect(on_out)
	return by_click


# The candle is snuffed (if it still burns) and lifts away.
func _lift_candle() -> void:
	_candle.stop()
	await PaperMotion.lift_away(_candle, 500.0, 0.4).finished
	_candle.visible = false


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
	_settling = _camera.glide_to(piece.global_position.x, 0.6)
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
