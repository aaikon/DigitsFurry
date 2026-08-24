extends CanvasLayer

@export var score_levels: Dictionary = {
	1: 5000,
	2: 10000,
	3: 15000
}

var animated_score
var score_tween: Tween

func _ready():
	$Background.hide()
	set_process(false)

func _process(delta):
	for level in score_levels.keys():
		if animated_score >= score_levels[level]:
			get_node("Background/Star" + str(level)).show()
	$Background/Label.text = str(int(animated_score))

func display(score):
	animated_score = 0
	set_process(true)
	$Background.show()
	Sfx.play_level_win()
	if score_tween:
		score_tween.kill()
	score_tween = create_tween()
	score_tween.tween_property(self, "animated_score", score, 2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)

func reset():
	if score_tween:
		score_tween.kill()
	set_process(false)
	animated_score = 0
	$Background.hide()
	for level in score_levels.keys():
		get_node("Background/Star" + str(level)).hide()
