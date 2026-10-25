extends Node
## Online play's one connection: a WebSocketPeer to the relay (tools/relay), in a room named by a
## 4-letter code. The protocol is our own JSON. Out: {to, data} (to 0 is everyone else). In:
## hello (my id, whether I am the host, the peers), join, leave, host (the host left; this is the new one), msg, and full or missing when the
## relay refuses. `send` and `broadcast` carry a kind and a payload, so the game never sees JSON.
## Nothing here waits on a timer of a peer's answer (a background tab throttles its timers).

signal connected ## hello arrived: `my_id` and `is_host` are set
signal refused(reason: String) ## "full", "missing" or "closed" before hello
signal disconnected ## the socket dropped for good, after the one retry
signal peer_joined(id: int)
signal peer_left(id: int)
signal host_changed(id: int) ## the host left and the relay named a new one (possibly me: `is_host` is already set)
signal received(from: int, kind: String, payload: Dictionary)

const LOCAL_RELAY := "ws://127.0.0.1:8787"
## The deployed relay, a `wss://monsternight-relay.ciplaksamuray12.workers.dev` address. Empty until the
## relay is deployed (tools/relay/deploy.md), and then every build uses the local one.
const PRODUCTION_RELAY := ""
## The game's itch.io page, `https://ciplaksamuray.itch.io/monsternight`. The page runs inside an iframe whose own
## address is not one to share, so Copy link builds on this instead. Empty: the page's own address.
const PAGE_URL := ""
## No I, O, 0 or 1: they look alike.
const CODE_LETTERS := "ABCDEFGHJKLMNPQRSTUVWXYZ"
const CODE_LENGTH := 4

var my_id := 0
var is_host := false
var peers: Array[int] = [] ## everyone else in the room
var code := ""
## The peer id of each player in a started match, by the player's name (the lobby fills it).
var id_by_name := {}

var _ws := WebSocketPeer.new()
var _state := "idle" # idle, connecting, open
var _joining := false # the room is expected to exist
var _retried := false
var _heard := false # hello arrived on this socket


## A fresh room code.
static func new_code() -> String:
	var result := ""
	for i in CODE_LENGTH:
		result += CODE_LETTERS[randi() % CODE_LETTERS.length()]
	return result


## A typed code as it will be used: upper case, without anything outside the alphabet. Returns ""
## when what is left is not a whole code.
static func clean_code(raw: String) -> String:
	var result := ""
	for c in raw.to_upper():
		if c in CODE_LETTERS:
			result += c
	return result if result.length() == CODE_LENGTH else ""


## One outgoing message as the text that goes over the socket.
static func encode(to: int, kind: String, payload: Dictionary) -> String:
	return JSON.stringify({"to": to, "data": {"k": kind, "p": payload}})


