class_name CursorController
extends CanvasLayer

signal steering_started(direction: Vector2, angle: float)
signal steering_updated(direction: Vector2, angle: float)
signal steering_ended()

@export var default_cursor: Texture2D = preload("res://mouse_pointer.png")
@export var arrow_cursor: Texture2D = preload("res://direction-arrow.png")

var _sprite: Sprite2D
var _is_steering: bool = false


func _ready() -> void:
	layer = 100
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	_sprite = Sprite2D.new()
	_sprite.texture = default_cursor
	_sprite.centered = true
	_sprite.offset = Vector2(8, 9)
	add_child(_sprite)


func _process(_delta: float) -> void:
	if _sprite and is_instance_valid(_sprite):
		_sprite.global_position = get_viewport().get_mouse_position()


func update_steering(is_steering: bool, offset: Vector2) -> void:
	if not _sprite:
		return

	if is_steering:
		var angle := offset.angle() + PI / 2.0
		_sprite.texture = arrow_cursor
		_sprite.rotation = angle
		_sprite.offset = Vector2.ZERO

		if not _is_steering:
			_is_steering = true
			steering_started.emit(offset, angle)
		else:
			steering_updated.emit(offset, angle)
	else:
		_sprite.texture = default_cursor
		_sprite.rotation = 0.0
		_sprite.offset = Vector2(8, 9)

		if _is_steering:
			_is_steering = false
			steering_ended.emit()
