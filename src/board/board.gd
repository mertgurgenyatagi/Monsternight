extends Node2D
## The board. It opens on the castle gate, so everyone sees where the race ends, then glides
## back to the village start. Wherever the camera's centre is, the sky takes that location's
## tint and its ambience plays. It lays the road across the scenery, sets every player's monster down
## on the start, walks the pieces along the road, and runs the turns: the camera glides to the
## active player, the die is offered, and the roll walks the piece.

## Every piece has landed on the start.
signal pieces_landed
## A turn's die was clicked (true), or the countdown went out (false).
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
const INTRO_GLIDE := 7.5 # the longest the intro glide takes
const INTRO_SPEED := 2100.0 # px a second, so a shorter board's intro is quicker, with the same feel
const SKIP_GLIDE := 0.9
const DROP_GAP := 0.45 # between one piece dropping onto the start and the next
const HOP_PACE := 0.42 # the time an in-between hop takes, against a hop's usual; it flows on into the next
const LAND_PACE := 0.7 # the same for the last hop of a walk
const FORK_VIEW := 330.0 # the camera looks this far past a fork while the choice is open
const CROWD_STEP := 52.0 # across a space, from one piece to the next
const CROWD_ROW := 4 # pieces in a row, then the next row stands behind
const CROWD_FRONT := Vector2(0, 16) # the front row's feet, from the token's middle
const CROWD_BACK := 34.0 # how far each row further back stands higher
const TURN_SECONDS := 5.0 # the countdown for a roll
const DIE_RISE := 300.0 # from the piece's feet to the die's middle, over its head
const COUNT_SCALE := 0.8 / BoardCamera.ZOOM
const COUNT_SIDE := Vector2(272, -30) # from the die's middle to the countdown's middle
const SHOW_BEAT := 0.25 # the rolled number stays on show this long
const TURN_BEAT := 0.15 # after a piece lands, before the camera glides on
const COIN_ICON := preload("res://assets/art/icons/coin_rim.png")
const BLOOD_ICON := preload("res://assets/art/icons/blood.png")
const COIN_SIZE := 78.0 # a flying coin at the token, in px; the HUD's counter is 30
const COIN_HUD := 30.0
const BLOOD_SIZE := 60.0
const BLOOD_HUD := 28.0
const POP_SCALE := 1.0 / BoardCamera.ZOOM # a pop in the world keeps the size it has on screen
const BEAM_HEIGHT := 110.0 # from a piece's feet to the middle of its body, where a beam starts
const POP_ABOVE := 190.0 # from a piece's feet to a pop over it
const DIE_POP := Vector2(290, -60) # from the die's middle to the "+1" beside it
const BONUS_BEAT := 0.6 # the "+1" stays on show this long before the die leaves
const BALL_SCALE := 0.4 # a crumpled piece, against its full size
const BALL_RISE := 150.0 # the ball lifts this far before it flies
const FLIGHT_FAST := 1.2 # the flight's time over no distance, and over the whole board
const FLIGHT_SLOW := 2.0
const SPILL_COINS := 5 # at most, falling out of the ball
const DUEL_BEAT := 0.3 # after the poses, before the stake is paid
const WIN_GROW := 1.15 # the winner's size while they pose
const SWAP_LIFT := 110.0 # the two pieces lift this far before they trade places
const REVIVE_BEAT := 0.6 # the camera holds on the start after the unfolding
const GATE_HOLD := 2.0 # the camera holds on the gate while a finisher's tag shows
const ONLOOK_FROM := 330.0 # the first onlooker stands this far right of the gate
const ONLOOK_STEP := 56.0 # across, from one onlooker to the next
const ONLOOK_ROW := 4
const FLAG_AT := Vector2(58, 8) # a planted flag, from the piece's feet
const FLAG_SCALE := 0.9
const TAG_RISE := 300.0 # from the piece's feet to the place tag's middle
const GATE_LIGHT := Color(1.0, 0.7, 0.3, 0.6)

@onready var _camera: BoardCamera = $Camera
@onready var _sky: Control = $SkyLayer/Sky
@onready var _bats: Array[Node] = $Bats.get_children()
@onready var _scenery: Node2D = $Scenery

var _location := ""
var _intro := false
var _skipped := false
var _pieces: Node2D
var _by_monster := {} # monster id -> its BoardPiece
var _hud: Hud
var _crowds := {} # path id -> the pieces standing there, in the order they arrived
var _die: Die
var _countdown: Countdown
var _path_view: BoardPathView
var _branch: BranchChoice
var _challenge: Challenge
var _frame: MinigameFrame
var _onlookers: Array[BoardPiece] = [] # the finished pieces, in finish order, standing by the gate
var _front: Node2D # over the pieces: an icon that springs up stands here, so no piece hides it
var _settling: Tween # the camera's glide onto a piece that has just stopped
var _last_turn_shown := false
var _note: TurnNote # online: whose move it is
var _rolled: Array = [] # online: the two faces the host rolled for this turn
var _track_name := "" # the board music now chosen, by where the leader is


