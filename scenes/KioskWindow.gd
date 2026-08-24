class_name KioskWindow
extends RefCounted

const FULLSCREEN_TOGGLE_KEYS = [KEY_F11, KEY_F12]

## Lets an operator drag a kiosk window to whichever monitor it belongs on,
## then press F11 or F12 to lock it fullscreen there -- no hardcoded screen index.
static func handle_fullscreen_toggle(window: Window, event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in FULLSCREEN_TOGGLE_KEYS:
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
