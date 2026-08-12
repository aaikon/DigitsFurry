extends Window

func _unhandled_key_input(event):
	KioskWindow.handle_fullscreen_toggle(self, event)
