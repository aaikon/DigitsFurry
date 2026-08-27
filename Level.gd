extends Node

const LAYOUTS = [
	preload("res://levels/Layout1.tscn"),
	preload("res://levels/Layout2.tscn"),
	preload("res://levels/Layout3.tscn"),
	preload("res://levels/Layout4.tscn"),
	preload("res://levels/Layout5.tscn"),
]
const BIRDS_SCENE = preload("res://levels/Birds.tscn")
const FLYING_BONUS_SCENE = preload("res://scenes/FlyingBonus.tscn")

# World-space band (matches SlingshotCamera's framed region in Level.tscn)
# that flying bonuses cross through, near the top of the visible sky.
const FLYING_BONUS_Y_RANGE = Vector2(935, 995)
const FLYING_BONUS_SPEED_RANGE = Vector2(180, 260)
const FLYING_BONUS_MIN_INTERVAL = 6.0
const FLYING_BONUS_MAX_INTERVAL = 14.0
const MAX_DASHES_PER_LEVEL = 3

signal score_changed(new_score)
signal max_score_changed(new_max_score)

var max_score = 0
var score = 0
var unlaunched_birds = []
var game_ended = false
var current_layout_index = 0

var _layout_node: Node = null
var _birds_node: Node = null
var _flying_bonuses: Array = []
var _dashes_remaining = MAX_DASHES_PER_LEVEL
var _layout_score_earned = 0 # points earned since the current layout was (re)loaded

func _ready():
	$StructuresWindow.world_2d = get_tree().root.world_2d
	# Off by default in Godot 4 -- without it, CollisionObject2D._input_event
	# (how Bird.gd detects being picked up) never fires, mouse or touch.
	get_viewport().physics_object_picking = true
	load_layout(0)
	_schedule_next_flying_bonus()

	# Input.mouse_mode is process-global, not per-window, so we can't just
	# hide it in project settings without also hiding it over AdminWindow
	# (operator needs the pointer for its buttons). Toggle it on focus
	# instead -- hidden while this touch window is active, restored when
	# focus moves to AdminWindow.
	var window = get_window()
	window.focus_entered.connect(func(): Input.mouse_mode = Input.MOUSE_MODE_HIDDEN)
	window.focus_exited.connect(func(): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE)
	if window.has_focus():
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

# Kiosk deployment: this window (slingshot/touch), StructuresWindow (pigs),
# and AdminWindow (operator controls) each live on their own monitor. Drag
# each window to its physical monitor, then press F11 on it to lock it
# fullscreen there -- see KioskWindow.gd.
func _unhandled_key_input(event):
	KioskWindow.handle_fullscreen_toggle(get_window(), event)
	$AdminWindow.handle_shortcuts(event)

func set_instructions_visible(value: bool):
	$InstructionsOverlay.visible = value
	$StructuresWindow/InstructionsOverlay.visible = value

## Resets the whole run: score goes back to 0 and play restarts from the
## first layout. Compare to load_layout(), which just (re)loads a layout
## without touching the running game score -- score is tallied across
## everything played between one reset_game() and the next.
func reset_game():
	score = 0
	_layout_score_earned = 0
	load_layout(0)

## Reloading the SAME layout index means the level is being reset/retried
## (there's no separate "Reset Level" button -- picking a layout does this),
## so whatever it earned this attempt is rolled back first. Progressing to a
## different layout keeps prior points, since score tallies across the whole
## game -- see reset_game().
func load_layout(index: int):
	if index == current_layout_index:
		score -= _layout_score_earned
	current_layout_index = index
	game_ended = false

	if _layout_node:
		_layout_node.queue_free()
	if _birds_node:
		_birds_node.queue_free()
	for bonus in _flying_bonuses:
		if is_instance_valid(bonus):
			bonus.queue_free()
	_flying_bonuses.clear()
	_dashes_remaining = MAX_DASHES_PER_LEVEL
	_layout_score_earned = 0
	$EndLevel.reset()
	$Gameover.reset()

	_layout_node = LAYOUTS[index].instantiate()
	add_child(_layout_node)
	_birds_node = BIRDS_SCENE.instantiate()
	add_child(_birds_node)

	await get_tree().process_frame

	max_score = 0
	for damageable in get_tree().get_nodes_in_group("Damageable") :
		damageable.connect("exploded", Callable(self, "_on_Damageable_exploded"))
		max_score += max(damageable.destroy_points, damageable.survive_points)

	unlaunched_birds = get_tree().get_nodes_in_group("Bird")

	var current_bird = change_bird()
	max_score -= current_bird.survive_points

	$StructuresWindow/GUI.set_max_score(max_score)
	$StructuresWindow/GUI.set_score(score)
	score_changed.emit(score)
	max_score_changed.emit(max_score)

func _schedule_next_flying_bonus():
	get_tree().create_timer(randf_range(FLYING_BONUS_MIN_INTERVAL, FLYING_BONUS_MAX_INTERVAL)).timeout.connect(_spawn_flying_bonus)

func _spawn_flying_bonus():
	if not game_ended:
		var bonus = FLYING_BONUS_SCENE.instantiate()
		var from_left = randf() < 0.5
		var start_pos = Vector2(90 if from_left else 760, randf_range(FLYING_BONUS_Y_RANGE.x, FLYING_BONUS_Y_RANGE.y))
		var speed = randf_range(FLYING_BONUS_SPEED_RANGE.x, FLYING_BONUS_SPEED_RANGE.y)
		bonus.caught.connect(_on_flying_bonus_caught)
		bonus.dashed.connect(_on_flying_bonus_dashed)
		add_child(bonus)
		bonus.launch(start_pos, 1.0 if from_left else -1.0, speed, _dashes_remaining > 0)
		_flying_bonuses.append(bonus)
	_schedule_next_flying_bonus()

func _add_score(points: int) -> void:
	score += points
	_layout_score_earned += points
	$StructuresWindow/GUI.set_score(score)
	score_changed.emit(score)

func _on_flying_bonus_caught(points):
	_add_score(points)

func _on_flying_bonus_dashed():
	_dashes_remaining -= 1

func _on_Damageable_exploded(damageable) :
	_add_score(damageable.destroy_points)
	await get_tree().process_frame
	var ennemies = get_tree().get_nodes_in_group("Ennemy")
	if ennemies.size() == 0:
		end_game()

func _on_Bird_eliminated(bird) :
	var current_bird = change_bird()
	if ! current_bird :
		end_game()

func _on_Bird_launched(bird):
	unlaunched_birds.pop_front()

func change_bird():
	if unlaunched_birds.size() == 0:
		return null
	var current_bird = unlaunched_birds[0]
	current_bird.connect("eliminated", Callable(self, "_on_Bird_eliminated"))
	current_bird.connect("launched", Callable(self, "_on_Bird_launched"))
	current_bird.attach_to($Slingshot)
	return current_bird

func end_game():
	if game_ended :
		return
	game_ended = true
	if get_tree().get_nodes_in_group("Ennemy").size() > 0:
		$Gameover.display()
		return
	while unlaunched_birds.size() > 0:
		var bird = unlaunched_birds.pop_front()
		_add_score(bird.survive_points)
		bird.explode(false)
	await get_tree().create_timer(2).timeout
	$EndLevel.display(score)
