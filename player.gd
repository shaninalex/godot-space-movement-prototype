class_name Player
extends RigidBody3D

@export var ship_mass := 100

@onready var movement_controller: MovementController = MovementController.new()


func _ready():
	angular_damp = 0.9
	mass = ship_mass
	init_thrusters()


func _physics_process(delta):
	movement_controller.physics_process(delta, self)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	movement_controller.set_center_of_mass(state.center_of_mass_local)

func _unhandled_input(event: InputEvent) -> void:
	movement_controller.handle_input(event)


func init_thrusters():
	for thruster in get_children():
		if thruster is Thruster:
			movement_controller.add_thruster(thruster)

