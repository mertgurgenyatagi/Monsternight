class_name LobbyState
extends RefCounted
## A room's seats and the rules for them: who is in, what they are called, who is ready, and
## whether the host may start. The host keeps the truth and broadcasts `to_list`; everyone else
## only reads it with `from_list`. Seats stay in the order people joined.

## Each seat: {id: the peer's id, name: as typed ("" until they type one), ready: bool}.
var seats: Array[Dictionary] = []


## Seats a peer at the end. Returns false when they are already in or the room has 8.
func add(id: int) -> bool:
	if seat_of(id) >= 0 or seats.size() >= Match.MAX_PLAYERS:
		return false
	seats.append({"id": id, "name": "", "ready": false})
	return true


func remove(id: int) -> void:
	var at := seat_of(id)
	if at >= 0:
		seats.remove_at(at)


## The index of the peer's seat, or -1.
func seat_of(id: int) -> int:
	for i in seats.size():
		if seats[i].id == id:
			return i
	return -1


## True when this typed name, cleaned, is another seat's name too (case does not matter).
func name_taken(id: int, raw: String) -> bool:
	var me := seat_of(id)
	if me < 0:
		return false
	var mine := Match.clean_name(raw, me).to_lower()
	for i in seats.size():
		if i != me and Match.clean_name(seats[i].name, i).to_lower() == mine:
			return true
	return false


## Gives the peer this name, and their ready mark. Returns false, changing nothing, when the name
## is taken or the peer is not here.
func set_profile(id: int, raw: String, ready: bool) -> bool:
	var at := seat_of(id)
	if at < 0 or name_taken(id, raw):
		return false
	seats[at].name = raw.strip_edges().left(Match.NAME_LENGTH).strip_edges()
	seats[at].ready = ready
	return true


## The names as they will be at the start: "Player N" for a blank one.
func final_names() -> Array[String]:
	var result: Array[String] = []
	for i in seats.size():
		result.append(Match.clean_name(seats[i].name, i))
	return result


## The host may start with 3 to 8 seats, all ready, with different names.
func can_start() -> bool:
	if seats.size() < Match.MIN_PLAYERS or seats.size() > Match.MAX_PLAYERS:
		return false
	for seat in seats:
		if not seat.ready:
			return false
	return Match.duplicates(final_names()).is_empty()


func to_list() -> Array:
	return seats.duplicate(true)


func from_list(list: Array) -> void:
	seats.clear()
	for item in list:
		seats.append({"id": int(item.id), "name": str(item.name), "ready": bool(item.ready)})
