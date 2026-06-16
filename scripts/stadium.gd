extends Node3D

# Field dimensions (must match pitch.tscn)
const FIELD_HX := 25.0
const FIELD_HZ := 15.0

# Perimeter — flush against the pitch (no empty gap)
const RUNOFF      := 1.05   # track width beyond touchline
const BARRIER_H   := 1.05
const BARRIER_D   := 0.38
const STAND_INSET := 0.08

# Stand geometry
const ROWS         := 9
const ROW_DEPTH    := 1.15
const ROW_HEIGHT   := 0.78
const SEAT_SPACING := 0.88
const AISLE_EVERY  := 14    # seats between aisles

var _rng := RandomNumberGenerator.new()

var _concrete_mat: ShaderMaterial
var _seat_mat: ShaderMaterial
var _wall_mat: ShaderMaterial
var _track_mat: StandardMaterial3D
var _railing_mat: StandardMaterial3D
var _barrier_mat: StandardMaterial3D
var _pole_mat: StandardMaterial3D
var _crowd_body_mesh: CapsuleMesh
var _crowd_head_mesh: SphereMesh
var _crowd_mat: ShaderMaterial

const SKIN_TONES := [
	Color(0.96, 0.81, 0.68), Color(0.90, 0.72, 0.56),
	Color(0.80, 0.62, 0.46), Color(0.64, 0.47, 0.33),
	Color(0.45, 0.31, 0.22), Color(0.34, 0.23, 0.16),
]
const PALETTE_HOME := [
	Color(0.78, 0.06, 0.07), Color(0.90, 0.16, 0.10),
	Color(0.86, 0.78, 0.10), Color(0.95, 0.95, 0.95),
]
const PALETTE_AWAY := [
	Color(0.08, 0.18, 0.74), Color(0.16, 0.42, 0.86),
	Color(0.88, 0.88, 0.92), Color(0.10, 0.12, 0.20),
]
const PALETTE_MIX := [
	Color(0.74, 0.07, 0.08), Color(0.10, 0.18, 0.72),
	Color(0.84, 0.80, 0.10), Color(0.70, 0.70, 0.72),
	Color(0.95, 0.95, 0.95), Color(0.16, 0.66, 0.22),
]
const AD_COLORS := [
	Color(0.90, 0.10, 0.10), Color(0.10, 0.35, 0.95),
	Color(0.95, 0.75, 0.05), Color(0.05, 0.70, 0.35),
	Color(0.95, 0.95, 0.95), Color(0.85, 0.20, 0.70),
]


func _ready() -> void:
	_rng.randomize()
	_setup_materials()
	_build_runoff_ring()
	_build_corners()
	_build_long_side( 1.0, PALETTE_HOME)
	_build_long_side(-1.0, PALETTE_AWAY)
	_build_short_side( 1.0, PALETTE_MIX)
	_build_short_side(-1.0, PALETTE_MIX)
	_build_ad_boards()
	_build_corner_flags()
	_build_light_towers()


func _stand_start(axis: float) -> float:
	return axis + RUNOFF + BARRIER_D + STAND_INSET


func _setup_materials() -> void:
	_concrete_mat = ShaderMaterial.new()
	_concrete_mat.shader = load("res://shaders/concrete.gdshader")
	_concrete_mat.set_shader_parameter("base_color", Color(0.34, 0.34, 0.36))

	_seat_mat = ShaderMaterial.new()
	_seat_mat.shader = load("res://shaders/seat.gdshader")

	_wall_mat = ShaderMaterial.new()
	_wall_mat.shader = load("res://shaders/concrete.gdshader")
	_wall_mat.set_shader_parameter("base_color", Color(0.26, 0.27, 0.30))
	_wall_mat.set_shader_parameter("noise_scale", 8.0)

	_track_mat = StandardMaterial3D.new()
	_track_mat.albedo_color = Color(0.12, 0.38, 0.14)
	_track_mat.roughness = 0.92

	_railing_mat = StandardMaterial3D.new()
	_railing_mat.albedo_color = Color(0.72, 0.74, 0.78)
	_railing_mat.metallic = 0.85
	_railing_mat.roughness = 0.28

	_barrier_mat = StandardMaterial3D.new()
	_barrier_mat.albedo_color = Color(0.18, 0.19, 0.22)
	_barrier_mat.roughness = 0.75

	_pole_mat = StandardMaterial3D.new()
	_pole_mat.albedo_color = Color(0.55, 0.56, 0.60)
	_pole_mat.metallic = 0.75
	_pole_mat.roughness = 0.32

	_crowd_body_mesh = CapsuleMesh.new()
	_crowd_body_mesh.radius = 0.17
	_crowd_body_mesh.height = 0.48
	_crowd_body_mesh.radial_segments = 8
	_crowd_head_mesh = SphereMesh.new()
	_crowd_head_mesh.radius = 0.13
	_crowd_head_mesh.height = 0.26
	_crowd_head_mesh.radial_segments = 10
	_crowd_head_mesh.rings = 6

	_crowd_mat = ShaderMaterial.new()
	_crowd_mat.shader = load("res://shaders/crowd.gdshader")