# The road is built for this match's lobby before any child (the camera, the scenery) reads it.
func _enter_tree() -> void:
	var size := clampi(Match.players.size(), Match.MIN_PLAYERS, Match.MAX_PLAYERS)
	if Match.board_kinds.is_empty():
		Match.board_kinds = BoardRoller.roll(size, Match.board_rng)
	BoardPath.configure(size, Match.board_kinds)


var _notices: Array[String] = []


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
	_branch = BranchChoice.new()
	lanes.add_child(_branch)
	_hud = Hud.new()
	add_child(_hud)
	_hud.track_pieces(_by_monster)
	if Online.active:
		_note = TurnNote.new()
		_hud.add_child(_note)
		Online.presence_changed.connect(_on_presence)
		Online.rejoined.connect(func(player_name: String) -> void: _notice(tr("BANNER_BACK") % player_name))
		Online.room_lost.connect(func() -> void: _notice(tr("BANNER_CLOSED")))
		Net.host_changed.connect(_on_host_changed)
		for player in Match.players: # a copy that arrives late still shows who is gone
			if Online.status(player.name) != "":
				_hud.set_presence(player, Online.status(player.name))
	_challenge = Challenge.new()
	_hud.add_child(_challenge)
	_frame = MinigameFrame.new()
	add_child(_frame)
	pieces_landed.connect(_hud.come_in)
	pieces_landed.connect(_follow_leader)
	pieces_landed.connect(_play_turns)
	_die = Die.new()
	_countdown = Countdown.new()
	_countdown.scale = Vector2.ONE * COUNT_SCALE
	_countdown.set_meta("rest_scale", _countdown.scale)
	for node in [_die, _countdown]:
		node.visible = false
		lanes.add_child(node) # over the pieces, so a crowd never hides them
	_camera.jump_to(BoardLayout.width())
	_track()
	_lightning_loop()
	_intro = true
	await get_tree().create_timer(INTRO_HOLD, false).timeout
	if not _skipped:
		_glide_home(minf(INTRO_GLIDE, BoardLayout.width() / INTRO_SPEED))


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
	# Dracula's and Medusa's powers fire before the space does.
	if player.monster == "dracula":
		await _power_drain(player)
	elif player.monster == "medusa":
		await _power_stone(player)
	var result := Match.land(player)
	var kind: String = result.kind
	var forced := Net.debug_value("group") # a test can force every landing to be this question group
	if forced in Space.DUELS and kind not in Space.DUELS:
		kind = forced
	if kind in Space.DUELS:
		if _settling and _settling.is_running():
			await _settling.finished
		_say("ONLINE_CHALLENGE", "ONLINE_CHALLENGE_MINE", player)
		var choice := await _challenge.ask(player)
		_say_clear()
		if not choice.is_empty() and choice.stake == Challenge.WALK:
			PaperMotion.tilt(piece_for(player), 9.0)
			await get_tree().create_timer(0.5, false).timeout
			return
		if not choice.is_empty():
			var outcome: Dictionary = await _frame.play(player, choice.opponent, choice.stake, kind)
			_track_name = "" # the duel's music gives way to the leader's track
			_follow_leader()
			await duel_end(outcome.winner, outcome.loser, player, choice.stake)
			return
		# Nobody to duel: the space acts as a coin space.
		kind = "coin"
		result.coins = Match.change_coins(player, 1)
	if kind not in QUICK:
		return
	var space := _path_view.space_at(id)
	var piece := piece_for(player)
	if _settling and _settling.is_running():
		await _settling.finished # the flight starts from a camera at rest, so it never jumps
	await space.wake().finished
	match kind:
		"coin":
			await _land_coin(player, space, result.coins)
		"spikes":
			await _land_spikes(player, space, piece, result.blood == 0 and Match.blood_is_safe(player), result.blood)
		"thief":
			await _land_thief(player, space, result.coins)
		"church":
			await _land_church(player, space, piece, result.blood)
	space.rest()
	if kind == "spikes" and result.blood != 0 and player.blood == 0:
		await die(player)


