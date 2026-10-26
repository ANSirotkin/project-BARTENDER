class_name Materials
## Material table. Index = material id stored in the grid (one byte per cell).
## Add new materials by appending to every array below.

const EMPTY := 0
const GLASS := 1
const WATER := 2
const OIL := 3
const SYRUP := 4

const COUNT := 5

# Heavier liquids sink below lighter ones.
const DENSITY := [0, 100, 10, 8, 14]
# Max cells a liquid slides sideways per step (higher = runnier).
const FLOW := [0, 0, 4, 3, 1]
# Chance per step that it tries to slide at all (lower = more viscous).
const FLOW_CHANCE := [0.0, 0.0, 1.0, 1.0, 0.2]
const IS_STATIC := [false, true, false, false, false]
# Keep colors opaque; the shader handles translucency.
const COLORS := [
	Color(0, 0, 0, 0),
	Color(0.80, 0.90, 1.00, 1.0),  # glass
	Color(0.20, 0.50, 1.00, 1.0),  # water
	Color(0.95, 0.80, 0.20, 1.0),  # oil
	Color(0.60, 0.10, 0.25, 1.0),  # syrup
]