# ── Runoff track flush with pitch edge ────────────────────────────────────────

func _build_runoff_ring() -> void:
	var ox := FIELD_HX + RUNOFF * 0.5
	var oz := FIELD_HZ + RUNOFF * 0.5
	var lx := FIELD_HX * 2.0 + RUNOFF * 2.0
	var lz := FIELD_HZ * 2.0 + RUNOFF * 2.0

	# North / south strips
	_add_mesh_box(Vector3(0.0, 0.015,  oz), Vector3(lx, 0.03, RUNOFF), _track_mat)
	_add_mesh_box(Vector3(0.0, 0.015, -oz), Vector3(lx, 0.03, RUNOFF), _track_mat)
	# East / west strips (between north/south corners)
	_add_mesh_box(Vector3( ox, 0.015, 0.0), Vector3(RUNOFF, 0.03, FIELD_HZ * 2.0), _track_mat)
	_add_mesh_box(Vector3(-ox, 0.015, 0.0), Vector3(RUNOFF, 0.03, FIELD_HZ * 2.0), _track_mat)

	# Low barrier wall on field side of track (separates pitch from stands)
	_build_barrier_long( 1.0)
	_build_barrier_long(-1.0)
	_build_barrier_short( 1.0)
	_build_barrier_short(-1.0)


func _build_barrier_long(side: float) -> void:
	var z := side * (FIELD_HZ + RUNOFF * 0.5)
	var len := FIELD_HX * 2.0 + RUNOFF * 2.0
	_add_mesh_box(Vector3(0.0, BARRIER_H * 0.5, z),
		Vector3(len, BARRIER_H, BARRIER_D), _barrier_mat)
	# Chrome handrail on top
	_add_mesh_box(Vector3(0.0, BARRIER_H + 0.04, z - side * 0.12),
		Vector3(len, 0.06, 0.06), _railing_mat)


func _build_barrier_short(side: float) -> void:
	var x := side * (FIELD_HX + RUNOFF * 0.5)
	var len := FIELD_HZ * 2.0
	_add_mesh_box(Vector3(x, BARRIER_H * 0.5, 0.0),
		Vector3(BARRIER_D, BARRIER_H, len), _barrier_mat)
	_add_mesh_box(Vector3(x - side * 0.12, BARRIER_H + 0.04, 0.0),
		Vector3(0.06, 0.06, len), _railing_mat)


func _build_corners() -> void:
	var cx := FIELD_HX + RUNOFF * 0.5
	var cz := FIELD_HZ + RUNOFF * 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_mesh_box(Vector3(sx * cx, 0.015, sz * cz),
				Vector3(RUNOFF, 0.03, RUNOFF), _track_mat)
			_add_mesh_box(Vector3(sx * cx, BARRIER_H * 0.5, sz * cz),
				Vector3(BARRIER_D + 0.1, BARRIER_H, BARRIER_D + 0.1), _barrier_mat)


# ── Long stands ───────────────────────────────────────────────────────────────

