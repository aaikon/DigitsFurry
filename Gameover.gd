extends CanvasLayer

func _ready():
	$PanelContainer.hide()

func display():
	await get_tree().create_timer(1).timeout
	$PanelContainer.show()
	$PanelContainer/Message.text = "Game Over"

func reset():
	$PanelContainer.hide()
