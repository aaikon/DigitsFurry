extends Window

@onready var score_label = $Panel/VBox/ScoreLabel
@onready var max_label = $Panel/VBox/MaxLabel

func _ready():
	var level = get_parent()
	$Panel/VBox/ResetButton.pressed.connect(func(): level.load_layout(level.current_layout_index))
	$Panel/VBox/Layout1Button.pressed.connect(func(): level.load_layout(0))
	$Panel/VBox/Layout2Button.pressed.connect(func(): level.load_layout(1))
	$Panel/VBox/Layout3Button.pressed.connect(func(): level.load_layout(2))
	level.score_changed.connect(_on_score_changed)
	level.max_score_changed.connect(_on_max_score_changed)
	_on_score_changed(level.score)
	_on_max_score_changed(level.max_score)

func _on_score_changed(new_score):
	score_label.text = "Score: %d" % new_score

func _on_max_score_changed(new_max):
	max_label.text = "Max: %d" % new_max

func _unhandled_key_input(event):
	KioskWindow.handle_fullscreen_toggle(self, event)
