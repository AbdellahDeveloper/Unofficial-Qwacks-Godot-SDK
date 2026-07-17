@tool
extends EditorPlugin

const AUTOLOAD_RUNTIME := "FlockRuntimeSetup"

func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_RUNTIME, "res://addons/flock_sdk/core/flock_runtime_setup.gd")
	print("[Flock SDK] Plugin enabled")

func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_RUNTIME)
	print("[Flock SDK] Plugin disabled")
