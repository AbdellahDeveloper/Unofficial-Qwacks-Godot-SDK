extends Node

func _ready() -> void:
	var events_script = load("res://addons/flock_sdk/core/flock_events.gd")
	var events = events_script.new()
	events.name = "FlockEventsNode"
	add_child(events)

	var client_script = load("res://addons/flock_sdk/core/flock_client.gd")
	var client = client_script.new()
	client.name = "FlockClientNode"
	add_child(client)
