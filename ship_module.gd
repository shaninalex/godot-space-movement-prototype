class_name ShipModule
extends Node3D

signal mass_changed(new_mass: float)

@export var mass: float = 10.0:
	set(value):
		if not is_equal_approx(mass, value):
			mass = value
			mass_changed.emit(mass)
