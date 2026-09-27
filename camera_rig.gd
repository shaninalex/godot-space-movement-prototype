class_name CameraRig
extends Node3D

@export_group("Follow Inertia")
## Controls how smoothly the camera follows the ship's rotation (higher = snappier, lower = more lag/inertia).
@export var rotation_inertia_speed: float = 6.0
## Base offset of camera relative to ship (Y = height, Z = distance behind).
@export var base_offset: Vector3 = Vector3(0.0, 5.0, 16.0)

@export_group("Zoom")
@export var min_zoom: float = 0.4
@export var max_zoom: float = 2.5
@export var zoom_step: float = 0.15
@export var zoom_speed: float = 12.0

@export_group("Pan Offset")
## Maximum lateral (X) and vertical (Y) camera shift based on mouse steering.
@export var max_pan_offset: Vector2 = Vector2(5.5, 1.5)
## Speed of camera pan smoothing.
@export var pan_smooth_speed: float = 0.05
@export var pan_enabled: bool = true

@export_group("Orbit Mode")
@export var orbit_sensitivity: float = 0.005
@export var orbit_inertia_speed: float = 10.0

@onready var camera: Camera3D = $Camera3D

var is_orbit_mode: bool = false

var _target_node: Node3D
var _current_zoom: float = 1.0
var _target_zoom: float = 1.0

var _orbit_quat_target: Quaternion = Quaternion.IDENTITY
var _orbit_quat: Quaternion = Quaternion.IDENTITY

var _current_rotation_quat: Quaternion = Quaternion.IDENTITY
var _current_pan: Vector2 = Vector2.ZERO


func _ready() -> void:
	_target_node = get_parent() as Node3D
	top_level = true

	if _target_node:
		global_position = _target_node.global_position
		_current_rotation_quat = _target_node.global_basis.get_rotation_quaternion()
		global_basis = Basis(_current_rotation_quat)

	if camera:
		if base_offset == Vector3.ZERO:
			base_offset = camera.position
		camera.position = base_offset
		camera.look_at(global_position, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	# Toggle Free Orbit mode with Tab
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle_orbit_mode()

	# Mouse wheel zoom
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom = clampf(_target_zoom - zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom = clampf(_target_zoom + zoom_step, min_zoom, max_zoom)

	# Orbit rotation input (mouse motion with RMB pressed) - Blender / DSP trackball free orbit
	if is_orbit_mode and event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT != 0):
		var mouse_event := event as InputEventMouseMotion
		var rot_yaw: float = -mouse_event.relative.x * orbit_sensitivity
		var rot_pitch: float = -mouse_event.relative.y * orbit_sensitivity
		var delta_rot := Quaternion(Vector3.UP, rot_yaw) * Quaternion(Vector3.RIGHT, rot_pitch)
		_orbit_quat_target = (_orbit_quat_target * delta_rot).normalized()


func _physics_process(delta: float) -> void:
	if not _target_node:
		return

	# Strictly match ship position without translational lag
	global_position = _target_node.global_position

	# Process Zoom
	_current_zoom = lerpf(_current_zoom, _target_zoom, zoom_speed * delta)

	# Process Pan-Offset based on mouse cursor distance from screen center
	var target_pan := Vector2.ZERO
	if not is_orbit_mode and get_viewport() and pan_enabled:
		var viewport_rect := get_viewport().get_visible_rect()
		var center := viewport_rect.size * 0.5
		if center.x > 0.0 and center.y > 0.0:
			var mouse_pos := get_viewport().get_mouse_position()
			var offset := (mouse_pos - center) / center
			target_pan = Vector2(offset.x * max_pan_offset.x, offset.y * max_pan_offset.y)

	_current_pan = _current_pan.lerp(target_pan, pan_smooth_speed * delta)

	# Process Rotation
	var ship_quat := _target_node.global_basis.get_rotation_quaternion()

	if is_orbit_mode:
		# Smoothly interpolate orbit quaternion towards target with inertia
		_orbit_quat = _orbit_quat.slerp(_orbit_quat_target, orbit_inertia_speed * delta)
	else:
		# Smoothly return orbit rotation back to default orientation behind ship
		_orbit_quat_target = Quaternion.IDENTITY
		_orbit_quat = _orbit_quat.slerp(Quaternion.IDENTITY, rotation_inertia_speed * delta)

	var target_quat := (ship_quat * _orbit_quat).normalized()
	_current_rotation_quat = _current_rotation_quat.slerp(target_quat, rotation_inertia_speed * delta)

	global_basis = Basis(_current_rotation_quat)

	# Update camera position with zoom and pan offset, and frame the ship
	if camera:
		camera.position = base_offset * _current_zoom
		camera.look_at(Vector3(global_position.x + _current_pan.x, global_position.y + _current_pan.y, global_position.z), global_basis.y)


func toggle_orbit_mode() -> void:
	is_orbit_mode = !is_orbit_mode
