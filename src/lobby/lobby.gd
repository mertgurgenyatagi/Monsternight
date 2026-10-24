extends Control
## The online lobby. Two views on one screen: choosing (host a room, join with a code, or the old
## same-screen setup) and the room itself (the code, Copy link, the seats, a name, Ready, and Start
## for the host). The host's `LobbyState` is the truth and goes to everyone on every change; Start
## sends the names and a seed, and every copy begins the same `Match` and goes to the turn order.

const DISPLAY := preload("res://assets/fonts/display.ttf")
const CREAM := Color("efe4cc")
const ROW_MAX := 4
const SPACING := Vector2(280, 330)
const SEATS_CENTER_Y := 600.0
const CONNECT_SECONDS := 8.0

var _state := LobbyState.new()
var _host_id := 0 # the peer who holds the truth, once known
var _entry: Control
var _room: Control
var _code_edit: LineEdit
var _tiles_root: Control
var _cards: Dictionary = {} # peer id -> SeatCard
var _cards_root: Node2D
var _name_edit: LineEdit
var _ready_button: PaperButton
var _start_button: PaperButton
var _copy_button: PaperButton
var _banner: PaperBanner
var _is_ready := false
var _resent := false
var _leaving := false
var _wait_id := 0 # counts attempts, so a stale timeout does nothing


func _ready() -> void:
	Sound.play_music("title")
	Match.reset()
	var again := Online.back_to_room and Net.is_online()
	Online.back_to_room = false
	var my_name := _name_in_last_match()
	Online.stop()
	if not again:
		Net.leave()
	add_child(preload("res://src/sky/sky.tscn").instantiate())
	_build_entry()
	_build_room()
	Net.connected.connect(_on_connected)
	Net.refused.connect(_on_refused)
	Net.disconnected.connect(func() -> void: _drop("LOBBY_DROPPED"))
	Net.peer_joined.connect(_on_peer_joined)
	Net.peer_left.connect(_on_peer_left)
	Net.host_changed.connect(_on_host_changed)
	Net.received.connect(_on_received)
	if again:
		_resume_room(my_name)
		return
	var linked := Net.room_from_link()
	if linked != "":
		_code_edit.text = linked
		_join()


# The name this peer played under in the match that just ended, or "".
func _name_in_last_match() -> String:
	for player_name: String in Net.id_by_name:
		if int(Net.id_by_name[player_name]) == Net.my_id:
			return player_name
	return ""


# Back from a match with the connection still open ("Play again"): the same room, everyone who is
# still here, nobody ready. The host builds the seats; the others send their name and wait for them.
func _resume_room(my_name: String) -> void:
	_host_id = Net.my_id if Net.is_host else Online.host_id
	_state = LobbyState.new()
	_is_ready = false
	if Net.is_host:
		_state.add(Net.my_id)
		for id in Net.peers:
			_state.add(id)
	_enter_room()
	# A default "Player N" is not carried over: it would clash with the other seats' own defaults.
	var generic := range(1, Match.MAX_PLAYERS + 1).any(func(n: int) -> bool: return my_name == tr("PLAYER_DEFAULT") % n)
	_name_edit.text = "" if generic else my_name
	_send_profile()
	if not Net.is_host:
		_show_banner("CEREMONY_WAIT_HOST")


# --- the choosing view ---

func _build_entry() -> void:
	_entry = Control.new()
	add_child(_entry)
	_entry.add_child(_label("LOBBY_TITLE", Rect2(360, 40, 1200, 130), 104))
	var host := _button("LOBBY_HOST", Rect2(700, 240, 520, 110), _host)
	_code_edit = LineEdit.new()
	_code_edit.name = "Code"
	_code_edit.position = Vector2(640, 440)
	_code_edit.size = Vector2(380, 100)
	_code_edit.max_length = Net.CODE_LENGTH
	_code_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_edit.placeholder_text = tr("LOBBY_CODE_HINT")
	_style_edit(_code_edit, 60)
	_code_edit.text_changed.connect(_on_code_typed)
	_code_edit.text_submitted.connect(func(_t: String) -> void: _join())
	_entry.add_child(_code_edit)
	var join := _button("LOBBY_JOIN", Rect2(1050, 440, 270, 100), _join)
	var local := _button("LOBBY_LOCAL", Rect2(700, 660, 520, 110), _local)
	var back := _button("LOBBY_BACK", Rect2(140, 930, 380, 104), _back)
	var buttons: Array[PaperButton] = [host, join, local, back]
	for i in buttons.size():
		_entry.add_child(buttons[i])
		buttons[i].enter(0.4 + i * 0.12)