func _build_long_side(side: float, palette: Array) -> void:
	var stand_len := FIELD_HX * 2.0 + RUNOFF * 2.0 + 6.0
	var seat_count := int(stand_len / SEAT_SPACING)
	var first := _stand_start(FIELD_HZ)

	for row in ROWS:
		var z := side * (first + row * ROW_DEPTH)
		var y := row * ROW_HEIGHT
		var row_tint := 0.92 + float(row % 2) * 0.08

		# Concrete step with slight overhang toward field on row 0
		var step_z := z - side * (0.08 if row == 0 else 0.0)
		_add_mesh_box(Vector3(0.0, y + ROW_HEIGHT * 0.5, step_z),
			Vector3(stand_len, ROW_HEIGHT, ROW_DEPTH), _concrete_mat)

		# Individual seat backs along the row
		_build_seat_row(Vector3(0.0, y + ROW_HEIGHT + 0.12, z + side * 0.42),
			Vector3(stand_len, 0.0, 0.0), SEAT_SPACING, side, row_tint)

		# Aisle pillars
		_build_aisles_long(z, y, stand_len, side)

		var origin := Vector3(0.0, y + ROW_HEIGHT + 0.48, z)
		_spawn_crowd(seat_count, origin, Vector3(SEAT_SPACING, 0.0, 0.0), palette)

	# Front railing on first row (toward field)
	var rail_z := side * (first - ROW_DEPTH * 0.35)
	_add_mesh_box(Vector3(0.0, ROW_HEIGHT + 0.55, rail_z),
		Vector3(stand_len, 0.05, 0.05), _railing_mat)
	for px in range(-int(stand_len * 0.45), int(stand_len * 0.45), 4):
		_add_mesh_box(Vector3(px, ROW_HEIGHT * 0.35, rail_z),
			Vector3(0.05, ROW_HEIGHT * 0.5, 0.05), _railing_mat)

	_build_long_back_facade(side, stand_len, first)


func _build_long_back_facade(side: float, stand_len: float, first: float) -> void:
	var back_z := side * (first + ROWS * ROW_DEPTH)
	var top_y := ROWS * ROW_HEIGHT

	_add_mesh_box(Vector3(0.0, top_y * 0.5, back_z + side * 1.05),
		Vector3(stand_len, top_y + 2.2, 0.7), _wall_mat)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.55, 0.72, 0.88, 0.55)
	glass_mat.roughness = 0.05
	glass_mat.metallic = 0.1
	_add_mesh_box(Vector3(0.0, top_y + 0.8, back_z + side * 1.42),
		Vector3(stand_len * 0.88, 1.6, 0.08), glass_mat)

	for i in 6:
		var x: float = -stand_len * 0.42 + float(i) * (stand_len * 0.84 / 5.0)
		_add_led(Vector3(x, top_y + 1.2, back_z + side * 1.45),
			Vector3(stand_len / 7.0, 0.5, 0.1), AD_COLORS[i % AD_COLORS.size()])


# ── Short stands ──────────────────────────────────────────────────────────────

func _build_short_side(side: float, palette: Array) -> void:
	var first := _stand_start(FIELD_HX)
	var inner_len := FIELD_HZ * 2.0
	var stand_len := inner_len + (first + ROWS * ROW_DEPTH - FIELD_HX) * 0.0 + inner_len
	stand_len = inner_len + 4.0
	var seat_count := int(stand_len / SEAT_SPACING)

	for row in ROWS:
		var x := side * (first + row * ROW_DEPTH)
		var y := row * ROW_HEIGHT
		var row_tint := 0.92 + float(row % 2) * 0.08

		var step_x := x - side * (0.08 if row == 0 else 0.0)
		_add_mesh_box(Vector3(step_x, y + ROW_HEIGHT * 0.5, 0.0),
			Vector3(ROW_DEPTH, ROW_HEIGHT, stand_len), _concrete_mat)

		_build_seat_row(Vector3(x + side * 0.42, y + ROW_HEIGHT + 0.12, 0.0),
			Vector3(0.0, 0.0, stand_len), SEAT_SPACING, side, row_tint, true)

		_build_aisles_short(x, y, stand_len, side)

		var origin := Vector3(x, y + ROW_HEIGHT + 0.48, 0.0)
		_spawn_crowd(seat_count, origin, Vector3(0.0, 0.0, SEAT_SPACING), palette)

	var back_x := side * (first + ROWS * ROW_DEPTH)
	var top_y := ROWS * ROW_HEIGHT
	_add_mesh_box(Vector3(back_x + side * 1.05, top_y * 0.5, 0.0),
		Vector3(0.7, top_y + 2.2, stand_len), _wall_mat)


