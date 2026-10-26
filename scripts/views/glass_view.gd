extends TextureRect
## Owns a GridSim, steps it, and uploads the raw material ids as an R8 texture.
## The shader turns ids into colors, so there is no per-cell loop in GDScript.
## Scene setup: TextureRect, expand_mode = Ignore Size, stretch_mode = Scale,
## custom size (e.g. 384x512), ShaderMaterial using liquid.gdshader.

@export var grid_w := 20
@export var grid_h := 20
@export var brush_radius := 1

var sim: GridSim
var image: Image
var tex: ImageTexture
var current_material := Materials.WATER
var pouring := false
var _tick := 0


func _ready() -> void:
	sim = GridSim.new(grid_w, grid_h)
	sim.make_glass()

	# Material ids must NOT be interpolated, so sample with nearest filtering.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	image = Image.create(grid_w, grid_h, false, Image.FORMAT_R8)
	tex = ImageTexture.create_from_image(image)
	texture = tex

	# Palette texture: one pixel per material, read by the shader.
	var pal := Image.create(Materials.COUNT, 1, false, Image.FORMAT_RGBA8)
	for m in Materials.COUNT:
		pal.set_pixel(m, 0, Materials.COLORS[m])
	var mat := material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("palette_tex", ImageTexture.create_from_image(pal))
		mat.set_shader_parameter("palette_size", float(Materials.COUNT))
	else:
		push_warning("glass_view: no ShaderMaterial assigned, nothing will be visible")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pouring = event.pressed
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: current_material = Materials.WATER
			KEY_2: current_material = Materials.OIL
			KEY_3: current_material = Materials.SYRUP
			KEY_R: sim.make_glass()


func _physics_process(_delta: float) -> void:
	if pouring:
		var p := get_local_mouse_position() / size * Vector2(grid_w, grid_h)
		sim.add_cells(int(p.x), int(p.y), brush_radius, current_material)
	var t0 := Time.get_ticks_usec()
	sim.step()
	var t1 := Time.get_ticks_usec()
	image.set_data(grid_w, grid_h, false, Image.FORMAT_R8, sim.cells)
	tex.update(image)
	var t2 := Time.get_ticks_usec()

	_tick += 1
	if _tick % 120 == 0:
		print("FPS: ", Engine.get_frames_per_second(),
			"  step ms: ", (t1 - t0) / 1000.0,
			"  upload ms: ", (t2 - t1) / 1000.0)
