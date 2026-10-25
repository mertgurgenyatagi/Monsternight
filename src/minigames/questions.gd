class_name Questions
extends RefCounted
## The 1000 Shot in the Dark questions (`data/questions.json`) and the four board groups they are
## served from (`data/question_groups.json`). A fine category the table does not list goes to the
## default group with a warning. Numbers are read and shown with a thin space between thousands.

const QUESTIONS := "res://data/questions.json"
const GROUPS := "res://data/question_groups.json"
const THIN := " "
const MINUS := "−"
## The board's groups, in the order of the spaces' letters.
const IDS: Array[String] = ["atlas", "archive", "lab", "stage"]

static var _all: Array = []
static var _by_group := {} # group -> array of questions
static var _by_id := {}


## Reads both files once.
static func load_all() -> void:
	if not _all.is_empty():
		return
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GROUPS))
	var group_of := {}
	for group: String in table.groups:
		for category: String in table.groups[group]:
			group_of[category] = group
	for id in IDS:
		_by_group[id] = []
	_all = JSON.parse_string(FileAccess.get_file_as_string(QUESTIONS))
	var warned := {}
	for q: Dictionary in _all:
		_by_id[int(q.id)] = q
		var group: String = group_of.get(q.category, "")
		if group == "":
			group = table.default
			if not warned.has(q.category):
				warned[q.category] = true
				push_warning("Questions: category %s is not in a group, so it goes to %s" % [q.category, group])
		_by_group[group].append(q)


static func group_of(q: Dictionary) -> String:
	load_all()
	for group in IDS:
		if q in _by_group[group]:
			return group
	return ""


static func by_id(id: int) -> Dictionary:
	load_all()
	return _by_id.get(id, {})


## A question of `group` whose id is not in `asked` (a dictionary of ids). A group that has run dry
## starts over: its ids are taken out of `asked` first.
static func pick(group: String, asked: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	load_all()
	var pool: Array = _by_group[group]
	var fresh := pool.filter(func(q: Dictionary) -> bool: return not asked.has(int(q.id)))
	if fresh.is_empty():
		for q: Dictionary in pool:
			asked.erase(int(q.id))
		fresh = pool
	var chosen: Dictionary = fresh[rng.randi_range(0, fresh.size() - 1)]
	asked[int(chosen.id)] = true
	return chosen


## The question's words in the current language.
static func text(q: Dictionary) -> String:
	return q.question_tr if Settings.language == "tr" else q.question_en


## The decimal mark of the current language.
static func decimal_mark() -> String:
	return "," if Settings.language == "tr" else "."


## `value` for reading: thin spaces between thousands, the language's decimal mark, a true minus.
static func format(value: float) -> String:
	var whole := is_equal_approx(value, roundf(value))
	var s := str(int(roundf(value))) if whole else ("%.2f" % value).rstrip("0").rstrip(".")
	return group_digits(s)


## Groups the digits of a typed or formatted number (`-12345.5` -> `−12 345,5` in Turkish).
static func group_digits(s: String) -> String:
	var negative := s.begins_with("-")
	if negative:
		s = s.substr(1)
	var parts := s.replace(",", ".").split(".")
	var whole := parts[0]
	var out := ""
	for i in whole.length():
		if i > 0 and (whole.length() - i) % 3 == 0:
			out += THIN
		out += whole[i]
	if parts.size() > 1:
		out += decimal_mark() + parts[1]
	return (MINUS if negative else "") + out
