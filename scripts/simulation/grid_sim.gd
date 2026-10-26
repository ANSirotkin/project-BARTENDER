class_name GridSim
## Pure simulation: no nodes, no rendering. One byte per cell.

var w: int
var h: int
var cells := PackedByteArray()
var touched := PackedByteArray()  # cells already moved this step
var flip := false                 # alternate scan direction to avoid drift
# Chance per tick that a cell actually displaces a lighter LIQUID (not empty air).
# Lower = slower, more bubbly sinking/rising through other liquids.
var sink_chance := 0.4

var density := PackedInt32Array()
var flow := PackedInt32Array()
var flow_chance := PackedFloat32Array()
var is_static := PackedByteArray()


func _init(width: int, height: int) -> void:
	w = width
	h = height
	cells.resize(w * h)
	touched.resize(w * h)
	density = PackedInt32Array(Materials.DENSITY)
	flow = PackedInt32Array(Materials.FLOW)
	flow_chance = PackedFloat32Array(Materials.FLOW_CHANCE)
	is_static.resize(Materials.COUNT)
	for m in Materials.COUNT:
		is_static[m] = 1 if Materials.IS_STATIC[m] else 0


func make_glass(wall := 2) -> void:
	cells.fill(Materials.EMPTY)
	for y in h:
		for t in wall:
			cells[y * w + t] = Materials.GLASS
			cells[y * w + (w - 1 - t)] = Materials.GLASS
	for x in w:
		for t in wall:
			cells[(h - 1 - t) * w + x] = Materials.GLASS


func add_cells(cx: int, cy: int, radius: int, mat: int) -> void:
	for y in range(cy - radius, cy + radius + 1):
		for x in range(cx - radius, cx + radius + 1):
			if x < 0 or x >= w or y < 0 or y >= h:
				continue
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) > radius * radius:
				continue
			var i := y * w + x
			if cells[i] == Materials.EMPTY:
				cells[i] = mat


func count_material(mat: int) -> int:
	var n := 0
	for c in cells:
		if c == mat:
			n += 1
	return n


func step() -> void:
	touched.fill(0)
	flip = not flip
	for y in range(h - 1, -1, -1):  # bottom to top
		var row := y * w
		for xi in w:
			var x := xi if flip else w - 1 - xi
			var i := row + x
			var m := cells[i]
			if m == 0 or touched[i] == 1 or is_static[m] == 1:
				continue
			_update_liquid(i, x, y, m)


func _passable(d: int, target: int) -> bool:
	# Can a cell of density d move into a cell holding `target`?
	return is_static[target] == 0 and density[target] < d


func _swap(a: int, b: int) -> void:
	var t := cells[a]
	cells[a] = cells[b]
	cells[b] = t
	touched[a] = 1
	touched[b] = 1


func _update_liquid(i: int, x: int, y: int, m: int) -> void:
	var d := density[m]

	if y + 1 < h:
		# 1. fall straight down (or sink through lighter liquid)
		var below := cells[i + w]
		if _passable(d, below) and (below == Materials.EMPTY or randf() < sink_chance):
			_swap(i, i + w)
			return
		# 2. fall diagonally
		var dir := 1 if randf() < 0.5 else -1
		for k in 2:
			var nx := x + dir
			if nx >= 0 and nx < w:
				var j := (y + 1) * w + nx
				var t := cells[j]
				if _passable(d, t) and (t == Materials.EMPTY or randf() < sink_chance):
					_swap(i, j)
					return
			dir = -dir

	# 3. spread sideways, displacing lighter liquids too (viscosity = how rarely / how far)
	if randf() > flow_chance[m]:
		return
	var sdir := 1 if randf() < 0.5 else -1
	for k in 2:
		var dest := x
		for s in range(1, flow[m] + 1):
			var nx := x + sdir * s
			if nx < 0 or nx >= w:
				break
			var t := cells[y * w + nx]
			if not _passable(d, t):
				break
			if t != Materials.EMPTY and randf() > sink_chance:
				break
			dest = nx
		if dest != x:
			_swap(i, y * w + dest)
			return
		sdir = -sdir
