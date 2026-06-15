extends Node3D

# Field dimensions (must match pitch.tscn)
const FIELD_HX := 25.0
const FIELD_HZ := 15.0

# Stand geometry
const ROWS         := 7
const ROW_DEPTH    := 1.3
const ROW_HEIGHT   := 0.85
const STAND_GAP    := 2.4    # gap between field edge and first row
const SEAT_SPACING := 0.95

var _rng := RandomNumberGenerator.new()
var _concrete_mat: StandardMaterial3D
var _seat_mat: StandardMaterial3D
var _wall_mat: StandardMaterial3D
var _roof_mat: StandardMaterial3D
var _pole_mat: StandardMaterial3D
var _crowd_body_mesh: CapsuleMesh
var _crowd_head_mesh: SphereMesh
var _crowd_mat: ShaderMaterial

# Realistic skin tones for spectator heads
const SKIN_TONES := [
	Color(0.96, 0.81, 0.68),
	Color(0.90, 0.72, 0.56),
	Color(0.80, 0.62, 0.46),
	Color(0.64, 0.47, 0.33),
	Color(0.45, 0.31, 0.22),
	Color(0.34, 0.23, 0.16),
]

const PALETTE_HOME := [
	Color(0.78, 0.06, 0.07),
	Color(0.90, 0.16, 0.10),
	Color(0.86, 0.78, 0.10),
	Color(0.95, 0.95, 0.95),
]
const PALETTE_AWAY := [
	Color(0.08, 0.18, 0.74),
	Color(0.16, 0.42, 0.86),
	Color(0.88, 0.88, 0.92),
	Color(0.10, 0.12, 0.20),
]
const PALETTE_MIX := [
	Color(0.74, 0.07, 0.08),
	Color(0.10, 0.18, 0.72),
	Color(0.84, 0.80, 0.10),
	Color(0.70, 0.70, 0.72),
	Color(0.95, 0.95, 0.95),
	Color(0.16, 0.66, 0.22),
]

# Advertising board colours (emissive LED look)
const AD_COLORS := [
	Color(0.90, 0.10, 0.10),
	Color(0.10, 0.35, 0.95),
	Color(0.95, 0.75, 0.05),
	Color(0.05, 0.70, 0.35),
	Color(0.95, 0.95, 0.95),
	Color(0.85, 0.20, 0.70),
]


func _ready() -> void:
	_rng.randomize()
	_setup_materials()
	_build_long_side( 1.0, PALETTE_HOME)   # south touchline (front stand)
	_build_long_side(-1.0, PALETTE_AWAY)   # north touchline
	_build_short_side( 1.0, PALETTE_MIX)   # east goal line
	_build_short_side(-1.0, PALETTE_MIX)   # west goal line
	_build_ad_boards()
	_build_corner_flags()
	_build_light_towers()


func _setup_materials() -> void:
	_concrete_mat = StandardMaterial3D.new()
	_concrete_mat.albedo_color = Color(0.30, 0.30, 0.32)
	_concrete_mat.roughness = 0.94

	_seat_mat = StandardMaterial3D.new()
	_seat_mat.albedo_color = Color(0.16, 0.18, 0.22)
	_seat_mat.roughness = 0.7

	_wall_mat = StandardMaterial3D.new()
	_wall_mat.albedo_color = Color(0.22, 0.23, 0.26)
	_wall_mat.roughness = 0.9

	_roof_mat = StandardMaterial3D.new()
	_roof_mat.albedo_color = Color(0.14, 0.15, 0.17)
	_roof_mat.metallic = 0.4
	_roof_mat.roughness = 0.45

	_pole_mat = StandardMaterial3D.new()
	_pole_mat.albedo_color = Color(0.58, 0.58, 0.62)
	_pole_mat.metallic = 0.7
	_pole_mat.roughness = 0.3

	# Spectator body (seated torso) and head meshes — low-poly for performance
	_crowd_body_mesh = CapsuleMesh.new()
	_crowd_body_mesh.radius = 0.16
	_crowd_body_mesh.height = 0.5
	_crowd_body_mesh.radial_segments = 6
	_crowd_body_mesh.rings = 2

	_crowd_head_mesh = SphereMesh.new()
	_crowd_head_mesh.radius = 0.12
	_crowd_head_mesh.height = 0.24
	_crowd_head_mesh.radial_segments = 8
	_crowd_head_mesh.rings = 4

	_crowd_mat = ShaderMaterial.new()
	_crowd_mat.shader = load("res://shaders/crowd.gdshader")


# ── Long stands (south / north) ───────────────────────────────────────────────