func _build_seat_row(origin: Vector3, axis_len: Vector3, spacing: float,
		side: float, tint: float, along_z: bool = false) -> void:
	var count := int(axis_len.length() / spacing)
	var step := axis_len / maxf(count, 1)
	var start := origin - step * (count * 0.5)
	var seat_mat := _seat_mat.duplicate() as ShaderMaterial
	seat_mat.set_shader_parameter("color_a", Color(0.14 * tint, 0.16 * tint, 0.20 * tint))
	seat_mat.set_shader_parameter("color_b", Color(0.20 * tint, 0.22 * tint, 0.28 * tint))

	for i in count:
		if i % AISLE_EVERY == AISLE_EVERY - 1:
			continue
		var pos := start + step * i
		var back_offset := Vector3(0.0, 0.18, side * 0.12) if not along_z else Vector3(side * 0.12, 0.18, 0.0)
		_add_mesh_box(pos + back_offset, Vector3(0.42, 0.36, 0.38) if not along_z else Vector3(0.38, 0.36, 0.42), seat_mat)


func _build_aisles_long(z: float, y: float, stand_len: float, side: float) -> void:
	for i in range(1, int(stand_len / (SEAT_SPACING * AISLE_EVERY))):
		var px := -stand_len * 0.45 + i * SEAT_SPACING * AISLE_EVERY
		_add_mesh_box(Vector3(px, y + ROW_HEIGHT * 0.5, z),
			Vector3(0.55, ROW_HEIGHT + 0.1, ROW_DEPTH + 0.1), _concrete_mat)


func _build_aisles_short(x: float, y: float, stand_len: float, side: float) -> void:
	for i in range(1, int(stand_len / (SEAT_SPACING * AISLE_EVERY))):
		var pz := -stand_len * 0.45 + i * SEAT_SPACING * AISLE_EVERY
		_add_mesh_box(Vector3(x, y + ROW_HEIGHT * 0.5, pz),
			Vector3(ROW_DEPTH + 0.1, ROW_HEIGHT + 0.1, 0.55), _concrete_mat)


# ── LED advertising (on barriers, not floating) ─────────────────────────────

func _build_ad_boards() -> void:
	var board_h := 0.75
	var board_y := 0.55
	var z_pos := FIELD_HZ + RUNOFF * 0.22
	var x_pos := FIELD_HX + RUNOFF * 0.22
	var seg := 3.8

	var n_x := int((FIELD_HX * 2.0) / seg)
	for i in n_x:
		var x: float = -FIELD_HX + seg * 0.5 + float(i) * seg
		var col: Color = AD_COLORS[i % AD_COLORS.size()]
		_add_led(Vector3(x, board_y,  z_pos), Vector3(seg - 0.15, board_h, 0.08), col)
		_add_led(Vector3(x, board_y, -z_pos), Vector3(seg - 0.15, board_h, 0.08), col)

	var n_z := int((FIELD_HZ * 2.0) / seg)
	for i in n_z:
		var z := -FIELD_HZ + seg * 0.5 + i * seg
		var col2: Color = AD_COLORS[(i + 2) % AD_COLORS.size()]
		_add_led(Vector3( x_pos, board_y, z), Vector3(0.08, board_h, seg - 0.15), col2)
		_add_led(Vector3(-x_pos, board_y, z), Vector3(0.08, board_h, seg - 0.15), col2)


func _add_led(pos: Vector3, size: Vector3, color: Color) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/led_ad.gdshader")
	mat.set_shader_parameter("base_color", color)
	_add_mesh_box(pos, size, mat)


# ── Crowd ─────────────────────────────────────────────────────────────────────