func _on_code_typed(text: String) -> void:
	_code_edit.text = text.to_upper()
	_code_edit.caret_column = text.length()


# --- the room view ---

func _build_room() -> void:
	_room = Control.new()
	_room.visible = false
	add_child(_room)
	_tiles_root = Control.new()
	_room.add_child(_tiles_root)
	_cards_root = Node2D.new()
	_room.add_child(_cards_root)
	_copy_button = _button("LOBBY_COPY", Rect2(1230, 100, 520, 104), _copy_link)
	_name_edit = LineEdit.new()
	_name_edit.name = "Name"
	_name_edit.position = Vector2(140, 930)
	_name_edit.size = Vector2(440, 104)
	_name_edit.max_length = Match.NAME_LENGTH
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.placeholder_text = tr("LOBBY_NAME_HINT")
	_style_edit(_name_edit, 48)
	_name_edit.text_submitted.connect(func(_t: String) -> void: _send_profile())
	_name_edit.focus_exited.connect(_send_profile)
	_room.add_child(_name_edit)
	_ready_button = _button("LOBBY_READY", Rect2(620, 930, 380, 104), _toggle_ready)
	_start_button = _button("LOBBY_START", Rect2(1040, 930, 380, 104), _start)
	var leave := _button("LOBBY_LEAVE", Rect2(1460, 930, 320, 104), _leave_room)
	for b: PaperButton in [_copy_button, _ready_button, _start_button, leave]:
		_room.add_child(b)
	leave.enter(0.9)


# Shows the room: the code on paper tiles, the buttons popping in.
func _enter_room() -> void:
	_entry.visible = false
	_room.visible = true
	for tile in _tiles_root.get_children():
		tile.queue_free()
	for i in Net.CODE_LENGTH:
		var tile := _code_tile(Net.code[i])
		tile.position = Vector2(300 + i * 190, 80)
		_tiles_root.add_child(tile)
		PaperMotion.drop_in(tile, 500.0, 0.7, 0.1 + i * 0.1)
	_start_button.visible = Net.is_host
	var buttons: Array[PaperButton] = [_copy_button, _ready_button, _start_button]
	for i in buttons.size():
		buttons[i].enter(0.5 + i * 0.12)
	_name_edit.grab_focus()
	_refresh()


func _code_tile(letter: String) -> Control:
	var tile := Control.new()
	tile.size = Vector2(150, 180)
	var paper := NinePatchRect.new()
	paper.texture = preload("res://assets/art/ui/panel.png")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		paper.set_patch_margin(side, 72)
	paper.self_modulate = CREAM
	paper.size = tile.size
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(paper)
	PaperShadow.add(paper)
	var text := Label.new()
	text.text = letter
	text.size = tile.size
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_override("font", DISPLAY)
	text.add_theme_font_size_override("font_size", 130)
	text.add_theme_color_override("font_color", SeatCard.INK)
	tile.add_child(text)
	return tile


# --- doing things ---

func _host() -> void:
	_connect(Net.new_code(), false)


func _join() -> void:
	var typed := Net.clean_code(_code_edit.text)
	if typed == "":
		_deny(_code_edit)
		_show_banner("LOBBY_BAD_CODE", true)
		return
	_connect(typed, true)


# Opens the room, and gives up with a banner if the relay has not answered in a few seconds.
func _connect(code: String, existing: bool) -> void:
	_wait_id += 1
	var attempt := _wait_id
	if not Net.open_room(code, existing):
		return
	await get_tree().create_timer(CONNECT_SECONDS, false).timeout
	if attempt == _wait_id and not Net.is_online() and not _leaving:
		Net.leave()
		_show_banner("LOBBY_CANT_CONNECT", true)


func _local() -> void:
	_go("res://src/setup/setup.tscn")


func _back() -> void:
	_go("res://src/title/title.tscn")


func _leave_room() -> void:
	Net.leave()
	_state = LobbyState.new()
	_wait_id += 1
	_is_ready = false
	_host_id = 0
	_room.visible = false
	_entry.visible = true
	for card: SeatCard in _cards.values():
		card.queue_free()
	_cards.clear()
	Sound.play("leave")


func _go(path: String) -> void:
	if _leaving:
		return
	_leaving = true
	Scenes.change_to(path)