## One text from the relay as a dictionary, or {} when it is not one of ours. `msg` carries
## `kind` and `payload` unpacked.
static func decode(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var parsed = json.data
	if not parsed is Dictionary or not parsed.get("t") is String:
		return {}
	if parsed.t == "msg":
		var data = parsed.get("data")
		if not data is Dictionary or not data.get("k") is String:
			return {}
		parsed["kind"] = data.k
		parsed["payload"] = data.get("p") if data.get("p") is Dictionary else {}
	return parsed


## The relay: `-- --relay URL` on the command line, `?relay=URL` in the page's address, the deployed
## one, or the local one.
static func relay_url() -> String:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--relay")
	if at >= 0 and at + 1 < args.size():
		return args[at + 1]
	var found := page_param("relay")
	if found != "":
		return found
	return PRODUCTION_RELAY if PRODUCTION_RELAY != "" else LOCAL_RELAY


## A room code from `?room=` in the page's address or `-- --room CODE`, or "".
static func room_from_link() -> String:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--room")
	if at >= 0 and at + 1 < args.size():
		return clean_code(args[at + 1])
	return clean_code(page_param("room"))


## The address someone can open to land in this room, or the room's code alone off the web.
static func link_for(room: String) -> String:
	if OS.has_feature("web"):
		var base = PAGE_URL if PAGE_URL != "" else JavaScriptBridge.eval("location.origin + location.pathname")
		return "%s?room=%s" % [base, room]
	return room


## A query parameter of the page's address; "" off the web.
static func page_param(key: String) -> String:
	if not OS.has_feature("web"):
		return ""
	var found = JavaScriptBridge.eval("new URLSearchParams(location.search).get('%s') || ''" % key)
	return found if found is String else ""


## A debug setting for tests: `-- --key value` on a desktop run, `?key=value` on the web. "1" for a flag
## with no value, "" when absent. A release build has none, so a shared link cannot change the rules.
static func debug_value(key: String) -> String:
	if OS.has_feature("release"):
		return ""
	var args := OS.get_cmdline_user_args()
	var at := args.find("--" + key)
	if at >= 0:
		return args[at + 1] if at + 1 < args.size() and not args[at + 1].begins_with("--") else "1"
	return page_param(key)


## Puts text on the clipboard: the browser's on the web, the system's elsewhere.
static func copy_text(text: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("navigator.clipboard && navigator.clipboard.writeText(%s)" % JSON.stringify(text))
	else:
		DisplayServer.clipboard_set(text)


func _process(_delta: float) -> void:
	if _state == "idle":
		return
	_ws.poll()
	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if _state == "connecting":
				_state = "open"
			while _ws.get_available_packet_count() > 0:
				_handle(decode(_ws.get_packet().get_string_from_utf8()))
		WebSocketPeer.STATE_CLOSED:
			_on_closed()


## Opens the room `room_code` (the host's code is made by `new_code`). `existing` is true for
## someone joining, so the relay says "missing" instead of making the room. Returns false when
## the code is not one.
func open_room(room_code: String, existing: bool) -> bool:
	room_code = clean_code(room_code)
	if room_code == "":
		return false
	leave()
	code = room_code
	_joining = existing
	_retried = false
	return _connect()


## Closes the socket and forgets the room.
func leave() -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_ws.close()
	_state = "idle"
	_clear()


## True once hello has arrived and the socket is open.
func is_online() -> bool:
	return _state == "open" and _heard


## Sends to one peer.
func send(to: int, kind: String, payload := {}) -> void:
	if _state == "open":
		_ws.send_text(encode(to, kind, payload))


## Sends to everyone else in the room.
func broadcast(kind: String, payload := {}) -> void:
	send(0, kind, payload)


func _connect() -> bool:
	_ws = WebSocketPeer.new()
	_heard = false
	var url := "%s/room/%s%s" % [relay_url(), code, "?join=1" if _joining else ""]
	if _ws.connect_to_url(url) != OK:
		_state = "idle"
		refused.emit("closed")
		return false
	_state = "connecting"
	return true


func _clear() -> void:
	my_id = 0
	is_host = false
	peers.clear()
	_heard = false


func _handle(msg: Dictionary) -> void:
	match msg.get("t", ""):
		"hello":
			my_id = int(msg.id)
			is_host = bool(msg.get("host", false))
			peers.clear()
			for p in msg.get("peers", []):
				peers.append(int(p))
			_heard = true
			connected.emit()
		"join":
			peers.append(int(msg.id))
			peer_joined.emit(int(msg.id))
		"leave":
			peers.erase(int(msg.id))
			peer_left.emit(int(msg.id))
		"host":
			is_host = int(msg.id) == my_id
			host_changed.emit(int(msg.id))
		"msg":
			received.emit(int(msg.from), msg.kind, msg.payload)
		"full", "missing":
			_state = "idle"
			refused.emit(msg.t)


# A drop after hello is tried once more (the full rejoin is part 41); a socket that closed
# before hello, or the second drop, ends the connection.
func _on_closed() -> void:
	if _state == "idle":
		return
	var was_heard := _heard
	_state = "idle"
	if was_heard and not _retried:
		_retried = true
		_clear()
		if _connect():
			return
	_clear()
	if was_heard:
		disconnected.emit()
	else:
		refused.emit("closed")
