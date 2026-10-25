class_name BranchChoice
extends Node2D
## The choice at a fork. Two paper arrows spring up beside the signpost, the upper one pointing up
## to the upper path and the lower one down to the lower path, and nothing else. A countdown runs for `SECONDS`. A click on an arrow, or the countdown going
## out, decides. Hovering an arrow lights the path it leads to and dims the other. It lives in the
## board's Lanes layer over the pieces. Only the arrows take clicks.

## The choice is made: by a click on an arrow (true), or because the countdown went out (false).
signal _decided(by_click: bool)

const ARROW := preload("res://assets/art/board/arrow.png")
const SECONDS := 10.0
const COUNT_SCALE := 0.8 / BoardCamera.ZOOM
const COUNT_AT := Vector2(-60, -300) # the countdown floats over the pieces, from the fork's token
const ARROW_AT := [Vector2(260, -470), Vector2(260, -340)] # the upper and the lower arrow's middle
const ARROW_TURN := [-22.0, 20.0] # degrees
const ARROW_SCALE := 1.1 / BoardCamera.ZOOM
const POP_GAP := 0.18
const CLICK_BEAT := 0.35
const TIMEOUT_BEAT := 0.55

var _countdown: Countdown
var _options: Array[Node2D] = []
var _areas: Array[Area2D] = []
var _stretches: Array[String] = []
var _view: BoardPathView
var _open := false
var _choice := -1
var _online := false # the host decides; the countdown here is only for show
var _mine := true # this copy's player makes the choice
var _clicked_here := false
var _clicked_index := -1


func _ready() -> void:
	_countdown = Countdown.new()
	_countdown.scale = Vector2.ONE * COUNT_SCALE
	_countdown.set_meta("rest_scale", _countdown.scale)
	_countdown.visible = false
	add_child(_countdown)


## Shows the choice at `fork` and waits for it. Gives the id of the space chosen, one of
## `BoardPath.next(fork)`. The arrows are gone again when it returns.
func ask(fork: String, view: BoardPathView, player := {}) -> String:
	_view = view
	_clicked_here = false
	var node := BoardPath.node(fork)
	var following: Array = node.next
	_choice = -1
	for i in following.size():
		_stretches.append(BoardPath.node(following[i]).stretch)
		_add_option(i, node.pos)
	_countdown.position = node.pos + COUNT_AT
	_countdown.rotation = 0.0
	_countdown.set_meta("rest_position", _countdown.position)
	for i in _options.size():
		PaperMotion.pop_in(_options[i], i * POP_GAP)
	await get_tree().create_timer(_options.size() * POP_GAP + 0.3, false).timeout
	_countdown.visible = true
	PaperMotion.pop_in(_countdown)
	_countdown.start(SECONDS)
	_online = Online.active
	_mine = Online.is_mine(player) if _online else true
	var by_click: bool
	if _online:
		_open = _mine
		for area in _areas:
			area.input_pickable = _mine
		var count := _options.size()
		var answer := await Online.decide("branch", player, SECONDS,
				func() -> int: return randi() % count,
				func(v: Variant) -> bool: return (v is int or v is float) and int(v) >= 0 and int(v) < count)
		_choice = int(answer.value)
		by_click = not answer.auto
		if by_click and not _clicked_here: # someone else's click: the arrow answers it
			Sound.play("ui_click")
			PaperMotion.squash(_options[_choice])
			_drop_others(_choice)
		elif _clicked_here and _choice != _clicked_index:
			_drop_others(_choice)
	else:
		_countdown.timed_out.connect(_on_timed_out)
		_open = true
		for area in _areas:
			area.input_pickable = true
		by_click = await _decided
		_countdown.timed_out.disconnect(_on_timed_out)
	_open = false
	for area in _areas:
		area.input_pickable = false
	_countdown.stop()
	PaperMotion.lift_away(_countdown, 500.0, 0.4)
	if by_click:
		await get_tree().create_timer(CLICK_BEAT, false).timeout
	else:
		# Nobody clicked: the arrows shake, then the pick lights up so it's clear.
		for option in _options:
			PaperMotion.shake(option)
		await get_tree().create_timer(0.3, false).timeout
		_hover(_choice, true)
		await get_tree().create_timer(TIMEOUT_BEAT, false).timeout
		_drop_others(_choice)
		await get_tree().create_timer(0.2, false).timeout
	await PaperMotion.pop_out(_options[_choice]).finished
	_view.clear_light()
	_countdown.visible = false
	for option in _options:
		option.queue_free()
	_options.clear()
	_areas.clear()
	_stretches.clear()
	return following[_choice]


func _add_option(index: int, fork_at: Vector2) -> void:
	var option := Node2D.new()
	option.position = fork_at + ARROW_AT[index]
	option.set_meta("rest_position", option.position)
	option.scale = Vector2.ZERO
	add_child(option)
	var arrow := Sprite2D.new()
	arrow.texture = ARROW
	arrow.rotation_degrees = ARROW_TURN[index]
	arrow.scale = Vector2.ONE * ARROW_SCALE
	option.add_child(arrow)
	PaperShadow.add(arrow)
	option.set_meta("rest_scale", Vector2.ONE)
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = ARROW.get_size() * ARROW_SCALE
	area.rotation_degrees = ARROW_TURN[index]
	area.add_child(shape)
	area.input_pickable = false
	area.input_event.connect(_on_input.bind(index))
	area.mouse_entered.connect(_hover.bind(index, true))
	area.mouse_exited.connect(_hover.bind(index, false))
	option.add_child(area)
	_areas.append(area)
	_options.append(option)


func _hover(index: int, over: bool) -> void:
	if index < 0 or index >= _options.size() or (over and not _open and index != _choice):
		return
	if over:
		if _open:
			Sound.play("ui_hover")
		PaperMotion.lift(_options[index], true)
		var others: Array[String] = []
		for i in _stretches.size():
			if i != index:
				others.append(_stretches[i])
		_view.light_path(_stretches[index], others)
	elif _open:
		PaperMotion.lift(_options[index], false)
		_view.clear_light()


func _on_input(_viewport: Node, event: InputEvent, _shape: int, index: int) -> void:
	if _open and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_open = false
		_choice = index
		Sound.play("ui_click")
		PaperMotion.squash(_options[index])
		_drop_others(index)
		if _online:
			_clicked_here = true
			_clicked_index = index
			Online.submit(index)
		else:
			_decided.emit(true)


# The clicked arrow's path stays lit, and the other arrow drops away.
func _drop_others(index: int) -> void:
	for i in _options.size():
		if i != index:
			PaperMotion.lift_away(_options[i], 200.0, 0.35)
			_options[i].create_tween().tween_property(_options[i], "modulate:a", 0.0, 0.3)


func _on_timed_out() -> void:
	_choice = randi() % _options.size()
	_decided.emit(false)
