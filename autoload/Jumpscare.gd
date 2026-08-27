extends Node

## Random fullscreen jumpscare: plays a chroma-keyed frame sequence (real
## alpha, so no green-box background) + a scream sound at a random
## interval during play. Disabled until you drop in your own frames --
## see assets/jumpscare/README.txt.

const FRAMES_DIR = "res://assets/jumpscare/frames/"
const SCREAM_PATH = "res://assets/audio/sfx/jumpscare_scream.ogg"
const PIPE_PATH = "res://assets/audio/sfx/pipe_falling.ogg"
const PIPE_IMAGE_PATH = "res://assets/jumpscare/pipe.png"

const FRAME_FPS = 30.0
const SCALE_MULT = 1.5
const SPEED_MULT = 1.5
const MIN_INTERVAL = 30.0
const MAX_INTERVAL = 60.0
const MIN_PLAY_FRACTION = 1 ## sometimes cuts short instead of playing to the end
const FALLBACK_DURATION = 6.0 ## force-clear if the play-duration timer somehow never fires

## Metal pipe sting -- sound + falling pipe image, runs on its own independent timer.
const PIPE_MIN_INTERVAL = 15.0
const PIPE_MAX_INTERVAL = 60.0
const PIPE_TARGET_WIDTH = 180.0
const PIPE_SCALE_MIN = 0.7
const PIPE_SCALE_MAX = 5.0
const PIPE_FALL_DURATION = 0.9

const PITCH_MIN = 0.5
const PITCH_MAX = 1.5

## Flashbang -- whole screen flashes white then slowly fades, on the
## Structures & Pigs window. Independent timer, same as the pipe sting.
const FLASHBANG_MIN_INTERVAL = 45.0
const FLASHBANG_MAX_INTERVAL = 60.0
const FLASHBANG_HOLD_DURATION = 3.0 ## fully white for this long before fading
const FLASHBANG_FADE_DURATION = 3.0

var enabled := true
var _frames: SpriteFrames = null
var _scream: AudioStream = null
var _pipe_sound: AudioStream = null
var _pipe_player: AudioStreamPlayer = null
var _pipe_texture: Texture2D = null

func _ready():
	_frames = _load_frames()
	if not _frames:
		push_warning("Jumpscare: no frames in %s -- disabled (see assets/jumpscare/README.txt)" % FRAMES_DIR)
	else:
		if ResourceLoader.exists(SCREAM_PATH):
			_scream = load(SCREAM_PATH)
		_schedule_next()

	if ResourceLoader.exists(PIPE_PATH):
		_pipe_sound = load(PIPE_PATH)
		_pipe_player = AudioStreamPlayer.new()
		add_child(_pipe_player)
		if ResourceLoader.exists(PIPE_IMAGE_PATH):
			_pipe_texture = load(PIPE_IMAGE_PATH)
		_schedule_next_pipe()
	else:
		push_warning("Jumpscare: no pipe sound at %s -- pipe scare disabled" % PIPE_PATH)

	_schedule_next_flashbang()

func _load_frames() -> SpriteFrames:
	var dir = DirAccess.open(FRAMES_DIR)
	if not dir:
		return null

	var names: Array[String] = []
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if not dir.current_is_dir() and (name.ends_with(".png") or name.ends_with(".webp")):
			names.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	if names.is_empty():
		return null
	names.sort()

	var sf = SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("jumpscare")
	sf.set_animation_loop("jumpscare", false)
	sf.set_animation_speed("jumpscare", FRAME_FPS * SPEED_MULT)
	for n in names:
		sf.add_frame("jumpscare", load(FRAMES_DIR + n))
	return sf

func _schedule_next():
	get_tree().create_timer(randf_range(MIN_INTERVAL, MAX_INTERVAL)).timeout.connect(_trigger)

func _trigger():
	if enabled:
		_show()
	_schedule_next()

## Manual one-off trigger (e.g. an operator shortcut) -- fires regardless of
## the enabled toggle, but only if frames are actually loaded.
func play_once() -> void:
	if _frames:
		_show()

func _schedule_next_pipe():
	get_tree().create_timer(randf_range(PIPE_MIN_INTERVAL, PIPE_MAX_INTERVAL)).timeout.connect(_trigger_pipe)

func _trigger_pipe():
	if enabled:
		_pipe_player.stream = _pipe_sound
		_pipe_player.pitch_scale = randf_range(PITCH_MIN, PITCH_MAX)
		_pipe_player.play()
		if _pipe_texture:
			_show_falling_pipe()
	_schedule_next_pipe()

func _show_falling_pipe():
	var layer = CanvasLayer.new()
	layer.layer = 100
	get_tree().root.add_child(layer)

	var sprite = Sprite2D.new()
	sprite.texture = _pipe_texture
	layer.add_child(sprite)

	var viewport_size = get_viewport().get_visible_rect().size
	var scale_factor = PIPE_TARGET_WIDTH / _pipe_texture.get_width() * randf_range(PIPE_SCALE_MIN, PIPE_SCALE_MAX)
	sprite.scale = Vector2(scale_factor, scale_factor)

	var half_height = _pipe_texture.get_height() * scale_factor / 2.0
	sprite.position = Vector2(randf_range(viewport_size.x * 0.2, viewport_size.x * 0.8), -half_height)

	var spin = randf_range(TAU * 1.5, TAU * 3.0) * (1 if randf() < 0.5 else -1)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "position:y", viewport_size.y + half_height, PIPE_FALL_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "rotation", spin, PIPE_FALL_DURATION) \
		.set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(func():
		if is_instance_valid(layer):
			layer.queue_free()
	)

func _schedule_next_flashbang():
	get_tree().create_timer(randf_range(FLASHBANG_MIN_INTERVAL, FLASHBANG_MAX_INTERVAL)).timeout.connect(_trigger_flashbang)

func _trigger_flashbang():
	if enabled:
		_show_flashbang()
	_schedule_next_flashbang()

func _show_flashbang():
	var structures_window = get_tree().root.get_node_or_null("Level/StructuresWindow")
	if not structures_window:
		return

	var layer = CanvasLayer.new()
	layer.layer = 100
	structures_window.add_child(layer)

	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 1)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(flash)

	var tween = create_tween()
	tween.tween_interval(FLASHBANG_HOLD_DURATION)
	tween.tween_property(flash, "color:a", 0.0, FLASHBANG_FADE_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		if is_instance_valid(layer):
			layer.queue_free()
	)

func _show():
	var layer = CanvasLayer.new()
	layer.layer = 100
	get_tree().root.add_child(layer)

	var sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _frames
	layer.add_child(sprite)

	var viewport_size = get_viewport().get_visible_rect().size
	var frame_size = _frames.get_frame_texture("jumpscare", 0).get_size()
	sprite.position = viewport_size / 2.0
	sprite.scale = viewport_size / frame_size * SCALE_MULT

	var sfx = AudioStreamPlayer.new()
	if _scream:
		sfx.stream = _scream
		sfx.pitch_scale = randf_range(PITCH_MIN, PITCH_MAX)
	layer.add_child(sfx)

	var clear := func():
		if is_instance_valid(layer):
			layer.queue_free()

	var full_duration = _frames.get_frame_count("jumpscare") / (FRAME_FPS * SPEED_MULT)
	var play_duration = randf_range(full_duration * MIN_PLAY_FRACTION, full_duration)
	get_tree().create_timer(play_duration).timeout.connect(clear)
	get_tree().create_timer(FALLBACK_DURATION).timeout.connect(clear)

	sprite.play("jumpscare")
	if _scream:
		sfx.play()
