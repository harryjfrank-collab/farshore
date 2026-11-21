extends Node
## Registers default input actions for keyboard/mouse and gamepad.
## Actions already defined in Project Settings > Input Map are left alone,
## so you can rebind there and this script won't override you.


func _enter_tree() -> void:
	_add(&"move_forward", [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add(&"move_back", [_key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add(&"move_left", [_key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add(&"move_right", [_key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0)])

	_add(&"look_left", [_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_add(&"look_right", [_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_add(&"look_up", [_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_add(&"look_down", [_axis(JOY_AXIS_RIGHT_Y, 1.0)])

	_add(&"jump", [_key(KEY_SPACE), _button(JOY_BUTTON_A)])
	_add(&"sprint", [_key(KEY_SHIFT), _button(JOY_BUTTON_LEFT_STICK)])

	_add(&"dig", [_mouse(MOUSE_BUTTON_LEFT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_add(&"fill", [_mouse(MOUSE_BUTTON_RIGHT), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])


func _add(action: StringName, events: Array, deadzone := 0.2) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, deadzone)
	for e in events:
		InputMap.action_add_event(action, e)


func _key(keycode: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	return e


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	return e


func _button(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


func _axis(axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = direction
	return e
