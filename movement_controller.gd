class_name MovementController
extends Node

signal mouse_steering_updated(is_steering: bool, offset: Vector2)

var _thrusters: Array[Thruster] = []
var _center_of_mass: Vector3 = Vector3.ZERO

var mouse_deadzone: float = 0.7


func add_thruster(thruster: Thruster) -> void:
	_thrusters.append(thruster)


func physics_process(_delta: float, body: RigidBody3D) -> void:
	var desired_direction := get_desired_direction()
	var desired_rotation := get_desired_rotation(body)

	var direction_normalized := desired_direction.normalized() if not desired_direction.is_zero_approx() else Vector3.ZERO
	var rotation_normalized := desired_rotation.normalized() if not desired_rotation.is_zero_approx() else Vector3.ZERO

	if direction_normalized.is_zero_approx() and rotation_normalized.is_zero_approx():
		for thruster in _thrusters:
			thruster.off()
		return

	var total_local_force := Vector3.ZERO
	var total_local_torque := Vector3.ZERO

	for thruster in _thrusters:
		var local_thrust_dir := thruster.get_local_thrust_direction()
		var local_lever_arm := thruster.transform.origin - _center_of_mass
		var local_torque := local_lever_arm.cross(local_thrust_dir)

		# 1. Linear translation alignment (WASD, forward/backward)
		var linear_activation := 0.0
		if not direction_normalized.is_zero_approx():
			var linear_alignment := local_thrust_dir.dot(direction_normalized)
			if linear_alignment > 0.1:
				linear_activation = linear_alignment * desired_direction.length()

		# 2. Rotational torque alignment (Roll Q/E, and mouse Pitch/Yaw)
		var angular_activation := 0.0
		if not rotation_normalized.is_zero_approx() and local_torque.length_squared() > 0.0001:
			var torque_alignment := local_torque.normalized().dot(rotation_normalized)
			if torque_alignment > 0.1:
				angular_activation = torque_alignment * desired_rotation.length()

		# Combined activation level
		var total_activation := clampf(linear_activation + angular_activation, 0.0, 1.0)

		if total_activation > 0.01:
			var t := thruster.ignite(total_activation)
			var force := -t.basis.y
			var pos := t.origin
			total_local_force += force
			total_local_torque += (pos - _center_of_mass).cross(force)
		else:
			thruster.off()

	if not total_local_force.is_zero_approx():
		body.apply_central_force(body.global_basis * total_local_force)
	if not total_local_torque.is_zero_approx():
		body.apply_torque(body.global_basis * total_local_torque)


func set_center_of_mass(com: Vector3) -> void:
	_center_of_mass = com


func get_desired_direction() -> Vector3:
	# Local ship movement axes:
	# A / D -> Move Left (-X) / Move Right (+X)
	# S / W -> Move Down (-Y) / Move Up (+Y)
	# Move Forward (-Z) / Move Backward (+Z)
	return Vector3(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_down", "move_up"),
		Input.get_axis("move_forward", "move_backward")
	)


func get_desired_rotation(body: RigidBody3D = null) -> Vector3:
	var pitch := 0.0
	var yaw := 0.0
	var roll := Input.get_axis("roll_right", "roll_left")

	# Check if CameraRig is in Orbit Mode (disable ship mouse steering during free orbit)
	var is_orbiting := false
	if body:
		var camera_rig := body.get_node_or_null("CameraRig")
		if camera_rig and "is_orbit_mode" in camera_rig:
			is_orbiting = camera_rig.is_orbit_mode

	var is_steering := false
	var steering_offset := Vector2.ZERO

	# Mouse offset from screen center: further from center = stronger continuous rotation
	if not is_orbiting and body and body.get_viewport():
		var viewport_rect := body.get_viewport().get_visible_rect()
		var center := viewport_rect.size * 0.5
		if center.x > 0.0 and center.y > 0.0:
			var mouse_pos := body.get_viewport().get_mouse_position()
			var offset := (mouse_pos - center) / center
			if offset.length() > mouse_deadzone:
				pitch = clampf(-offset.y, -1.0, 1.0)
				yaw = clampf(-offset.x, -1.0, 1.0)
				is_steering = true
				steering_offset = offset

	mouse_steering_updated.emit(is_steering, steering_offset)

	return Vector3(pitch, yaw, roll)


func handle_input(_event: InputEvent) -> void:
	pass