## The player dies for real, and the board shows it: the monster crumples into a paper ball, any
## coins spill out, the ball flies in an arc back to the start and unfolds there with full blood.
## `Match.die` settles the rules first. Awaiting it waits until the monster stands on the start.
## Part 17 calls it for a death in a duel too.
func die(player: Dictionary) -> void:
	var piece := piece_for(player)
	var from: String = player.space
	var lost := Match.die(player)
	if lost.is_empty():
		return # a finished player can't die
	if _settling and _settling.is_running():
		await _settling.finished
	piece.stop_sway()
	_leave(from, piece)
	Sound.play("crumple")
	await PaperMotion.crumple(piece, 0.5, false, BALL_SCALE).finished
	piece.fold(true, BALL_SCALE)
	if lost.coins > 0:
		_spill_coins(piece.position + Vector2(0, -BALL_SCALE * 100.0), mini(lost.coins, SPILL_COINS))
		_hud.show_coins(player, true)
	await PaperMotion.move_to(piece, piece.position - Vector2(0, BALL_RISE), 0.35).finished
	# It joins the start's crowd as it flies there, so the others make room at once.
	_crowds[BoardPath.START] = _crowds.get(BoardPath.START, []) + [piece]
	var target := _slot_of(piece, BoardPath.START)
	_settle(BoardPath.START, piece)
	var distance := absf(target.x - piece.position.x)
	var far := clampf(distance / BoardLayout.width(), 0.0, 1.0)
	var flight := lerpf(FLIGHT_FAST, FLIGHT_SLOW, far)
	Sound.play("fly")
	_camera.glide_to(target.x, flight)
	await PaperMotion.toss(piece, target, flight, clampf(distance * 0.1, 260.0, 620.0),
			2, piece.ball).finished
	Sound.play("hop")
	await PaperMotion.bounce(piece, 34.0).finished
	await get_tree().create_timer(0.15, false).timeout
	piece.fold(false)
	Sound.play("respawn")
	PaperMotion.unfold(piece)
	_flare_start()
	_hud.show_blood(player, 0.2)
	_follow_leader()
	await get_tree().create_timer(REVIVE_BEAT + 0.6, false).timeout
	piece.start_sway()
	_settling = _camera.glide_to(piece.global_position.x, 0.4)


## The player has reached the castle gate: `Match.finish` gives them their place, the gate's doors swing
## open with a warm flare and a sting, the piece plants a flag, the HUD greys its portrait with the flag,
## and a paper tag with the place shows. Then the piece joins the onlookers beside the gate, and stays
## there for good. Awaiting it waits until the piece stands among them.
func finish(player: Dictionary) -> void:
	var place := Match.finish(player)
	var piece := piece_for(player)
	if _settling and _settling.is_running():
		await _settling.finished
	piece.stop_sway()
	var doors: GateDoors = _scenery.doors()
	doors.open()
	_flare_gate()
	Sound.sting("sting_finish")
	Sound.play(Monsters.voice(player.monster, "win"))
	PaperMotion.hop(piece, 70.0)
	PaperMotion.tilt(piece, 5.0)
	await get_tree().create_timer(0.5, false).timeout
	_plant_flag(piece)
	_hud.set_finished(player)
	await get_tree().create_timer(0.35, false).timeout
	var tag := PlaceTag.new(place)
	tag.position = piece.position - Vector2(0, TAG_RISE)
	_front.add_child(tag)
	tag.scale = Vector2.ONE * 1.4
	PaperMotion.pop_in(tag)
	Sound.play("card_slam", -6.0)
	await get_tree().create_timer(GATE_HOLD, false).timeout
	PaperMotion.pop_out(tag)
	doors.close()
	await get_tree().create_timer(0.3, false).timeout
	tag.queue_free()
	# The piece steps over to the onlookers, who stand a little right of the gate and face the board.
	_leave(BoardPath.FINISH, piece)
	var slot := _onlooker_slot(_onlookers.size())
	_onlookers.append(piece)
	await PaperMotion.hop_to(piece, slot, func() -> void: Sound.play("hop"), true, 90.0).finished
	piece.watch()
	_follow_leader()


## The result of a duel really happens. `Match.duel_result` settles the rules; here the winner poses,
## the loser crumples and unfolds (or dies, through `die`), and the coin, the blood or the places move.
## The camera holds on the challenger, except for a death far away and a swap. Awaiting it waits for
## the end of it all.
func duel_end(winner: Dictionary, loser: Dictionary, challenger: Dictionary, stake: String) -> void:
	var opponent: Dictionary = winner if is_same(loser, challenger) else loser
	var from_challenger: String = challenger.space
	var from_opponent: String = opponent.space
	var result := Match.duel_result(winner, loser, challenger, stake)
	if _settling and _settling.is_running():
		await _settling.finished
	_win_pose(winner)
	await _lose_pose(loser, result.died)
	await get_tree().create_timer(DUEL_BEAT, false).timeout
	if result.free: # Frankenstein's Monster loses nothing as the challenger
		PowerPop.show_over(_front, piece_for(loser).position - Vector2(0, POP_ABOVE), tr("POP_FREE"), POP_SCALE)
		await get_tree().create_timer(0.9, false).timeout
	if result.coins != 0:
		_delta(loser, -result.coins, "coins")
		await _duel_coin(winner, loser)
		_delta(winner, result.coins, "coins")
	if result.blood != 0:
		_delta(loser, -result.blood, "blood")
		if result.gain != 0: # the blood drop flies from the loser's portrait to the winner's
			await _duel_blood(winner, loser)
			_delta(winner, result.gain, "blood")
		else:
			_hud.show_blood(loser)
		await get_tree().create_timer(0.9, false).timeout
	if result.died:
		if not is_same(loser, challenger):
			await _camera.glide_to(piece_for(loser).global_position.x, 0.8).finished
		await die(loser)
	if result.swapped:
		await _swap(challenger, opponent, from_challenger, from_opponent)


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


