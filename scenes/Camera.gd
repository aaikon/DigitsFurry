extends Camera2D

func _ready():
	position_smoothing_enabled = false
	get_viewport().size_changed.connect(_fit_to_scene)
	_fit_to_scene()

func _fit_to_scene():
	var scene_size = Vector2(limit_right - limit_left, limit_bottom - limit_top)
	var viewport_size = get_viewport_rect().size
	var zoom_factor = min(viewport_size.x / scene_size.x, viewport_size.y / scene_size.y)
	zoom = Vector2(zoom_factor, zoom_factor)
	position = Vector2(limit_left, limit_top) + scene_size / 2
