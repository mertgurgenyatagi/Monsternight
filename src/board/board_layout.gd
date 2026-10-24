class_name BoardLayout
## Where everything on the board goes. Each location's x range is worked out from board.md's
## space counts, and the lanes' heights are set here, so the scenery (part 6) and the path
## (part 7) agree. Move a lane or change a count here, never by hand in the scenery.
##
## World x runs from 0 at the village end to `width()` at the castle gate. The view is always
## one 1080-tall screen at the old zoom, so world y is screen y there; the zoom shows a little more
## above and below.

enum Lane { MAIN, UPPER, LOWER }

const SPACE := 220.0 # the room each space takes along the road
const LEAD_IN := 500.0 # before the first space, so the start isn't against the edge
const LEAD_OUT := 900.0 # after the last space: the castle gate, then the board's end
const HILL_IMAGE_WIDTH := 2400.0 # church_hill.png as drawn
const CHURCH_INSET := 100.0 # the church path's first and last space, from the hill's edges

## The locations in order, with board.md's space counts. A split's width is set by its longer
## path; the first split is the church path's spaces plus its insets, which is the hill's width
## too. A split can also have `pad`, in spaces of extra width, so its ramps lie outside its
## paths' spaces.
const LOCATIONS := [
	{"id": "village", "spaces": 12},
	{"id": "graveyard", "spaces": 12, "split": true, "ramp": 600.0},
	{"id": "forest", "spaces": 12},
	{"id": "swamp", "spaces": 10, "split": true, "ramp": 220.0, "pad": 2.0},
	{"id": "castle", "spaces": 15},
]

const MAIN_Y := 880.0 # the road
const UPPER_Y := 627.0 # over the church hill, and the boardwalk
const LOWER_Y := 935.0 # through the graveyard, and the bog
const GROUND_Y := 750.0 # the top of the ground strips
const PROP_BASE_Y := 810.0 # where tall props stand, their feet hidden behind the ground strip
const HILL_TOP_Y := 542.0 # the top of the hill's plateau, well over the upper lane so its spaces stand on the grass

static var _locations: Array[Dictionary] = []


## The locations with their world x ranges: id, from, to, and for a split its ramp, the run
## over which its paths climb away from the road and back.
static func locations() -> Array[Dictionary]:
	if _locations.is_empty():
		var x := 0.0
		for i in LOCATIONS.size():
			var location: Dictionary = LOCATIONS[i].duplicate()
			var span: float = (location.spaces + location.get("pad", 0.0)) * SPACE
			if location.id == "graveyard":
				span = hill_width()
			if i == 0:
				span += LEAD_IN
			if i == LOCATIONS.size() - 1:
				span += LEAD_OUT
			location.from = x
			location.to = x + span
			x += span
			_locations.append(location)
	return _locations


## The width of the church hill: the church path's spaces and the room at either end. The hill's
## picture is stretched sideways to this.
static func hill_width() -> float:
	var spaces := 0
	for each in LOCATIONS:
		if each.id == "graveyard":
			spaces = each.spaces
	return spaces * SPACE + CHURCH_INSET * 2.0


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
## corner, which is half the zoomed view left of its centre.
static func layer_x(x: float, scroll: float) -> float:
	return BoardCamera.HALF_WIDTH + scroll * (x - BoardCamera.HALF_WIDTH)
