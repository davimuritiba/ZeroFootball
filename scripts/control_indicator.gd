extends Node3D

## Floating ring above the controlled player.

const HEIGHT := 2.15
const PULSE_SPEED := 3.5

var _ring: MeshInstance3D
var _arrow: MeshInstance3D
var _phase: float = 0.0


func _ready() -> void:
	_build()
	visible = false


func set_active(active: bool) -> void:
	visible = active
	if active:
		_phase = 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	_phase += delta * PULSE_SPEED
	var pulse := 1.0 + sin(_phase * 2.0) * 0.07
	scale = Vector3(pulse, 1.0, pulse)
	position.y = HEIGHT + sin(_phase) * 0.06
	rotation.y += delta * 1.8


func _build() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.92, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.1)
	mat.emission_energy_multiplier = 2.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.92
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.28
	torus.outer_radius = 0.38
	torus.rings = 16
	torus.ring_segments = 24
	_ring.mesh = torus
	_ring.set_surface_override_material(0, mat)
	_ring.rotation.x = deg_to_rad(90.0)
	add_child(_ring)

	_arrow = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.14
	cone.height = 0.22
	cone.radial_segments = 12
	_arrow.mesh = cone
	_arrow.set_surface_override_material(0, mat)
	_arrow.position = Vector3(0.0, 0.35, 0.0)
	_arrow.rotation.x = PI
	add_child(_arrow)