## A piece that reaches a fork asks its player: the signpost's two arrows spring up with a countdown,
## and the camera eases out so both paths are in view. A click on an arrow, or the countdown going out
## (a random path), decides. Awaiting the signal gives the chosen id.
func choose_branch(player: Dictionary, fork: String) -> Signal:
	var piece := piece_for(player)
	_choose(piece, fork)
	return piece.branch_chosen


# The turn loop: glide to the active player, offer the die with the countdown, roll, walk, land, and
# pass the turn on, until `Match` says the last turn is over.
func _play_turns() -> void:
	await get_tree().create_timer(Match.players.size() * Hud.DROP_GAP + 1.2, false).timeout
	while true:
		var player := Match.active()
		var piece := piece_for(player)
		await _camera.glide_to(piece.global_position.x).finished
		_hud.set_active(player)
		Sound.play("turn_start")
		_say("ONLINE_ROLLING", "ONLINE_ROLL_MINE", player)
		var by_click := await _offer_die(piece)
		_say_clear()
		var dice := Match.roll(_rolled)
		var bonus := Match.roll_bonus(player)
		if not by_click:
			await _die.nudge().finished
			if Online.active:
				PowerPop.show_over(_front, _die.position + DIE_POP * POP_SCALE, tr("POP_AUTO"), POP_SCALE)
		_lift_countdown()
		await _die.tumble(dice)
		if dice[0] == dice[1]: # a double: the piece hops once more
			PaperMotion.hop(piece, 40.0)
		await get_tree().create_timer(SHOW_BEAT, false).timeout
		if bonus > 0: # the dice keep their real faces; the bonus pops beside them
			PowerPop.show_over(_front, _die.position + DIE_POP * POP_SCALE, tr("POP_PLUS_TWO"), POP_SCALE)
			await get_tree().create_timer(BONUS_BEAT, false).timeout
		_die.leave()
		await walk(player, dice[0] + dice[1] + bonus)
		if player.space == BoardPath.FINISH:
			await finish(player)
			if Match.over():
				await _banner(tr("BANNER_EVERYONE_HOME"), 1.4)
				await _end_match()
				return
		else:
			await land(player, player.space)
		await get_tree().create_timer(TURN_BEAT, false).timeout
		var turn := Match.turn
		if not Match.next_player():
			await _end_match()
			return
		if Match.turn != turn:
			_hud.set_turn(Match.turn)
			if Match.turn >= Match.turns and not _last_turn_shown:
				await _last_turn()
			else:
				await get_tree().create_timer(0.2, false).timeout


# Online: a player's connection dropped, they went away, or they are back. Their card dims and a
# short banner says so; the ones who are not on this board (a name that is not a player) are skipped.
func _on_presence(player_name: String, state: String) -> void:
	for player in Match.players:
		if player.name == player_name:
			_hud.set_presence(player, state)
			Sound.play("leave" if state != "" else "join")
			if state != "":
				_notice(tr("BANNER_DROPPED" if state == "dropped" else "BANNER_AWAY") % player_name)


func _on_host_changed(id: int) -> void:
	for player_name: String in Net.id_by_name:
		if int(Net.id_by_name[player_name]) == id:
			_notice(tr("BANNER_HOST") % player_name)


# A short banner that waits for the one before it.
func _notice(text: String) -> void:
	_notices.append(text)
	if _notices.size() > 1:
		return
	while not _notices.is_empty():
		await _banner(_notices[0], 1.2)
		_notices.pop_front()


# Online, the note says whose move it is: `others` for everyone else (with the player's name in it),
# `mine` for the player's own copy.
func _say(others: String, mine: String, player: Dictionary) -> void:
	if _note == null:
		return
	if Online.is_mine(player):
		_note.say(tr(mine), true)
	else:
		_note.say(tr(others) % player.name)


func _say_clear() -> void:
	if _note:
		_note.clear()


# Dracula landed: "Drain!" pops over him, and from each victim nearby a drop falls off the portrait
# and flies to his, one after another, while the victims recoil. His own count fills when the last
# drop is in. `Match.drain` has already moved the blood.
func _power_drain(player: Dictionary) -> void:
	var before: int = player.blood
	var victims := Match.drain(player)
	if victims.is_empty():
		return
	if _settling and _settling.is_running():
		await _settling.finished
	var piece := piece_for(player)
	PowerPop.show_over(_front, piece.position - Vector2(0, POP_ABOVE), tr("POP_DRAIN"), POP_SCALE)
	PaperMotion.tilt(piece, 6.0)
	await get_tree().create_timer(0.5, false).timeout
	var last: Signal
	for victim in victims:
		PaperMotion.tilt(piece_for(victim), 9.0)
		_beam(piece, piece_for(victim), Monsters.color("dracula"))
		_delta(victim, -1, "blood")
		var drop := _flyer(BLOOD_ICON, _hud.anchor(victim, "blood"), BLOOD_HUD)
		Sound.play("fly")
		_hud.show_blood(victim) # the drop leaves the victim's portrait
		var flight := PaperMotion.fly_to(drop, _hud.anchor(player, "blood"),
				Vector2.ONE * BLOOD_HUD / BLOOD_ICON.get_width(), 0.6, 0.0, 70.0)
		flight.finished.connect(drop.queue_free)
		last = flight.finished
		await get_tree().create_timer(0.3, false).timeout
	await last
	_hud.show_blood(player)
	_delta(player, player.blood - before, "blood")
	await get_tree().create_timer(0.4, false).timeout