func _build_long_side(side: float, palette: Array) -> void:
	var stand_len := FIELD_HX * 2.0 + 10.0
	var seat_count := int(stand_len / SEAT_SPACING)
	var first := FIELD_HZ + STAND_GAP

	for row in ROWS:
		var z := side * (first + row * ROW_DEPTH)
		var y := row * ROW_HEIGHT

		# concrete step
		_add_box(Vector3(0.0, y + ROW_HEIGHT * 0.5, z),
				 Vector3(stand_len, ROW_HEIGHT, ROW_DEPTH), _concrete_mat)
		# seat strip (slightly behind, on top of the step)
		_add_box(Vector3(0.0, y + ROW_HEIGHT + 0.05, z + side * 0.45),
				 Vector3(stand_len, 0.34, 0.42), _seat_mat)

		var origin := Vector3(0.0, y + ROW_HEIGHT + 0.5, z)
		_spawn_crowd(seat_count, origin, Vector3(SEAT_SPACING, 0.0, 0.0), palette)

	# back wall + roof
	var back_z := side * (first + ROWS * ROW_DEPTH)
	var top_y := ROWS * ROW_HEIGHT
	_add_box(Vector3(0.0, top_y * 0.5, back_z + side * 0.8),
			 Vector3(stand_len, top_y + 1.0, 0.5), _wall_mat)
	_add_box(Vector3(0.0, top_y + 2.6, back_z - side * 2.0),
			 Vector3(stand_len, 0.3, ROWS * ROW_DEPTH + 3.0), _roof_mat)
	# roof support pillars
	for px in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		var sx: float = px * (stand_len * 0.45)
		_add_box(Vector3(sx, top_y + 1.3, back_z + side * 0.6),
				 Vector3(0.3, 2.6, 0.3), _pole_mat)


# ── Short stands (east / west, behind goals) ──────────────────────────────────

func _build_short_side(side: float, palette: Array) -> void:
	var depth_each_long := STAND_GAP + ROWS * ROW_DEPTH
	var stand_len := FIELD_HZ * 2.0 + depth_each_long * 2.0 + 4.0
	var seat_count := int(stand_len / SEAT_SPACING)
	var first := FIELD_HX + STAND_GAP

	for row in ROWS:
		var x := side * (first + row * ROW_DEPTH)
		var y := row * ROW_HEIGHT

		_add_box(Vector3(x, y + ROW_HEIGHT * 0.5, 0.0),
				 Vector3(ROW_DEPTH, ROW_HEIGHT, stand_len), _concrete_mat)
		_add_box(Vector3(x + side * 0.45, y + ROW_HEIGHT + 0.05, 0.0),
				 Vector3(0.42, 0.34, stand_len), _seat_mat)

		var origin := Vector3(x, y + ROW_HEIGHT + 0.5, 0.0)
		_spawn_crowd(seat_count, origin, Vector3(0.0, 0.0, SEAT_SPACING), palette)

	var back_x := side * (first + ROWS * ROW_DEPTH)
	var top_y := ROWS * ROW_HEIGHT
	_add_box(Vector3(back_x + side * 0.8, top_y * 0.5, 0.0),
			 Vector3(0.5, top_y + 1.0, stand_len), _wall_mat)
	_add_box(Vector3(back_x - side * 2.0, top_y + 2.6, 0.0),
			 Vector3(ROWS * ROW_DEPTH + 3.0, 0.3, stand_len), _roof_mat)


# ── Perimeter advertising boards ──────────────────────────────────────────────

func _build_ad_boards() -> void:
	var board_h := 0.9
	var board_y := 0.45
	# long sides (run along X), placed just outside the touchlines
	var seg_x := 4.0
	var n_x := int((FIELD_HX * 2.0) / seg_x)
	for i in n_x:
		var x := -FIELD_HX + seg_x * 0.5 + i * seg_x
		var col: Color = AD_COLORS[i % AD_COLORS.size()]
		_add_ad(Vector3(x, board_y, FIELD_HZ + 0.6), Vector3(seg_x - 0.2, board_h, 0.12), col)
		_add_ad(Vector3(x, board_y, -(FIELD_HZ + 0.6)), Vector3(seg_x - 0.2, board_h, 0.12), col)

	# short sides (run along Z), behind goals
	var seg_z := 3.5
	var n_z := int((FIELD_HZ * 2.0) / seg_z)
	for i in n_z:
		var z := -FIELD_HZ + seg_z * 0.5 + i * seg_z
		var col2: Color = AD_COLORS[(i + 2) % AD_COLORS.size()]
		_add_ad(Vector3(FIELD_HX + 0.6, board_y, z), Vector3(0.12, board_h, seg_z - 0.2), col2)
		_add_ad(Vector3(-(FIELD_HX + 0.6), board_y, z), Vector3(0.12, board_h, seg_z - 0.2), col2)


