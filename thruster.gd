class_name Thruster
extends ShipModule

@export var throttle: float = 1.0
@export var max_thrust: float = 100.0
@export var consumption: float = 0.05
@export var effect: Node3D
@export var enable: bool = true

func _ready() -> void:
	if effect:
		effect.visible = false


func ignite(level: float = 1.0) -> Transform3D:
	if not enable:
		return Transform3D.IDENTITY
		
	var actual_level := clampf(level, 0.0, 1.0) * clampf(throttle, 0.0, 1.0)
	if actual_level <= 0.0:
		off()
		return Transform3D.IDENTITY

	if effect:
		effect.visible = true
		effect.scale.y = actual_level
		effect.position.y = 0.15 + (0.5 * actual_level)

	var current_thrust := max_thrust * actual_level
	# Returns transform with thruster local position and thrust-scaled basis
	return Transform3D(transform.basis * current_thrust, transform.origin)


func off() -> void:
	if effect:
		effect.visible = false


func get_local_thrust_direction() -> Vector3:
	return -transform.basis.y.normalized()


