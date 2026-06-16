extends Node3D

## Distant sky backdrop: terrain ring, hills, city skyline, trees and clouds.

const FIELD_HX := 25.0
const FIELD_HZ := 15.0

var _rng := RandomNumberGenerator.new()
var _grass_mat: StandardMaterial3D
var _hill_mat: StandardMaterial3D
var _dirt_mat: StandardMaterial3D
var _city_mat: StandardMaterial3D
var _tree_trunk_mat: StandardMaterial3D
var _tree_leaf_mat: StandardMaterial3D
var _cloud_mat: ShaderMaterial


func _ready() -> void:
	_rng.randomize()
	_setup_materials()
	_build_ground()
	_build_hills()
	_build_city_skyline()
	_build_trees()
	_build_clouds()
	_build_distant_mountains()


func _setup_materials() -> void:
	_grass_mat = StandardMaterial3D.new()
	_grass_mat.albedo_color = Color(0.16, 0.42, 0.18)
	_grass_mat.roughness = 0.95

	_hill_mat = StandardMaterial3D.new()
	_hill_mat.albedo_color = Color(0.22, 0.48, 0.20)
	_hill_mat.roughness = 0.92

	_dirt_mat = StandardMaterial3D.new()
	_dirt_mat.albedo_color = Color(0.36, 0.30, 0.22)
	_dirt_mat.roughness = 0.98

	_city_mat = StandardMaterial3D.new()
	_city_mat.albedo_color = Color(0.38, 0.40, 0.46)
	_city_mat.roughness = 0.85
	_city_mat.metallic = 0.15

	_tree_trunk_mat = StandardMaterial3D.new()
	_tree_trunk_mat.albedo_color = Color(0.32, 0.22, 0.14)
	_tree_trunk_mat.roughness = 0.9

	_tree_leaf_mat = StandardMaterial3D.new()
	_tree_leaf_mat.albedo_color = Color(0.12, 0.38, 0.14)
	_tree_leaf_mat.roughness = 0.88

	_cloud_mat = ShaderMaterial.new()
	_cloud_mat.shader = load("res://shaders/cloud.gdshader")
	_cloud_mat.set_shader_parameter("cloud_color", Color(1.0, 1.0, 1.0, 0.82))


func _build_ground() -> void:
	# Wide terrain pad surrounding the stadium
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(320.0, 320.0)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	mi.mesh = plane
	mi.set_surface_override_material(0, _grass_mat)
	mi.position = Vector3(0.0, -0.35, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

	# Dirt paths beyond stadium
	for angle_deg in range(0, 360, 45):
		var a := deg_to_rad(float(angle_deg))
		var dist := 55.0
		_add_box(
			Vector3(cos(a) * dist, -0.28, sin(a) * dist),
			Vector3(8.0, 0.06, 28.0),
			_dirt_mat,
			Vector3(0.0, a, 0.0),
			false
		)


func _build_hills() -> void:
	var hill_positions := [
		Vector3(-70.0, 0.0, -55.0), Vector3(75.0, 0.0, -48.0),
		Vector3(-82.0, 0.0, 40.0), Vector3(68.0, 0.0, 58.0),
		Vector3(-45.0, 0.0, 72.0), Vector3(50.0, 0.0, -70.0),
	]
	for pos in hill_positions:
		var h := _rng.randf_range(6.0, 14.0)
		var w := _rng.randf_range(22.0, 38.0)
		var d := _rng.randf_range(18.0, 32.0)
		_add_box(pos + Vector3(0.0, h * 0.5 - 0.3, 0.0), Vector3(w, h, d), _hill_mat, Vector3.ZERO, false)
		# Secondary mound
		_add_box(
			pos + Vector3(_rng.randf_range(-8.0, 8.0), h * 0.35, _rng.randf_range(-6.0, 6.0)),
			Vector3(w * 0.55, h * 0.45, d * 0.5), _hill_mat, Vector3.ZERO, false
		)


func _build_distant_mountains() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.52, 0.62)
	mat.roughness = 1.0
	for side: float in [-1.0, 1.0]:
		for i in 4:
			var x: float = side * (90.0 + float(i) * 18.0) + _rng.randf_range(-12.0, 12.0)
			var z: float = _rng.randf_range(-60.0, 60.0)
			var h: float = _rng.randf_range(18.0, 35.0)
			_add_box(Vector3(x, h * 0.5, z), Vector3(40.0, h, 25.0), mat, Vector3.ZERO, false)


