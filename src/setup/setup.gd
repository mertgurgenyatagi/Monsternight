extends Control
## The setup screen: 2 to 8 paper name cards, one per player. Begin stores the players in
## Match once the names are valid; Back returns to the title.

const CARD_COUNT_DEFAULT := 2
const ROW_MAX := 4
const SPACING := Vector2(280, 360)
const ROWS_CENTER_Y := 545.0

@onready var _cards_root: Node2D = $Cards
@onready var _add: PaperButton = $Add
@onready var _remove: PaperButton = $Remove
@onready var _begin: PaperButton = $Begin
@onready var _back: PaperButton = $Back

var _cards: Array[NameCard] = []
var _leaving := false


func _ready() -> void:
	Sound.play_music("title")
	var earlier := Match.names()
	for i in maxi(earlier.size(), CARD_COUNT_DEFAULT):
		_add_card(earlier[i] if i < earlier.size() else "")
	_layout(false)
	_refresh()

	_add.pressed.connect(_on_add)
	_remove.pressed.connect(_on_remove)
	_begin.pressed.connect(_on_begin)
	_back.pressed.connect(_on_back)

	PaperMotion.drop_in($Heading, 300.0, 0.8, 0.2)
	for i in _cards.size():
		PaperMotion.pop_in(_cards[i], 0.5 + i * 0.12)
	var buttons: Array[PaperButton] = [_back, _add, _remove, _begin]
	for i in buttons.size():
		buttons[i].enter(0.9 + i * 0.12)


func _on_add() -> void:
	if _cards.size() >= Match.MAX_PLAYERS:
		_deny(_add)
		return
	var card := _add_card("")
	_layout(true)
	Sound.play("flip")
	PaperMotion.slide_in(card, 2100.0 if _cards.size() % 2 == 0 else -200.0)
	_refresh()


func _on_remove() -> void:
	if _cards.size() <= Match.MIN_PLAYERS:
		_deny(_remove)
		return
	var card: NameCard = _cards.pop_back()
	Sound.play("crumple")
	PaperMotion.crumple(card)
	_layout(true)
	_refresh()


func _on_begin() -> void:
	if not _begin_ready():
		_deny(_begin)
		return
	if Match.start(_typed()):
		_leave("res://src/pregame/pregame.tscn")


func _on_back() -> void:
	_leave("res://src/title/title.tscn")


func _leave(path: String) -> void:
	if _leaving:
		return
	_leaving = true
	Scenes.change_to(path)


func _deny(button: PaperButton) -> void:
	Sound.play("ui_denied")
	PaperMotion.shake(button)


func _add_card(text: String) -> NameCard:
	var card := NameCard.new()
	card.seat = _cards.size()
	card.name_changed.connect(_on_names_changed)
	_cards_root.add_child(card)
	card.text = text
	_cards.append(card)
	return card


# Cards fill a row of up to four, then a second row, each row centered.
func _layout(animate: bool) -> void:
	var count := _cards.size()
	var rows := 1 if count <= ROW_MAX else 2
	var top_count := count if rows == 1 else ceili(count / 2.0)
	for i in count:
		var row := 0 if i < top_count else 1
		var in_row := top_count if row == 0 else count - top_count
		var col := i if row == 0 else i - top_count
		var x := 960.0 + (col - (in_row - 1) / 2.0) * SPACING.x
		var y := ROWS_CENTER_Y + (row - (rows - 1) / 2.0) * SPACING.y
		var card := _cards[i]
		card.seat = i
		if animate and card.has_meta("rest_position"):
			PaperMotion.move_to(card, Vector2(x, y))
		else:
			card.position = Vector2(x, y)
			card.set_meta("rest_position", card.position)


func _typed() -> Array[String]:
	var result: Array[String] = []
	for card in _cards:
		result.append(card.text)
	return result


func _begin_ready() -> bool:
	return Match.duplicates(_typed()).is_empty()


func _on_names_changed() -> void:
	var before := _cards.filter(func(c: NameCard) -> bool: return c.bad)
	_refresh()
	for card: NameCard in _cards:
		if card.bad and card not in before:
			Sound.play("ui_denied", -6.0)
			PaperMotion.shake(card)


func _refresh() -> void:
	var dupes := Match.duplicates(_typed())
	for i in _cards.size():
		_cards[i].set_bad(i in dupes)
	_begin.modulate.a = 1.0 if dupes.is_empty() else 0.5
	_add.modulate.a = 1.0 if _cards.size() < Match.MAX_PLAYERS else 0.5
	_remove.modulate.a = 1.0 if _cards.size() > Match.MIN_PLAYERS else 0.5


# Clicking anywhere but the name being typed puts the pen down.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is LineEdit and not focused.get_global_rect().has_point(event.position):
			focused.release_focus()
