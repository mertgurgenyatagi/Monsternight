class_name Monsters
## The 8 monsters, in the order of characters.md. Everything that needs a monster's look reads it
## from here. The colors are sampled from the art, so a tint agrees with the drawing.

const IDS: Array[String] = ["dracula", "medusa", "frankenstein", "death", "hyde", "cthulhu", "wolfman", "dorian"]

const COLORS := {
	"dracula": Color("c82d32"),
	"medusa": Color("269265"),
	"frankenstein": Color("f9da54"),
	"death": Color("a654ce"),
	"hyde": Color("fa6d16"),
	"cthulhu": Color("3f978c"),
	"wolfman": Color("446395"),
	# His art is a burgundy jacket, but burgundy sits too close to Dracula's red, so this is the
	# pink the design asks for, at the jacket's hue.
	"dorian": Color("d6457f"),
}


## The translation key of the monster's name.
static func name_key(id: String) -> String:
	return "MONSTER_" + id.to_upper()


## The translation key of the monster's short power line (characters.md).
static func power_key(id: String) -> String:
	return "POWER_" + id.to_upper()


static func display_name(id: String) -> String:
	return TranslationServer.translate(name_key(id))


static func color(id: String) -> Color:
	return COLORS[id]


static func body(id: String) -> Texture2D:
	return load("res://assets/art/monsters/%s.png" % id)


static func portrait(id: String) -> Texture2D:
	return load("res://assets/art/monsters/%s_portrait.png" % id)


## The path of one of the monster's voices: "pick", "win" or "lose", for `Sound.play`.
static func voice(id: String, kind: String) -> String:
	return "voices/%s_%s" % [id, kind]