func _copy_link() -> void:
	Net.copy_text(Net.link_for(Net.code))
	_copy_button.text = tr("LOBBY_COPIED")
	await get_tree().create_timer(1.4, false).timeout
	if is_instance_valid(_copy_button):
		_copy_button.text = tr("LOBBY_COPY")


func _toggle_ready() -> void:
	_is_ready = not _is_ready
	_send_profile()


# Everyone, host included, sends their name and ready mark to the host, which checks them.
func _send_profile() -> void:
	if not Net.is_online():
		return
	var payload := {"name": _name_edit.text, "ready": _is_ready}
	if Net.is_host:
		_apply_profile(Net.my_id, payload)
	else:
		Net.send(_host_id, "profile", payload)


func _start() -> void:
	if not Net.is_host or _leaving:
		return
	if not _state.can_start():
		_deny(_start_button)
		_show_banner("LOBBY_NEED_PLAYERS", true)
		return
	var seed := randi() & 0x7fffffff
	var names := _state.final_names()
	var ids: Array = _state.seats.map(func(s: Dictionary) -> int: return s.id)
	Net.broadcast("start", {"names": names, "ids": ids, "seed": seed})
	_begin_match(names, ids, seed)


# Every copy runs this with the host's numbers: the same Match, the same board, the same order.
func _begin_match(names: Array, ids: Array, seed: int) -> void:
	var typed: Array[String] = []
	for n in names:
		typed.append(str(n))
	if not Match.start(typed, seed):
		return
	Net.id_by_name.clear()
	for i in typed.size():
		Net.id_by_name[Match.players[i].name] = int(ids[i])
	if Net.is_online():
		Online.begin(_host_id)
	Sound.play("start")
	_go("res://src/pregame/pregame.tscn")


# --- the host's side ---

func _on_connected() -> void:
	_host_id = Net.my_id if Net.is_host else 0
	_state = LobbyState.new()
	_is_ready = false
	if Net.is_host:
		_state.add(Net.my_id)
	_enter_room()


func _on_peer_joined(id: int) -> void:
	if Net.is_host and _state.add(id):
		Sound.play("join")
		_publish()


func _on_peer_left(id: int) -> void:
	if Net.is_host:
		_state.remove(id)
		Sound.play("leave")
		_publish()
	# A host that left is replaced by the relay's `host` message (see `_on_host_changed`).


# The host left while we were in the room. The relay named the longest-connected peer; if that is
# this copy it builds the seats from what it has, the others wait for them.
func _on_host_changed(id: int) -> void:
	_host_id = id
	_resent = false
	if Net.is_host:
		var old := _state
		_state = LobbyState.new()
		_state.add(Net.my_id)
		for peer in Net.peers:
			_state.add(peer)
		for seat in _state.seats: # keep the names and ready marks the old seats had
			var at := old.seat_of(seat.id)
			if at >= 0:
				_state.set_profile(seat.id, old.seats[at].name, old.seats[at].ready)
		_publish()
		_send_profile()
	_refresh()


func _apply_profile(id: int, payload: Dictionary) -> void:
	if not _state.set_profile(id, str(payload.get("name", "")), bool(payload.get("ready", false))):
		if id == Net.my_id:
			_is_ready = false
			_show_banner("LOBBY_NAME_TAKEN", true)
		else:
			Net.send(id, "denied", {"why": "name"})
		var at := _state.seat_of(id)
		if at >= 0:
			_state.seats[at].ready = false
	_publish()


# The host sends the seats to everyone and shows them itself.
func _publish() -> void:
	Net.broadcast("lobby", {"host": _host_id, "seats": _state.to_list()})
	_refresh()


# --- everyone's side ---

func _on_received(from: int, kind: String, payload: Dictionary) -> void:
	match kind:
		"profile":
			if Net.is_host:
				_apply_profile(from, payload)
		"lobby":
			if not Net.is_host and (_host_id == 0 or from == _host_id):
				_host_id = int(payload.get("host", from))
				_state.from_list(payload.get("seats", []))
				var mine := _state.seat_of(Net.my_id)
				if mine >= 0:
					_is_ready = _state.seats[mine].ready
					# The host may have built its seats before our name reached it: say it once more.
					if not _resent and _name_edit.text != "" and _state.seats[mine].name != _name_edit.text.strip_edges():
						_resent = true
						_send_profile()
				_refresh()
		"denied":
			if from == _host_id:
				_is_ready = false
				_show_banner("LOBBY_NAME_TAKEN", true)
		"start":
			if from == _host_id:
				_begin_match(payload.get("names", []), payload.get("ids", []), int(payload.get("seed", 0)))


