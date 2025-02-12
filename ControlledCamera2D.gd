extends Camera2D

var target_zoom: Vector2 = zoom
const ZOOM_CHANGE_RATE: float = 10

var target_position: Vector2 = position
const POSITION_CHANGE_RATE: float = 40

func _process(delta: float) -> void:
	zoom = (zoom * max(0, 1 - ZOOM_CHANGE_RATE * delta)) + (target_zoom * min(1, ZOOM_CHANGE_RATE * delta))
	
	position = (position * max(0, 1 - POSITION_CHANGE_RATE * delta)) + (target_position * min(1, POSITION_CHANGE_RATE * delta))