func _spawn_crowd(count: int, origin: Vector3, step: Vector3, palette: Array) -> void:
	var start := origin - step * (count * 0.5)
	var jitter_axis := Vector3(step.z, 0.0, step.x).normalized()
	var slots: Array[Vector3] = []

	for i in count:
		if i % AISLE_EVERY == AISLE_EVERY - 1:
			continue
		var base := start + step * i
		base += jitter_axis * _rng.randf_range(-0.08, 0.08)
		base.y += _rng.randf_range(-0.04, 0.04)
		slots.append(base)

	if slots.is_empty():
		return

	var bodies := _make_crowd_mm(slots.size(), _crowd_body_mesh)
	var heads := _make_crowd_mm(slots.size(), _crowd_head_mesh)

	for i in slots.size():
		var base: Vector3 = slots[i]
		var h := _rng.randf_range(0.92, 1.10)
		var phase := _rng.randf()
		var shirt: Color = palette[_rng.randi() % palette.size()]
		var skin: Color = SKIN_TONES[_rng.randi() % SKIN_TONES.size()]
		var body_basis := Basis().scaled(Vector3(1.0, h, 1.0))
		bodies.set_instance_transform(i, Transform3D(body_basis, base + Vector3(0.0, 0.22 * h, 0.0)))
		bodies.set_instance_color(i, shirt)
		bodies.set_instance_custom_data(i, Color(phase, 0.0, 0.0, 0.0))
		heads.set_instance_transform(i, Transform3D(Basis(), base + Vector3(0.0, 0.55 * h, 0.0)))
		heads.set_instance_color(i, skin)
		heads.set_instance_custom_data(i, Color(phase, 0.0, 0.0, 0.0))

	_add_crowd_instance(bodies)
	_add_crowd_instance(heads)


func _make_crowd_mm(count: int, mesh: Mesh) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = count
	return mm


func _add_crowd_instance(mm: MultiMesh) -> void:
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _crowd_mat
	add_child(mmi)


# ── Corner flags ──────────────────────────────────────────────────────────────

func _build_corner_flags() -> void:
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.92, 0.92, 0.94)
	pole_mat.metallic = 0.5
	pole_mat.roughness = 0.35
	var flag_mat := StandardMaterial3D.new()
	flag_mat.albedo_color = Color(0.95, 0.82, 0.05)
	flag_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var corner := Vector3(sx * FIELD_HX, 0.0, sz * FIELD_HZ)
			var pole := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.02
			pm.bottom_radius = 0.02
			pm.height = 1.5
			pole.mesh = pm
			pole.set_surface_override_material(0, pole_mat)
			pole.position = corner + Vector3(0.0, 0.75, 0.0)
			add_child(pole)
			var flag := MeshInstance3D.new()
			var fm := BoxMesh.new()
			fm.size = Vector3(0.45, 0.30, 0.015)
			flag.mesh = fm
			flag.set_surface_override_material(0, flag_mat)
			flag.position = corner + Vector3(-sx * 0.24, 1.28, 0.0)
			add_child(flag)


# ── Light towers (behind stands) ────────────────────────────────────────────

func _build_light_towers() -> void:
	var back := _stand_start(FIELD_HX) + ROWS * ROW_DEPTH + 4.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_build_tower(Vector3(sx * back, 0.0, sz * (FIELD_HZ + 6.0)))


func _build_tower(base: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.16
	pm.bottom_radius = 0.42
	pm.height = 22.0
	pole.mesh = pm
	pole.set_surface_override_material(0, _pole_mat)
	pole.position = Vector3(base.x, 11.0, base.z)
	add_child(pole)

	var panel_mat := ShaderMaterial.new()
	panel_mat.shader = load("res://shaders/led_ad.gdshader")
	panel_mat.set_shader_parameter("base_color", Color(1.0, 0.97, 0.88))
	panel_mat.set_shader_parameter("glow", 3.5)
	_add_mesh_box(Vector3(base.x, 22.0, base.z), Vector3(3.8, 1.4, 0.35), panel_mat)

	var light := SpotLight3D.new()
	light.light_color = Color(1.0, 0.97, 0.88)
	light.light_energy = 3.5
	light.spot_range = 110.0
	light.spot_angle = 48.0
	light.position = Vector3(base.x, 22.0, base.z)
	add_child(light)
	light.look_at(Vector3(0.0, 0.0, 0.0))


# ── Mesh helpers ──────────────────────────────────────────────────────────────

func _add_mesh_box(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