# What a player just gained or lost, as a tag over their piece.
func _delta(player: Dictionary, amount: int, kind: String) -> void:
	if amount == 0:
		return
	DeltaPop.show_over(_front, piece_for(player).position - Vector2(0, POP_ABOVE + 80.0), amount, kind, POP_SCALE)


# A wedge of the monster's color from one piece to another.
func _beam(from: BoardPiece, to: BoardPiece, color: Color) -> void:
	var lift := Vector2(0, -BEAM_HEIGHT)
	PowerBeam.fire(_front, from.position + lift, to.position + lift, color)


# Medusa landed: her gaze tilts her piece, then each victim nearby goes grey with a squash, one after
# another, "Stone!" over them, and their portraits grey too. `Match.petrify` has already marked them.
func _power_stone(player: Dictionary) -> void:
	var turned := Match.petrify(player)
	if turned.is_empty():
		return
	if _settling and _settling.is_running():
		await _settling.finished
	var gazer := piece_for(player)
	PaperMotion.tilt(gazer, 6.0)
	await get_tree().create_timer(0.3, false).timeout
	for victim in turned:
		var piece := piece_for(victim)
		_beam(gazer, piece, Monsters.color("medusa"))
		await get_tree().create_timer(0.25, false).timeout
		Sound.play("stone")
		_delta(victim, -1, "turn")
		PowerPop.show_over(_front, piece.position - Vector2(0, POP_ABOVE), tr("POP_STONE"), POP_SCALE)
		piece.set_stone(true)
		_hud.set_stone(victim, true)
		PaperMotion.squash(piece)
		await get_tree().create_timer(0.35, false).timeout
	await get_tree().create_timer(0.5, false).timeout


# A stone player's turn comes: the camera glides to them, the grey shakes and flakes off with the old
# colour flashing back, "Crack!" pops, and the turn passes on without the die.
func _crack(player: Dictionary) -> void:
	var piece := piece_for(player)
	await _camera.glide_to(piece.global_position.x, 0.7).finished
	_hud.set_active(player)
	Sound.play("stone_crack")
	PaperMotion.shake(piece)
	await get_tree().create_timer(0.25, false).timeout
	piece.set_stone(false)
	_hud.set_stone(player, false)
	PaperMotion.squash(piece)
	PowerPop.show_over(_front, piece.position - Vector2(0, POP_ABOVE), tr("POP_CRACK"), POP_SCALE)
	await get_tree().create_timer(1.1, false).timeout


# Turn `turns` begins: a sting, a flash of the sky, the counter pops and a banner drops in with a
# slight shake. A countdown on screen sputters. Only the first time.
func _last_turn() -> void:
	_last_turn_shown = true
	Sound.sting("sting_final_turn", 3.0)
	_sky.flash()
	if _countdown.visible:
		PaperMotion.squash(_countdown)
	await get_tree().create_timer(0.5, false).timeout
	_hud.last_turn()
	await _banner(tr("BANNER_LAST_TURN"), 1.6, true)


# Drops a paper banner in under the HUD's strip, holds it `hold` seconds, then lifts it away. A
# `shaky` one is red and jerks a little while it holds. Awaiting it waits until it is gone.
func _banner(text: String, hold: float, shaky := false) -> void:
	var banner := PaperBanner.new(text, shaky)
	var at := Vector2(960, 330)
	banner.position = at
	banner.set_meta("rest_position", at)
	banner.set_meta("rest_scale", Vector2.ONE)
	_hud.add_child(banner)
	PaperMotion.drop_in(banner, 420.0, 0.5)
	Sound.play("card_slam", -4.0)
	await get_tree().create_timer(0.5, false).timeout
	if shaky:
		var shake := banner.create_tween().set_loops(int(hold / 0.2))
		shake.tween_property(banner, "position:x", at.x + 5.0, 0.05)
		shake.tween_property(banner, "position:x", at.x - 5.0, 0.1)
		shake.tween_property(banner, "position:x", at.x, 0.05)
	await get_tree().create_timer(hold, false).timeout
	await PaperMotion.lift_away(banner, 500.0, 0.4).finished
	banner.queue_free()