func _on_refused(reason: String) -> void:
	_wait_id += 1
	match reason:
		"full":
			_show_banner("LOBBY_FULL", true)
		"missing":
			_show_banner("LOBBY_MISSING", true)
		_:
			_show_banner("LOBBY_CANT_CONNECT", true)


# Back to choosing, with a banner saying why.
func _drop(why: String) -> void:
	if _leaving:
		return
	_leave_room()
	_show_banner(why, true)


# --- drawing ---

func _refresh() -> void:
	if not _room.visible:
		return
	var count := _state.seats.size()
	for i in count:
		var seat: Dictionary = _state.seats[i]
		if not _cards.has(seat.id):
			var card := SeatCard.new(seat.id)
			_cards_root.add_child(card)
			card.position = _seat_position(i, count)
			_cards[seat.id] = card
			PaperMotion.slide_in(card, 2100.0 if i % 2 == 0 else -200.0)
			PaperMotion.pop_in(card)
	for id: int in _cards.keys():
		if _state.seat_of(id) < 0:
			var gone: SeatCard = _cards[id]
			_cards.erase(id)
			PaperMotion.crumple(gone)
	for i in count:
		var seat: Dictionary = _state.seats[i]
		var card: SeatCard = _cards[seat.id]
		var shown: String = seat.name if seat.name != "" else tr("PLAYER_DEFAULT") % (i + 1)
		card.show_seat(shown, seat.id == _host_id, seat.ready)
		var target := _seat_position(i, count)
		if card.get_meta("target", Vector2.INF) != target:
			card.set_meta("target", target)
			card.set_meta("rest_position", target)
			if card.has_meta("placed"):
				PaperMotion.move_to(card, target)
			card.set_meta("placed", true)
	_ready_button.text = tr("LOBBY_NOT_READY") if _is_ready else tr("LOBBY_READY")
	_start_button.visible = Net.is_host
	_start_button.modulate.a = 1.0 if _state.can_start() else 0.5


func _seat_position(i: int, count: int) -> Vector2:
	var rows := 1 if count <= ROW_MAX else 2
	var top_count := count if rows == 1 else ceili(count / 2.0)
	var row := 0 if i < top_count else 1
	var in_row := top_count if row == 0 else count - top_count
	var col := i if row == 0 else i - top_count
	return Vector2(960.0 + (col - (in_row - 1) / 2.0) * SPACING.x,
			SEATS_CENTER_Y + (row - (rows - 1) / 2.0) * SPACING.y)


func _show_banner(key: String, red := false) -> void:
	if _banner and is_instance_valid(_banner):
		_banner.queue_free()
	var banner := PaperBanner.new(tr(key), red)
	_banner = banner
	banner.position = Vector2(960, 860 if _room.visible else 140)
	add_child(banner)
	Sound.play("ui_denied" if red else "ui_click", -4.0)
	await PaperMotion.drop_in(banner, 500.0, 0.5).finished
	await get_tree().create_timer(2.2, false).timeout
	if is_instance_valid(banner):
		await PaperMotion.lift_away(banner).finished
		if is_instance_valid(banner):
			banner.queue_free()


func _deny(piece: CanvasItem) -> void:
	Sound.play("ui_denied")
	PaperMotion.shake(piece)


func _button(key: String, rect: Rect2, action: Callable) -> PaperButton:
	var button := PaperButton.new()
	button.position = rect.position
	button.size = rect.size
	button.text = tr(key)
	button.add_theme_font_size_override("font_size", 48)
	button.pressed.connect(action)
	return button


func _label(key: String, rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.text = tr(key)
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DISPLAY)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.78))
	return label


# Ink on a cream strip, as on the setup cards.
func _style_edit(edit: LineEdit, font_size: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_width_bottom = 6
	style.border_color = SeatCard.INK
	style.set_corner_radius_all(10)
	for state in ["normal", "focus"]:
		edit.add_theme_stylebox_override(state, style)
	edit.add_theme_font_override("font", DISPLAY)
	edit.add_theme_font_size_override("font_size", font_size)
	edit.add_theme_color_override("font_color", SeatCard.INK)
	edit.add_theme_color_override("caret_color", SeatCard.INK)
	edit.add_theme_color_override("font_placeholder_color", Color(SeatCard.INK, 0.4))
	edit.context_menu_enabled = false


# Clicking away from a text field puts the pen down.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is LineEdit and not focused.get_global_rect().has_point(event.position):
			focused.release_focus()
