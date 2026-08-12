class_name KioskWindow
extends RefCounted

const FULLSCREEN_TOGGLE_KEY = KEY_F11

## Lets an operator drag a kiosk window to whichever monitor it belongs on,
## then press F11 to lock it fullscreen there -- no hardcoded screen index.
static func handle_fullscreen_toggle(window: Window, event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == FULLSCREEN_TOGGLE_KEY:
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
