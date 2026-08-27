extends Area2D

## A bonus target that flies across the top of the slingshot window on a
## gentle, wavering path. Some of the time (DASH_CHANCE), at a random point
## partway through the flight, it suddenly darts off very fast in a random
## direction to make its exit -- otherwise it just wavers on out normally.
## Tap/click it for points -- let it get away and it's just missed, no
## penalty.

signal caught(points)
signal dashed

var points := 1000

var direction := 1.0 # 1 = moving right, -1 = moving left
var _base_speed := 0.0
var _speed_variation := 0.0
var _speed_freq := 0.0
var _start_y := 0.0
var _drift_y := 0.0 # px/sec -- gentle overall climb or descent across the flight
var _bob_amplitude := 0.0
var _bob_freq := 0.0
var _time := 0.0

var _will_dash := false
var _dashing := false
var _dash_at := 0.0
var _dash_velocity := Vector2.ZERO

const DASH_CHANCE = 0.4
const DASH_SPEED_RANGE = Vector2(900.0, 1400.0)
const DASH_DELAY_RANGE = Vector2(0.3, 6.0)
const ROTATION_SPEED = 3.0 # radians/sec
const BOUNDS_MARGIN = 150.0
# World-space rect matching SlingshotCamera's framed region in Level.tscn.
const SCREEN_RECT = Rect2(141.6667, 925, 566.6667, 300)

func launch(start_pos: Vector2, launch_direction: float, speed: float, allow_dash: bool = true) -> void:
	position = start_pos
	direction = launch_direction
	_base_speed = speed
	_start_y = start_pos.y
	_speed_variation = randf_range(0.15, 0.4)
	_speed_freq = randf_range(0.5, 1.5)
	_drift_y = randf_range(-30.0, 30.0)
	_bob_amplitude = randf_range(10.0, 35.0)
	_bob_freq = randf_range(0.8, 2.2)
	_will_dash = allow_dash and randf() < DASH_CHANCE
	_dash_at = randf_range(DASH_DELAY_RANGE.x, DASH_DELAY_RANGE.y)

func _physics_process(delta):
	_time += delta
	rotation += ROTATION_SPEED * delta
	if _will_dash and not _dashing and _time >= _dash_at:
		_start_dash()

	if _dashing:
		position += _dash_velocity * delta
	else:
		var speed = _base_speed * (1.0 + sin(_time * _speed_freq) * _speed_variation)
		position.x += direction * speed * delta
		position.y = _start_y + _drift_y * _time + sin(_time * _bob_freq) * _bob_amplitude

	if _is_out_of_bounds():
		queue_free()

func _start_dash() -> void:
	_dashing = true
	var angle = randf_range(0, TAU)
	var speed = randf_range(DASH_SPEED_RANGE.x, DASH_SPEED_RANGE.y)
	_dash_velocity = Vector2(cos(angle), sin(angle)) * speed
	dashed.emit()

func _is_out_of_bounds() -> bool:
	return (
		position.x < SCREEN_RECT.position.x - BOUNDS_MARGIN
		or position.x > SCREEN_RECT.position.x + SCREEN_RECT.size.x + BOUNDS_MARGIN
		or position.y < SCREEN_RECT.position.y - BOUNDS_MARGIN
		or position.y > SCREEN_RECT.position.y + SCREEN_RECT.size.y + BOUNDS_MARGIN
	)

func _input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("touch"):
		caught.emit(points)
		queue_free()
