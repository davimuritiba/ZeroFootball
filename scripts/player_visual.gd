extends Node3D

## Builds a more detailed humanoid figure from Godot primitives.
## Attach to a child Node3D of CharacterBody3D named "Visual".

@export var jersey_color : Color = Color(0.80, 0.08, 0.12)
@export var shorts_color : Color = Color(0.12, 0.12, 0.22)
@export var skin_color   : Color = Color(0.88, 0.70, 0.54)
@export var sock_color   : Color = Color(0.90, 0.90, 0.92)
@export var shoe_color   : Color = Color(0.08, 0.08, 0.08)
@export var hair_color   : Color = Color(0.18, 0.12, 0.07)


func _ready() -> void:
	_build()


func set_facing(angle_y: float) -> void:
	rotation.y = angle_y


# ── Build ─────────────────────────────────────────────────────────────────────

func _build() -> void:
	var jersey := _mat(jersey_color)
	var shorts  := _mat(shorts_color)
	var skin    := _mat(skin_color, 0.6)
	var sock    := _mat(sock_color)
	var shoe    := _mat(shoe_color, 0.45)
	var hair    := _mat(hair_color, 0.85)

	# Head + hair cap
	_sphere(Vector3(0.0, 1.66, 0.0), 0.16, skin)
	_squashed_sphere(Vector3(0.0, 1.71, -0.02), 0.165, 0.7, hair)
	# Nose hint for facing readability
	_box(Vector3(0.0, 1.65, 0.15), Vector3(0.05, 0.06, 0.05), skin)

	# Neck
	_capsule(Vector3(0.0, 1.50, 0.0), 0.06, 0.10, Vector3.ZERO, skin)

	# Shoulders (rounded)
	_sphere(Vector3(-0.22, 1.34, 0.0), 0.12, jersey)
	_sphere(Vector3( 0.22, 1.34, 0.0), 0.12, jersey)

	# Torso — tapered: chest + waist
	_box(Vector3(0.0, 1.16, 0.0), Vector3(0.42, 0.34, 0.22), jersey)
	_box(Vector3(0.0, 0.92, 0.0), Vector3(0.36, 0.20, 0.20), jersey)

	# Hips / shorts
	_box(Vector3(0.0, 0.74, 0.0), Vector3(0.40, 0.22, 0.21), shorts)

	# Arms — upper sleeves
	_capsule(Vector3(-0.28, 1.16, 0.0), 0.075, 0.30, Vector3(0.0, 0.0,  deg_to_rad(14.0)), jersey)
	_capsule(Vector3( 0.28, 1.16, 0.0), 0.075, 0.30, Vector3(0.0, 0.0, -deg_to_rad(14.0)), jersey)
	# Forearms
	_capsule(Vector3(-0.33, 0.88, 0.0), 0.06, 0.28, Vector3(0.0, 0.0,  deg_to_rad(7.0)), skin)
	_capsule(Vector3( 0.33, 0.88, 0.0), 0.06, 0.28, Vector3(0.0, 0.0, -deg_to_rad(7.0)), skin)
	# Hands
	_sphere(Vector3(-0.35, 0.72, 0.0), 0.07, skin)
	_sphere(Vector3( 0.35, 0.72, 0.0), 0.07, skin)

	# Legs — thighs
	_capsule(Vector3(-0.11, 0.46, 0.0), 0.092, 0.36, Vector3.ZERO, shorts)
	_capsule(Vector3( 0.11, 0.46, 0.0), 0.092, 0.36, Vector3.ZERO, shorts)
	# Knees
	_sphere(Vector3(-0.11, 0.30, 0.0), 0.08, skin)
	_sphere(Vector3( 0.11, 0.30, 0.0), 0.08, skin)
	# Shins (socks)
	_capsule(Vector3(-0.11, 0.14, 0.0), 0.078, 0.28, Vector3.ZERO, sock)
	_capsule(Vector3( 0.11, 0.14, 0.0), 0.078, 0.28, Vector3.ZERO, sock)

	# Feet (boots)
	_box(Vector3(-0.11, 0.035, 0.08), Vector3(0.10, 0.07, 0.24), shoe)
	_box(Vector3( 0.11, 0.035, 0.08), Vector3(0.10, 0.07, 0.24), shoe)


# ── Primitive helpers ─────────────────────────────────────────────────────────

func _mat(color: Color, roughness: float = 0.82) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness    = roughness
	return m


func _sphere(pos: Vector3, radius: float, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh   = sm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)


func _squashed_sphere(pos: Vector3, radius: float, y_scale: float, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh   = sm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.scale = Vector3(1.0, y_scale, 1.0)
	add_child(mi)


func _box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size  = size
	mi.mesh  = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)


func _capsule(pos: Vector3, radius: float, height: float,
		rot: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = height
	cm.radial_segments = 12
	mi.mesh     = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation = rot
	add_child(mi)