# The match is over: the camera glides to the castle gate, the portraits dim, a banner says so, the
# music fades, and the results are logged. The unfinished pieces sway slowly where they stand and a
# light flares over the gate. Then the curtain falls and the ceremony opens.
func _end_match() -> void:
	print("Match over")
	_hud.dim()
	for player in Match.players:
		if not player.finished:
			piece_for(player).wait()
	Sound.play_music("")
	_track_name = "end"
	await _camera.glide_to(BoardPath.finish().pos.x, 2.0).finished
	_flare_gate()
	await _banner(tr("BANNER_NIGHT_OVER"), 2.0)
	for row in Match.results():
		print("Result: ", row.rank, ". ", row.player.name, " trophies ", row.trophies, " finish ",
				row.finish, " gold ", row.gold, " duels ", row.duels)
	for stat in Match.stats():
		print("Stat: ", stat.key, " ", stat.value, " ", stat.players.map(func(p: Dictionary) -> String: return p.name))
	await _close_curtain()
	get_tree().change_scene_to_file("res://src/ceremony/ceremony.tscn")


# The curtain falls over the board and holds a moment. The ceremony opens with the same curtain
# closed, so the scene changes under it.
func _close_curtain() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 85
	add_child(layer)
	var curtain := Curtain.new()
	layer.add_child(curtain)
	curtain.set_spread(0.0, true)
	Sound.play("fly", -3.0)
	await curtain.move(1.0, 1.3, 0.0).finished
	await get_tree().create_timer(0.6, false).timeout


func _choose(piece: BoardPiece, fork: String) -> void:
	await get_tree().process_frame # so a caller can await the signal choose_branch returns
	_camera.glide_to(BoardPath.node(fork).pos.x + FORK_VIEW, 0.6)
	_say("ONLINE_PATH", "ONLINE_PATH_MINE", piece.player)
	var chosen := await _branch.ask(fork, _path_view, piece.player)
	_say_clear()
	_camera.follow(piece)
	piece.branch_chosen.emit(chosen)


# Small coins fall out of a ball at `at`, in front of the pieces, and fade as they fall.
func _spill_coins(at: Vector2, count: int) -> void:
	for i in count:
		var coin := Sprite2D.new()
		coin.texture = COIN_ICON
		coin.scale = Vector2.ONE * 34.0 / COIN_ICON.get_width()
		coin.position = at
		_front.add_child(coin)
		var side := randf_range(-90.0, 90.0)
		var tween := coin.create_tween().set_parallel()
		tween.tween_property(coin, "position:x", at.x + side, 0.8)
		tween.tween_property(coin, "position:y", at.y - randf_range(60.0, 120.0), 0.28) 				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(coin, "position:y", at.y + 70.0, 0.5) 				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(coin, "modulate:a", 0.0, 0.4).set_delay(0.4)
		tween.parallel().tween_property(coin, "rotation", randf_range(-6.0, 6.0), 0.8)
		tween.chain().tween_callback(coin.queue_free)


# The winner squashes, grows and jumps, with a flare under them and their voice, then settles back.
func _win_pose(player: Dictionary) -> void:
	var piece := piece_for(player)
	var base: Vector2 = piece.scale
	piece.stop_sway()
	Sound.play(Monsters.voice(player.monster, "win"))
	_flare_under(piece, Monsters.color(player.monster).lightened(0.4))
	piece.set_meta("rest_scale", base * WIN_GROW)
	PaperMotion.squash(piece)
	await get_tree().create_timer(0.12, false).timeout
	PaperMotion.hop(piece, 64.0)
	PaperMotion.tilt(piece, 5.0)
	await get_tree().create_timer(1.1, false).timeout
	piece.set_meta("rest_scale", base)
	PaperMotion.squash(piece)
	piece.start_sway()


# The loser's voice, then the piece crumples into its ball and unfolds again. A loser who dies only
# cries out, and `die` crumples them.
func _lose_pose(player: Dictionary, dies: bool) -> void:
	var piece := piece_for(player)
	Sound.play(Monsters.voice(player.monster, "lose"))
	if dies:
		await get_tree().create_timer(1.3, false).timeout
		return
	piece.stop_sway()
	Sound.play("crumple")
	await PaperMotion.crumple(piece, 0.5, false, BALL_SCALE).finished
	piece.fold(true, BALL_SCALE)
	await get_tree().create_timer(0.35, false).timeout
	piece.fold(false)
	Sound.play("respawn")
	await PaperMotion.unfold(piece).finished
	piece.start_sway()


# A coin flies from the loser's counter to the winner's, and both counts tick.
func _duel_coin(winner: Dictionary, loser: Dictionary) -> void:
	var coin := _flyer(COIN_ICON, _hud.anchor(loser, "coins"), COIN_HUD)
	Sound.play("fly")
	_hud.show_coins(loser) # the count ticks down as the coin leaves
	await PaperMotion.fly_to(coin, _hud.anchor(winner, "coins"),
			Vector2.ONE * COIN_HUD / COIN_ICON.get_width(), 0.8, 0.0, 130.0).finished
	coin.queue_free()
	_hud.show_coins(winner)
	await get_tree().create_timer(0.5, false).timeout


