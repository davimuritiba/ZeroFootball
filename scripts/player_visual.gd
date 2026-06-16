extends Node3D

## Procedural humanoid rig with walk, run, idle and kick animations.

@export var jersey_color : Color = Color(0.80, 0.08, 0.12)
@export var shorts_color : Color = Color(0.12, 0.12, 0.22)
@export var skin_color   : Color = Color(0.88, 0.70, 0.54)
@export var sock_color   : Color = Color(0.90, 0.90, 0.92)
@export var shoe_color   : Color = Color(0.08, 0.08, 0.08)
@export var hair_color   : Color = Color(0.18, 0.12, 0.07)

# Animation
var _phase: float = 0.0
var _kick_t: float = -1.0
var _move_speed: float = 0.0
var _rng_phase: float = 0.0

# Rig pivots
var _hips: Node3D
var _spine: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _fore_l: Node3D
var _fore_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _shin_l: Node3D
var _shin_r: Node3D
var _foot_l: Node3D
var _foot_r: Node3D


func _ready() -> void:
	_rng_phase = randf() * TAU
	_build_rig()


func configure(p_jersey: Color, p_shorts: Color) -> void:
	jersey_color = p_jersey
	shorts_color = p_shorts
	_clear()
	_build_rig()


func set_facing(angle_y: float) -> void:
	rotation.y = angle_y


func set_move_speed(speed: float) -> void:
	_move_speed = speed


func play_kick() -> void:
	_kick_t = 0.0


func update_animation(delta: float) -> void:
	if _kick_t >= 0.0:
		_kick_t += delta
		_animate_kick(_kick_t)
		if _kick_t > 0.45:
			_kick_t = -1.0
		return

	if _move_speed > 0.15:
		var freq := lerpf(6.5, 11.0, clampf(_move_speed / 7.0, 0.0, 1.0))
		_phase += delta * freq
		_animate_locomotion()
	else:
		_phase = lerpf(_phase, 0.0, delta * 4.0)
		_animate_idle(delta)


# ── Animation ─────────────────────────────────────────────────────────────────

