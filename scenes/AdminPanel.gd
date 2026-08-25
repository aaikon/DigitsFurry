extends Window

@onready var score_label = $Panel/VBox/ScoreLabel
@onready var max_label = $Panel/VBox/MaxLabel

func _ready():
	var level = get_parent()
	$Panel/VBox/ResetButton.pressed.connect(func(): level.load_layout(level.current_layout_index))
	$Panel/VBox/Layout1Button.pressed.connect(func(): level.load_layout(0))
	$Panel/VBox/Layout2Button.pressed.connect(func(): level.load_layout(1))
	$Panel/VBox/Layout3Button.pressed.connect(func(): level.load_layout(2))
	$Panel/VBox/Layout4Button.pressed.connect(func(): level.load_layout(3))
	$Panel/VBox/Layout5Button.pressed.connect(func(): level.load_layout(4))
	$Panel/VBox/JumpscareToggle.button_pressed = Jumpscare.enabled
	$Panel/VBox/JumpscareToggle.toggled.connect(func(pressed): Jumpscare.enabled = pressed)
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
	handle_shortcuts(event)

## Callable from any kiosk window (not just this one), so operator shortcuts
## work regardless of which window currently has focus -- see Level.gd and
## StructuresWindow.gd.
func handle_shortcuts(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_R:
			$Panel/VBox/ResetButton.pressed.emit()
		KEY_1:
			$Panel/VBox/Layout1Button.pressed.emit()
		KEY_2:
			$Panel/VBox/Layout2Button.pressed.emit()
		KEY_3:
			$Panel/VBox/Layout3Button.pressed.emit()
		KEY_4:
			$Panel/VBox/Layout4Button.pressed.emit()
		KEY_5:
			$Panel/VBox/Layout5Button.pressed.emit()
		KEY_J:
			$Panel/VBox/JumpscareToggle.button_pressed = not $Panel/VBox/JumpscareToggle.button_pressed
