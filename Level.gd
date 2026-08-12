extends Node

const LAYOUTS = [
	preload("res://levels/Layout1.tscn"),
	preload("res://levels/Layout2.tscn"),
	preload("res://levels/Layout3.tscn"),
]
const BIRDS_SCENE = preload("res://levels/Birds.tscn")

signal score_changed(new_score)
signal max_score_changed(new_max_score)

var max_score = 0
var score = 0
var unlaunched_birds = []
var game_ended = false
var current_layout_index = 0

var _layout_node: Node = null
var _birds_node: Node = null

func _ready():
	$StructuresWindow.world_2d = get_tree().root.world_2d
	# Off by default in Godot 4 -- without it, CollisionObject2D._input_event
	# (how Bird.gd detects being picked up) never fires, mouse or touch.
	get_viewport().physics_object_picking = true
	load_layout(0)

# Kiosk deployment: this window (slingshot/touch), StructuresWindow (pigs),
# and AdminWindow (operator controls) each live on their own monitor. Drag
# each window to its physical monitor, then press F11 on it to lock it
# fullscreen there -- see KioskWindow.gd.
func _unhandled_key_input(event):
	KioskWindow.handle_fullscreen_toggle(get_window(), event)

# TEMP DEBUG -- remove once touch click behavior is diagnosed.
func _input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton:
		print("[MainWindow input] ", event)

func load_layout(index: int):
	current_layout_index = index
	game_ended = false

	if _layout_node:
		_layout_node.queue_free()
	if _birds_node:
		_birds_node.queue_free()
	$EndLevel.reset()
	$Gameover.reset()

	_layout_node = LAYOUTS[index].instantiate()
	add_child(_layout_node)
	_birds_node = BIRDS_SCENE.instantiate()
	add_child(_birds_node)

	await get_tree().process_frame

	score = 0
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

func _on_Damageable_exploded(damageable) :
	score += damageable.destroy_points
	$StructuresWindow/GUI.set_score(score)
	score_changed.emit(score)
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
		score += bird.survive_points
		bird.explode(false)
	$StructuresWindow/GUI.set_score(score)
	score_changed.emit(score)
	await get_tree().create_timer(2).timeout
	$EndLevel.display(score)