func _add_ad(pos: Vector3, size: Vector3, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	mat.roughness = 0.4
	_add_box(pos, size, mat)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _add_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)


func _spawn_crowd(count: int, origin: Vector3, step: Vector3, palette: Array) -> void:
	var bodies := _make_crowd_mm(count, _crowd_body_mesh)
	var heads  := _make_crowd_mm(count, _crowd_head_mesh)

	var start := origin - step * (count * 0.5)
	var jitter_axis := Vector3(step.z, 0.0, step.x).normalized()

	for i in count:
		var base := start + step * i
		base += jitter_axis * _rng.randf_range(-0.12, 0.12)
		base.y += _rng.randf_range(-0.05, 0.05)

		var h := _rng.randf_range(0.9, 1.12)
		var phase := _rng.randf()
		var shirt: Color = palette[_rng.randi() % palette.size()]
		var skin: Color = SKIN_TONES[_rng.randi() % SKIN_TONES.size()]

		# Body sits at the seat; head rests on top, scaled together
		var body_basis := Basis().scaled(Vector3(1.0, h, 1.0))
		var body_pos := base + Vector3(0.0, 0.25 * h, 0.0)
		bodies.set_instance_transform(i, Transform3D(body_basis, body_pos))
		bodies.set_instance_color(i, shirt)
		bodies.set_instance_custom_data(i, Color(phase, 0.0, 0.0, 0.0))

		var head_pos := base + Vector3(0.0, 0.6 * h, 0.0)
		heads.set_instance_transform(i, Transform3D(Basis(), head_pos))
		heads.set_instance_color(i, skin)
		heads.set_instance_custom_data(i, Color(phase, 0.0, 0.0, 0.0))

	_add_crowd_instance(bodies)
	_add_crowd_instance(heads)


func _make_crowd_mm(count: int, mesh: Mesh) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors       = true
	mm.use_custom_data  = true
	mm.mesh             = mesh
	mm.instance_count   = count
	return mm


func _add_crowd_instance(mm: MultiMesh) -> void:
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _crowd_mat
	add_child(mmi)


# ── Corner flags ──────────────────────────────────────────────────────────────

func _build_corner_flags() -> void:
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.9, 0.9, 0.9)
	pole_mat.roughness = 0.4

	var flag_mat := StandardMaterial3D.new()
	flag_mat.albedo_color = Color(0.95, 0.82, 0.05)
	flag_mat.roughness = 0.6
	flag_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	for sx in [1.0, -1.0]:
		for sz in [1.0, -1.0]:
			var corner := Vector3(sx * FIELD_HX, 0.0, sz * FIELD_HZ)

			var pole := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.025
			pm.bottom_radius = 0.025
			pm.height = 1.5
			pole.mesh = pm
			pole.set_surface_override_material(0, pole_mat)
			pole.position = corner + Vector3(0.0, 0.75, 0.0)
			add_child(pole)

			var flag := MeshInstance3D.new()
			var fm := BoxMesh.new()
			fm.size = Vector3(0.5, 0.32, 0.02)
			flag.mesh = fm
			flag.set_surface_override_material(0, flag_mat)
			flag.position = corner + Vector3(-sx * 0.27, 1.3, 0.0)
			add_child(flag)


# ── Light towers ──────────────────────────────────────────────────────────────

func _build_light_towers() -> void:
	var tx := FIELD_HX + 12.0
	var tz := FIELD_HZ + 12.0
	for sx in [1.0, -1.0]:
		for sz in [1.0, -1.0]:
			_build_tower(Vector3(sx * tx, 0.0, sz * tz))


func _build_tower(base: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var pm   := CylinderMesh.new()
	pm.top_radius    = 0.18
	pm.bottom_radius = 0.45
	pm.height        = 24.0
	pole.mesh = pm
	pole.set_surface_override_material(0, _pole_mat)
	pole.position = Vector3(base.x, 12.0, base.z)
	add_child(pole)

	# Lamp panel with emissive bulbs
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.9, 0.9, 0.85)
	panel_mat.emission_enabled = true
	panel_mat.emission = Color(1.0, 0.97, 0.85)
	panel_mat.emission_energy_multiplier = 3.0
	_add_box(Vector3(base.x, 24.0, base.z), Vector3(4.0, 1.6, 0.4), panel_mat)

	var light := SpotLight3D.new()
	light.light_color    = Color(1.0, 0.97, 0.88)
	light.light_energy   = 4.0
	light.spot_range     = 120.0
	light.spot_angle     = 45.0
	light.shadow_enabled = false
	light.position = Vector3(base.x, 24.0, base.z)
	add_child(light)
	light.look_at(Vector3(0.0, 0.0, 0.0))