func _duel_blood(winner: Dictionary, loser: Dictionary) -> void:
	var drop := _flyer(BLOOD_ICON, _hud.anchor(loser, "blood"), BLOOD_HUD)
	Sound.play("fly")
	_hud.show_blood(loser) # the count ticks down as the drop leaves
	await PaperMotion.fly_to(drop, _hud.anchor(winner, "blood"),
			Vector2.ONE * BLOOD_HUD / BLOOD_ICON.get_width(), 0.7, 0.0, 110.0).finished
	drop.queue_free()
	_hud.show_blood(winner)
	await get_tree().create_timer(0.3, false).timeout


# The two pieces lift, swap places along crossing arcs and set down. The camera rides with the
# challenger, so the other piece crosses the screen on the way. The crowds are re-run, and nobody
# gets a space's effect from it. `Match.duel_result` has already swapped the spaces.
func _swap(challenger: Dictionary, opponent: Dictionary, from_challenger: String,
		from_opponent: String) -> void:
	var mine := piece_for(challenger)
	var theirs := piece_for(opponent)
	mine.stop_sway()
	theirs.stop_sway()
	_leave(from_challenger, mine)
	_leave(from_opponent, theirs)
	Sound.play("swap")
	for piece in [mine, theirs]:
		PaperMotion.move_to(piece, piece.position - Vector2(0, SWAP_LIFT), 0.3)
	await get_tree().create_timer(0.35, false).timeout
	_crowds[from_opponent] = _crowds.get(from_opponent, []) + [mine]
	_crowds[from_challenger] = _crowds.get(from_challenger, []) + [theirs]
	var to_mine := _slot_of(mine, from_opponent)
	var to_theirs := _slot_of(theirs, from_challenger)
	_settle(from_opponent, mine)
	_settle(from_challenger, theirs)
	var distance := absf(to_mine.x - mine.position.x)
	var flight := lerpf(FLIGHT_FAST, FLIGHT_SLOW, clampf(distance / BoardLayout.width(), 0.0, 1.0))
	var arc := clampf(distance * 0.1, 260.0, 620.0)
	_camera.glide_to(to_mine.x, flight)
	PaperMotion.toss(theirs, to_theirs, flight, arc * 0.55, 0)
	await PaperMotion.toss(mine, to_mine, flight, arc, 0).finished
	Sound.play("hop")
	PaperMotion.squash(mine)
	PaperMotion.squash(theirs)
	mine.start_sway()
	theirs.start_sway()
	_follow_leader()
	await get_tree().create_timer(0.3, false).timeout
	_settling = _camera.glide_to(mine.global_position.x, 0.6)
	await _settling.finished


# Where the `index`th finisher stands: in rows beside the gate, the first one nearest it.
func _onlooker_slot(index: int) -> Vector2:
	var row := index / ONLOOK_ROW
	var x := ONLOOK_FROM + (index % ONLOOK_ROW) * ONLOOK_STEP + (ONLOOK_STEP / 2.0 if row % 2 == 1 else 0.0)
	return BoardPath.finish().pos + CROWD_FRONT + Vector2(x, -CROWD_BACK * row)


# A warm light flares in the doorway as the doors open.
func _flare_gate() -> void:
	var glow := Glow.new(GATE_LIGHT, 230.0)
	glow.scale.y *= 1.4
	glow.position = BoardPath.finish().pos + Vector2(0, -250)
	_front.add_child(glow)
	await glow.flare(1.5, 0.2, 1.6).finished
	glow.queue_free()


# The piece plants a flag beside it, which pops up and sways on its pole.
func _plant_flag(piece: BoardPiece) -> void:
	var flag := Flag.new()
	flag.position = FLAG_AT
	flag.scale = Vector2.ONE * FLAG_SCALE
	piece.add_child(flag)
	PaperShadow.add(flag)
	PaperMotion.pop_in(flag).finished.connect(func() -> void: PaperMotion.sway(flag, 2.5, 3.2))
	Sound.play("flip")


# A flare on the ground under a piece.
func _flare_under(piece: BoardPiece, color: Color) -> void:
	var glow := Glow.new(Color(color, 0.55), 120.0)
	glow.scale.y *= 0.5
	glow.position = piece.position + Vector2(0, -6)
	_front.add_child(glow)
	await glow.flare().finished
	glow.queue_free()


# A small flare on the start's token, where a piece has just come back to life.
func _flare_start() -> void:
	var glow := Glow.new(Color(1.0, 0.85, 0.5, 0.5), 110.0)
	glow.scale.y *= 0.6
	glow.position = BoardPath.start().pos + Vector2(0, -20)
	_front.add_child(glow)
	await glow.flare().finished
	glow.queue_free()


