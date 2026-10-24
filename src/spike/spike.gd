extends Control
## THROWAWAY (part 32): the online spike. A room code, a connection to the relay (tools/relay), the
## peers in the room, and a ping button that measures the round trip. The protocol is JSON over a
## plain WebSocketPeer; see the part 32 notes in docs/microplan.md.

const DEFAULT_RELAY := "ws://127.0.0.1:8787"

var _ws := WebSocketPeer.new()
var _open := false
var _id := 0
var _peers: Array[int] = []
var _sent := {}
var _next_ping := 1
var _code: LineEdit
var _relay: LineEdit
var _list: Label
var _log: RichTextLabel


func _ready() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(60, 40)
	box.size = Vector2(1500, 900)
	add_child(box)
	_relay = LineEdit.new()
	_relay.text = _relay_from_url()
	_relay.name = "Relay"
	box.add_child(_relay)
	var row := HBoxContainer.new()
	box.add_child(row)
	_code = LineEdit.new()
	_code.name = "Code"
	_code.placeholder_text = "room code"
	_code.custom_minimum_size.x = 300
	row.add_child(_code)
	var host := Button.new()
	host.name = "Host"
	host.text = "Host"
	host.pressed.connect(_host)
	row.add_child(host)
	var join := Button.new()
	join.name = "Join"
	join.text = "Join"
	join.pressed.connect(_join)
	row.add_child(join)
	var leave := Button.new()
	leave.name = "Leave"
	leave.text = "Leave"
	leave.pressed.connect(_leave)
	row.add_child(leave)
	var ping := Button.new()
	ping.name = "Ping"
	ping.text = "Ping everyone"
	ping.pressed.connect(_ping)
	row.add_child(ping)
	_list = Label.new()
	_list.name = "Peers"
	_list.text = "not connected"
	box.add_child(_list)
	_log = RichTextLabel.new()
	_log.name = "Log"
	_log.custom_minimum_size.y = 600
	_log.scroll_following = true
	box.add_child(_log)


func _process(_delta: float) -> void:
	_ws.poll()
	var state := _ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		_open = true
		while _ws.get_available_packet_count() > 0:
			_receive(JSON.parse_string(_ws.get_packet().get_string_from_utf8()))
	elif state == WebSocketPeer.STATE_CLOSED and _open:
		_open = false
		_id = 0
		_peers.clear()
		_show("closed (%d)" % _ws.get_close_code())


# The relay is ws://127.0.0.1:8787 unless the page was opened with ?relay=<url>.
func _relay_from_url() -> String:
	if OS.has_feature("web"):
		var found = JavaScriptBridge.eval("new URLSearchParams(location.search).get('relay') || ''")
		if found is String and found != "":
			return found
	return DEFAULT_RELAY


# Host makes a code and joins it; Join uses the typed one. Both are the same socket to the relay.
func _host() -> void:
	const LETTERS := "ABCDEFGHJKLMNPQRSTUVWXYZ"
	var code := ""
	for i in 4:
		code += LETTERS[randi() % LETTERS.length()]
	_code.text = code
	_join()


func _join() -> void:
	_leave()
	if _code.text.strip_edges() == "":
		_show("type a code first")
		return
	_ws = WebSocketPeer.new()
	var err := _ws.connect_to_url("%s/room/%s" % [_relay.text, _code.text.strip_edges().to_upper()])
	_show("connecting: %s" % error_string(err))


func _leave() -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_ws.close()


func _ping() -> void:
	if not _open:
		return
	var n := _next_ping
	_next_ping += 1
	_sent[n] = Time.get_ticks_usec()
	_send(0, {"k": "ping", "n": n})


func _send(to: int, data: Dictionary) -> void:
	_ws.send_text(JSON.stringify({"to": to, "data": data}))


func _receive(msg: Dictionary) -> void:
	match msg.t:
		"hello":
			_id = int(msg.id)
			_peers.clear()
			for p in msg.peers:
				_peers.append(int(p))
			_show("joined as %d, peers %s" % [_id, _peers])
		"join":
			_peers.append(int(msg.id))
			_show("peer %d joined" % msg.id)
		"leave":
			_peers.erase(int(msg.id))
			_show("peer %d left" % msg.id)
		"msg":
			var data: Dictionary = msg.data
			if data.k == "ping":
				_send(int(msg.from), {"k": "pong", "n": data.n})
			elif data.k == "pong":
				var ms := (Time.get_ticks_usec() - int(_sent.get(int(data.n), 0))) / 1000.0
				_show("pong %d from %d in %.1f ms" % [data.n, msg.from, ms])
	_list.text = "me %d, peers %s" % [_id, _peers]


func _show(line: String) -> void:
	print("[spike] ", line)
	_log.append_text(line + "\n")
