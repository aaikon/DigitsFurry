extends Camera2D

# The region this camera frames by default (used to compute its centered
# position and starting zoom). This is deliberately separate from the
# built-in limit_* properties: those are left at the full level bounds so
# the engine only stops the camera at the true edge of the world, not at
# this camera's preferred framing -- otherwise, resizing the window past
# this region's size would get clamped/cropped by the engine instead of
# revealing more of the scene.
@export var region_position: Vector2
@export var region_size: Vector2

# Zoom is computed once (covering the region at whatever size the window
# starts at) and then left alone: resizing the window afterward reveals more
# or less of the region at that same fixed scale, instead of continuously
# rescaling the image to fill the new size. That keeps rendering pixel-exact
# (no upscale blur) and means a bigger window shows more of the scene rather
# than just a stretched version of the same crop.

func _ready():
	position_smoothing_enabled = false
	position = region_position + region_size / 2
	if not _try_lock_zoom():
		get_viewport().size_changed.connect(_on_size_changed)

func _on_size_changed():
	if _try_lock_zoom():
		get_viewport().size_changed.disconnect(_on_size_changed)

func _try_lock_zoom() -> bool:
	var viewport_size = get_viewport_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return false
	var zoom_factor = max(viewport_size.x / region_size.x, viewport_size.y / region_size.y)
	zoom = Vector2(zoom_factor, zoom_factor)
	return true