# The board's music follows whoever leads the race, by the location they stand in: it changes when
# the lead does, never when the camera does. A missing track plays as silence.
func _follow_leader() -> void:
	var leader := Match.leader()
	if leader.is_empty():
		return
	var location := BoardLayout.location_at(BoardPath.node(leader.space).pos.x)
	var track: String = "board_" + location.id
	if track == _track_name:
		return
	_track_name = track
	print("Music: ", track, " (", leader.name, " leads)")
	Sound.play_music(track)


# A coin springs up from the token, spins like a flipped coin and glints, then flies to the
# player's coin counter, which ticks up as it arrives.
func _land_coin(player: Dictionary, space: Space, amount := 1) -> void:
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
	_delta(player, amount, "coins")


# The spikes shoot up out of the token and sink back slowly, the piece jolts, and a drop falls
# off the portrait.
func _land_spikes(player: Dictionary, space: Space, piece: BoardPiece, safe := false, amount := 0) -> void:
	Sound.play("spikes")
	var spikes := _stand_in(space)
	PaperMotion.stretch(spikes, 1.6, 0.1)
	if safe: # Death at 1 blood shrugs them off
		await get_tree().create_timer(0.15, false).timeout
		PowerPop.show_over(_front, piece.position - Vector2(0, POP_ABOVE), tr("POP_SAFE"), POP_SCALE)
		await PaperMotion.tilt(piece, 9.0).finished
		await PaperMotion.stretch(spikes, 1.0, 0.45, false).finished
		_put_back(space, spikes)
		return
	var jolt := PaperMotion.hop(piece, 38.0)
	await get_tree().create_timer(0.15, false).timeout
	_hud.show_blood(player)
	_delta(player, amount, "blood")
	await jolt.finished
	await PaperMotion.shake(piece).finished
	await PaperMotion.stretch(spikes, 1.0, 0.45, false).finished
	_put_back(space, spikes)


# The hand darts up. With a coin to take, one flies down from the counter into it, and the hand
# closes on it and ducks back into the token; without, it grabs at the air and sinks back empty.
func _land_thief(player: Dictionary, space: Space, amount: int) -> void:
	var steals := amount != 0
	Sound.play("thief")
	var hand := _stand_in(space)
	await PaperMotion.stretch(hand, 1.5, 0.12).finished
	if steals:
		var coin := _flyer(COIN_ICON, _hud.anchor(player, "coins"), COIN_HUD)
		Sound.play("fly")
		_hud.show_coins(player) # the count ticks down as the coin leaves
		_delta(player, amount, "coins")
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
func _land_church(player: Dictionary, space: Space, piece: BoardPiece, amount: int) -> void:
	var gains := amount != 0
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
		_delta(player, amount, "blood")
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


# Sets the die and the countdown over the piece, and waits for a click on the die (true) or for the
# countdown to go out (false).
func _offer_die(piece: BoardPiece) -> bool:
	var rows := ceili(_crowds.get(piece.player.space, []).size() / float(CROWD_ROW))
	var at: Vector2 = piece.position - Vector2(0, DIE_RISE + CROWD_BACK * maxi(rows - 1, 0))
	_die.place(at)
	_die.clickable = Online.is_mine(piece.player)
	_countdown.rotation = 0.0
	_countdown.position = at + COUNT_SIDE
	_countdown.set_meta("rest_position", _countdown.position)
	await _die.offer()
	_countdown.visible = true
	PaperMotion.pop_in(_countdown)
	_countdown.start(TURN_SECONDS)
	if Online.active:
		# The host rolls: the click only asks, and the faces come back with everyone's answer.
		var player: Dictionary = piece.player
		var on_ask := Online.submit.bind({})
		if Online.is_mine(player):
			_die.clicked.connect(on_ask)
		var answer := await Online.decide("roll", player, TURN_SECONDS,
				func() -> Dictionary: return {},
				func(_v: Variant) -> bool: return true,
				func(_v: Variant) -> Dictionary: return {"dice": [randi_range(1, 6), randi_range(1, 6)]})
		if Online.is_mine(player):
			_die.clicked.disconnect(on_ask)
		_rolled = answer.value.dice
		return not answer.auto
	_rolled = []
	var on_click := _decided.emit.bind(true)
	var on_out := _decided.emit.bind(false)
	_die.clicked.connect(on_click)
	_countdown.timed_out.connect(on_out)
	var by_click: bool = await _decided
	_die.clicked.disconnect(on_click)
	_countdown.timed_out.disconnect(on_out)
	return by_click


# The countdown is stopped (if it still runs) and lifts away.
func _lift_countdown() -> void:
	_countdown.stop()
	await PaperMotion.lift_away(_countdown, 500.0, 0.4).finished
	_countdown.visible = false


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
	await PaperMotion.move_to(piece, _slot(here, 0, 1), 0.1).finished
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
		await PaperMotion.hop_to(piece, target, func() -> void: Sound.play("hop"), last, 44.0,
				LAND_PACE if last else HOP_PACE).finished
		here = to
		if BoardPath.is_fork(here):
			_path_view.nudge_signpost(here)
	Match.move_to(player, here)
	_follow_leader()
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
