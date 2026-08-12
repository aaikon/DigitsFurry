extends CanvasLayer

@onready var score_progress = $MarginContainer/VBoxContainer/NinePatchRect/HBoxLeft/ScoreProgress
@onready var score_max_label = $MarginContainer/VBoxContainer/NinePatchRect/HBoxRight/ScoreMax
@onready var score_value_label = $MarginContainer/VBoxContainer/NinePatchRect/HBoxRight/ScoreValue

var animated_score = 0
var score_tween: Tween

func _process(delta):
	score_progress.value = animated_score
	score_value_label.text = str(int(animated_score))

func set_max_score(score_max):
	score_progress.max_value = score_max
	score_max_label.text = str(score_max)

func set_score(score):
	if score_tween:
		score_tween.kill()
	score_tween = create_tween()
	score_tween.tween_property(self, "animated_score", score, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
