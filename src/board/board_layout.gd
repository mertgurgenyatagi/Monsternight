class_name BoardLayout
## Where everything on the board goes. Each location's x range is worked out from board.md's
## space counts, and the lanes' heights are set here, so the scenery (part 6) and the path
## (part 7) agree. Move a lane or change a count here, never by hand in the scenery.
##
## World x runs from 0 at the village end to `width()` at the castle gate. The view is always
## one 1080-tall screen, so world y is screen y.

enum Lane { MAIN, UPPER, LOWER }

const SPACE := 220.0 # the room each space takes along the road
const LEAD_IN := 500.0 # before the first space, so the start isn't against the edge
const LEAD_OUT := 900.0 # after the last space: the castle gate, then the board's end
const HILL_WIDTH := 2400.0 # church_hill.png: the first split spans it

## The locations in order, with board.md's space counts. A split's width is set by its longer
## path; the first split is the hill's width instead.
const LOCATIONS := [
	{"id": "village", "spaces": 9},
	{"id": "graveyard", "spaces": 10, "split": true, "ramp": 600.0},
	{"id": "forest", "spaces": 9},
	{"id": "swamp", "spaces": 7, "split": true, "ramp": 220.0},
	{"id": "castle", "spaces": 11},
]

const MAIN_Y := 900.0 # the road
const UPPER_Y := 640.0 # over the church hill, and the boardwalk
const LOWER_Y := 990.0 # through the graveyard, and the bog
const GROUND_Y := 780.0 # the top of the ground strips
const PROP_BASE_Y := 840.0 # where tall props stand, their feet hidden behind the ground strip
const HILL_TOP_Y := 625.0 # the top of the hill's plateau, just under the upper lane

static var _locations: Array[Dictionary] = []


## The locations with their world x ranges: id, from, to, and for a split its ramp, the run
## over which its paths climb away from the road and back.
static func locations() -> Array[Dictionary]:
	if _locations.is_empty():
		var x := 0.0
		for i in LOCATIONS.size():
			var location: Dictionary = LOCATIONS[i].duplicate()
			var span: float = location.spaces * SPACE
			if location.id == "graveyard":
				span = HILL_WIDTH
			if i == 0:
				span += LEAD_IN
			if i == LOCATIONS.size() - 1:
				span += LEAD_OUT
			location.from = x
			location.to = x + span
			x += span
			_locations.append(location)
	return _locations


static func location(id: String) -> Dictionary:
	for each in locations():
		if each.id == id:
			return each
	return {}


## The location at this world x. Past either end, the nearest one.
static func location_at(x: float) -> Dictionary:
	for each in locations():
		if x < each.to:
			return each
	return locations()[-1]


## The whole board's width.
static func width() -> float:
	return locations()[-1].to


## Where the castle gate stands: the finish, a little past the last space.
static func gate_x() -> float:
	return width() - LEAD_OUT + SPACE * 1.6


## A lane's height at world x. Outside the splits every lane is the road. In a split, the upper
## and lower paths ease away from the road over the split's ramp, and back before it ends.
static func lane_y(lane: Lane, x: float) -> float:
	if lane == Lane.MAIN:
		return MAIN_Y
	var split := location_at(x)
	if not split.get("split", false):
		return MAIN_Y
	var away := smoothstep(split.from, split.from + split.ramp, x) \
			* (1.0 - smoothstep(split.to - split.ramp, split.to, x))
	return lerpf(MAIN_Y, UPPER_Y if lane == Lane.UPPER else LOWER_Y, away)


## Where a piece goes inside a parallax layer with this scroll scale, so it's in the middle of
## the screen when the camera's centre is at world x. Layers scroll from the camera's top-left
## corner, which is 960 px left of its centre.
static func layer_x(x: float, scroll: float) -> float:
	return 960.0 + scroll * (x - 960.0)
