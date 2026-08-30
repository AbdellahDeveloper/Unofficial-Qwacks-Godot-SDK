@tool
extends EditorPlugin

const AUTOLOAD_RUNTIME := "FlockRuntimeSetup"
const INITIALIZER_SCRIPT := "res://addons/flock_sdk/editor/flock_initializer_window.gd"

var _initializer_window: Window = null

func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_RUNTIME, "res://addons/flock_sdk/core/flock_runtime_setup.gd")
	add_tool_menu_item("Flock Initializer", Callable(self, "_open_initializer"))
	print("[Flock SDK] Plugin enabled")

func _exit_tree() -> void:
	remove_tool_menu_item("Flock Initializer")
	if _initializer_window and is_instance_valid(_initializer_window):
		_initializer_window.queue_free()
		_initializer_window = null
	remove_autoload_singleton(AUTOLOAD_RUNTIME)
	print("[Flock SDK] Plugin disabled")

func _open_initializer() -> void:
	if _initializer_window == null or not is_instance_valid(_initializer_window):
		_initializer_window = load(INITIALIZER_SCRIPT).new()
		add_child(_initializer_window)
	_initializer_window.popup_centered(Vector2i(600, 720))