func _animate_idle(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001 + _rng_phase
	var breath := sin(t * 2.0) * 0.02
	_reset_limbs()
	_spine.rotation.x = breath
	_head.rotation.x = -breath * 0.3
	_arm_l.rotation.x = deg_to_rad(8.0)
	_arm_r.rotation.x = deg_to_rad(8.0)


func _animate_locomotion() -> void:
	var s := sin(_phase)
	var c := cos(_phase)
	var run_blend := clampf((_move_speed - 3.5) / 3.5, 0.0, 1.0)
	var stride := lerpf(0.55, 0.85, run_blend)
	var arm_swing := lerpf(0.45, 0.75, run_blend)

	_leg_l.rotation.x = s * stride
	_leg_r.rotation.x = -s * stride
	_shin_l.rotation.x = maxf(0.0, -s) * lerpf(0.5, 0.9, run_blend)
	_shin_r.rotation.x = maxf(0.0, s) * lerpf(0.5, 0.9, run_blend)
	_foot_l.rotation.x = maxf(0.0, s) * 0.25
	_foot_r.rotation.x = maxf(0.0, -s) * 0.25

	_arm_l.rotation.x = -s * arm_swing
	_arm_r.rotation.x = s * arm_swing
	_fore_l.rotation.x = absf(s) * 0.35
	_fore_r.rotation.x = absf(-s) * 0.35

	_spine.rotation.x = absf(c) * 0.06
	_hips.position.y = 0.88 + absf(c) * 0.04


func _animate_kick(t: float) -> void:
	_reset_limbs()
	var norm := t / 0.45
	if norm < 0.35:
		# Wind-up: pull leg back
		var p := norm / 0.35
		_leg_r.rotation.x = -lerpf(0.0, 1.1, p)
		_shin_r.rotation.x = lerpf(0.0, 1.4, p)
		_spine.rotation.x = -lerpf(0.0, 0.25, p)
		_arm_l.rotation.x = lerpf(0.0, -0.8, p)
		_arm_r.rotation.x = lerpf(0.0, 0.5, p)
	elif norm < 0.55:
		# Strike
		var p := (norm - 0.35) / 0.2
		_leg_r.rotation.x = lerpf(-1.1, 1.3, p)
		_shin_r.rotation.x = lerpf(1.4, 0.1, p)
		_foot_r.rotation.x = lerpf(0.0, 0.4, p)
		_spine.rotation.x = lerpf(-0.25, 0.15, p)
	else:
		# Follow-through
		var p := (norm - 0.55) / 0.45
		_leg_r.rotation.x = lerpf(1.3, 0.2, p)
		_shin_r.rotation.x = lerpf(0.1, 0.3, p)


func _reset_limbs() -> void:
	_hips.position.y = 0.88
	_spine.rotation = Vector3.ZERO
	_head.rotation = Vector3.ZERO
	_arm_l.rotation = Vector3.ZERO
	_arm_r.rotation = Vector3.ZERO
	_fore_l.rotation = Vector3.ZERO
	_fore_r.rotation = Vector3.ZERO
	_leg_l.rotation = Vector3.ZERO
	_leg_r.rotation = Vector3.ZERO
	_shin_l.rotation = Vector3.ZERO
	_shin_r.rotation = Vector3.ZERO
	_foot_l.rotation = Vector3.ZERO
	_foot_r.rotation = Vector3.ZERO


# ── Rig build ─────────────────────────────────────────────────────────────────

func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_hips = null


func _build_rig() -> void:
	var jersey := _mat(jersey_color, 0.78)
	var shorts := _mat(shorts_color, 0.82)
	var skin := _skin_mat(skin_color)
	var sock := _mat(sock_color, 0.8)
	var shoe := _mat(shoe_color, 0.42)
	var hair := _mat(hair_color, 0.88)

	_hips = _pivot("Hips", Vector3(0.0, 0.88, 0.0))
	_spine = _pivot("Spine", Vector3(0.0, 0.0, 0.0), _hips)

	# Torso
	_mesh_box(Vector3(0.0, 0.22, 0.0), Vector3(0.40, 0.38, 0.20), jersey, _spine)
	_mesh_box(Vector3(0.0, -0.06, 0.0), Vector3(0.36, 0.18, 0.19), jersey, _spine)
	_mesh_box(Vector3(0.0, -0.22, 0.0), Vector3(0.38, 0.20, 0.20), shorts, _spine)

	# Head
	_head = _pivot("Head", Vector3(0.0, 0.50, 0.0), _spine)
	_mesh_sphere(Vector3(0.0, 0.10, 0.0), 0.155, skin, _head, 20)
	_mesh_sphere(Vector3(0.0, 0.16, -0.02), 0.158, hair, _head, 16, Vector3(1.0, 0.65, 1.0))
	_mesh_box(Vector3(0.0, 0.08, 0.14), Vector3(0.04, 0.05, 0.05), skin, _head)

	# Shoulders
	_mesh_sphere(Vector3(-0.20, 0.38, 0.0), 0.10, jersey, _spine)
	_mesh_sphere(Vector3(0.20, 0.38, 0.0), 0.10, jersey, _spine)

	# Left arm
	_arm_l = _pivot("ArmL", Vector3(-0.22, 0.36, 0.0), _spine)
	_mesh_capsule(Vector3(0.0, -0.14, 0.0), 0.065, 0.26, jersey, _arm_l)
	_fore_l = _pivot("ForeL", Vector3(0.0, -0.28, 0.0), _arm_l)
	_mesh_capsule(Vector3(0.0, -0.12, 0.0), 0.055, 0.22, skin, _fore_l)
	_mesh_sphere(Vector3(0.0, -0.26, 0.0), 0.06, skin, _fore_l)

	# Right arm (kicking side)
	_arm_r = _pivot("ArmR", Vector3(0.22, 0.36, 0.0), _spine)
	_mesh_capsule(Vector3(0.0, -0.14, 0.0), 0.065, 0.26, jersey, _arm_r)
	_fore_r = _pivot("ForeR", Vector3(0.0, -0.28, 0.0), _arm_r)
	_mesh_capsule(Vector3(0.0, -0.12, 0.0), 0.055, 0.22, skin, _fore_r)
	_mesh_sphere(Vector3(0.0, -0.26, 0.0), 0.06, skin, _fore_r)

	# Left leg
	_leg_l = _pivot("LegL", Vector3(-0.10, -0.32, 0.0), _spine)
	_mesh_capsule(Vector3(0.0, -0.16, 0.0), 0.085, 0.30, shorts, _leg_l)
	_shin_l = _pivot("ShinL", Vector3(0.0, -0.32, 0.0), _leg_l)
	_mesh_capsule(Vector3(0.0, -0.13, 0.0), 0.072, 0.24, sock, _shin_l)
	_foot_l = _pivot("FootL", Vector3(0.0, -0.26, 0.04), _shin_l)
	_mesh_box(Vector3(0.0, -0.02, 0.06), Vector3(0.09, 0.06, 0.22), shoe, _foot_l)

	# Right leg
	_leg_r = _pivot("LegR", Vector3(0.10, -0.32, 0.0), _spine)
	_mesh_capsule(Vector3(0.0, -0.16, 0.0), 0.085, 0.30, shorts, _leg_r)
	_shin_r = _pivot("ShinR", Vector3(0.0, -0.32, 0.0), _leg_r)
	_mesh_capsule(Vector3(0.0, -0.13, 0.0), 0.072, 0.24, sock, _shin_r)
	_foot_r = _pivot("FootR", Vector3(0.0, -0.26, 0.04), _shin_r)
	_mesh_box(Vector3(0.0, -0.02, 0.06), Vector3(0.09, 0.06, 0.22), shoe, _foot_r)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _pivot(name: String, pos: Vector3, parent: Node = self) -> Node3D:
	var n := Node3D.new()
	n.name = name
	n.position = pos
	parent.add_child(n)
	return n


func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


func _skin_mat(color: Color) -> StandardMaterial3D:
	var m := _mat(color, 0.58)
	m.rim_enabled = true
	m.rim = 0.1
	m.rim_tint = 0.55
	return m


func _mesh_sphere(pos: Vector3, radius: float, mat: Material, parent: Node,
		segs: int = 16, scale: Vector3 = Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = segs
	sm.rings = maxi(segs / 2, 4)
	mi.mesh = sm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.scale = scale
	parent.add_child(mi)


func _mesh_box(pos: Vector3, size: Vector3, mat: Material, parent: Node) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)


func _mesh_capsule(pos: Vector3, radius: float, height: float, mat: Material, parent: Node) -> void:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = height
	cm.radial_segments = 14
	mi.mesh = cm
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
