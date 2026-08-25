extends Window

func _unhandled_key_input(event):
	KioskWindow.handle_fullscreen_toggle(self, event)
	get_parent().get_node("AdminWindow").handle_shortcuts(event)
