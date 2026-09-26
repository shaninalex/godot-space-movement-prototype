class_name Player
extends RigidBody3D

@export var ship_base_mass: float = 100.0
@onready var movement_controller: MovementController = MovementController.new()


func _ready():
	angular_damp = 0.3
	init_thrusters()
	init_modules()
	update_mass_and_center_of_mass()
	print("Ship mass: ", mass)

func init_modules():
	for child in get_children():
		if child is ShipModule:
			child.mass_changed.connect(func(_new_mass): update_mass_and_center_of_mass())


func _physics_process(delta):
	movement_controller.physics_process(delta, self)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	movement_controller.set_center_of_mass(state.center_of_mass_local)


func _unhandled_input(event: InputEvent) -> void:
	movement_controller.handle_input(event)


func update_mass_and_center_of_mass() -> void:
	var total_mass: float = ship_base_mass
	var weighted_pos := Vector3.ZERO # Власний центр мас корпусу в (0,0,0)

	for child in get_children():
		if child is ShipModule:
			total_mass += child.mass
			weighted_pos += child.position * child.mass

	mass = total_mass
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = weighted_pos / total_mass
	movement_controller.set_center_of_mass(center_of_mass)


func init_thrusters():
	for thruster in get_children():
		if thruster is Thruster:
			movement_controller.add_thruster(thruster)