func _build_city_skyline() -> void:
	# City visible beyond the north stand (positive Z side in world)
	var base_z := 58.0
	var buildings := 22
	for i in buildings:
		var x: float = -95.0 + float(i) * (190.0 / float(buildings))
		var w := _rng.randf_range(4.0, 9.0)
		var h := _rng.randf_range(12.0, 42.0)
		var d := _rng.randf_range(4.0, 7.0)
		_add_box(Vector3(x, h * 0.5, base_z + _rng.randf_range(-4.0, 4.0)),
			Vector3(w, h, d), _city_mat, Vector3.ZERO, false)
		# Random lit windows strip
		if _rng.randf() > 0.5:
			var win_mat := StandardMaterial3D.new()
			win_mat.albedo_color = Color(0.9, 0.85, 0.55)
			win_mat.emission_enabled = true
			win_mat.emission = Color(1.0, 0.9, 0.6)
			win_mat.emission_energy_multiplier = 0.8
			_add_box(Vector3(x, h * 0.55, base_z + d * 0.5 + 0.5),
				Vector3(w * 0.7, h * 0.35, 0.15), win_mat, Vector3.ZERO, false)

	# Second row taller background
	for i in 10:
		var x2: float = -80.0 + float(i) * 17.0
		var h2 := _rng.randf_range(25.0, 55.0)
		_add_box(Vector3(x2, h2 * 0.5, base_z + 12.0), Vector3(7.0, h2, 5.0), _city_mat, Vector3.ZERO, false)


func _build_trees() -> void:
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.12
	trunk_mesh.bottom_radius = 0.18
	trunk_mesh.height = 1.4
	var leaf_mesh := CylinderMesh.new()
	leaf_mesh.top_radius = 0.0
	leaf_mesh.bottom_radius = 1.1
	leaf_mesh.height = 2.4

	for _n in 120:
		var angle := _rng.randf() * TAU
		var dist := _rng.randf_range(48.0, 95.0)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		# Skip if inside stadium footprint
		if absf(pos.x) < FIELD_HX + 20.0 and absf(pos.z) < FIELD_HZ + 20.0:
			continue
		var scale_h := _rng.randf_range(0.8, 1.3)
		_add_tree(pos, trunk_mesh, leaf_mesh, scale_h)


func _add_tree(pos: Vector3, trunk_mesh: CylinderMesh, leaf_mesh: CylinderMesh, scale_h: float) -> void:
	var trunk := MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.set_surface_override_material(0, _tree_trunk_mat)
	trunk.position = pos + Vector3(0.0, 0.7 * scale_h, 0.0)
	trunk.scale = Vector3(scale_h, scale_h, scale_h)
	trunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trunk)

	var leaves := MeshInstance3D.new()
	leaves.mesh = leaf_mesh
	leaves.set_surface_override_material(0, _tree_leaf_mat)
	leaves.position = pos + Vector3(0.0, 2.2 * scale_h, 0.0)
	leaves.scale = Vector3(scale_h, scale_h, scale_h)
	leaves.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(leaves)


func _build_clouds() -> void:
	var cloud_mesh := SphereMesh.new()
	cloud_mesh.radius = 1.0
	cloud_mesh.height = 2.0
	cloud_mesh.radial_segments = 16
	cloud_mesh.rings = 8

	var cloud_positions := [
		Vector3(-40.0, 55.0, -30.0), Vector3(30.0, 62.0, -50.0),
		Vector3(60.0, 48.0, 20.0), Vector3(-55.0, 58.0, 35.0),
		Vector3(0.0, 70.0, -60.0), Vector3(80.0, 52.0, -10.0),
		Vector3(-75.0, 45.0, -15.0), Vector3(15.0, 65.0, 45.0),
	]
	for base in cloud_positions:
		for puff in 4:
			var mi := MeshInstance3D.new()
			mi.mesh = cloud_mesh
			mi.material_override = _cloud_mat
			var offset := Vector3(
				_rng.randf_range(-6.0, 6.0),
				_rng.randf_range(-1.5, 1.5),
				_rng.randf_range(-3.0, 3.0)
			)
			var s := _rng.randf_range(5.0, 11.0)
			mi.position = base + offset
			mi.scale = Vector3(s * 1.4, s * 0.45, s)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)


func _add_box(pos: Vector3, size: Vector3, mat: Material,
		rot: Vector3 = Vector3.ZERO, cast_shadow: bool = true) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
