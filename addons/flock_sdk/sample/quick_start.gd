extends Control

## Flock SDK Quick Start Example

@onready var status_label: Label = %StatusLabel
@onready var player_id_label: Label = %PlayerIdLabel
@onready var login_button: Button = %LoginButton
@onready var logout_button: Button = %LogoutButton
@onready var send_event_button: Button = %SendEventButton
@onready var log_error_button: Button = %LogErrorButton

func _ready() -> void:
	status_label.text = "Initializing SDK..."
	login_button.disabled = true
	logout_button.disabled = true
	send_event_button.disabled = true
	log_error_button.disabled = true

	FlockEvents.get_instance().initialized.connect(_on_sdk_initialized)
	FlockEvents.get_instance().initialization_failed.connect(_on_sdk_failed)
	FlockEvents.get_instance().authenticated.connect(_on_authenticated)
	FlockEvents.get_instance().auth_expired.connect(_on_session_expired)


func _on_sdk_initialized() -> void:
	status_label.text = "SDK Initialized"

	if FlockClient.get_instance().is_authenticated:
		_on_authenticated({"player_id": FlockClient.get_instance().current_player_id})
	else:
		login_button.disabled = false


func _on_sdk_failed(error: String) -> void:
	status_label.text = "SDK Failed: %s" % error


func _on_authenticated(info: Dictionary) -> void:
	status_label.text = "Authenticated"
	player_id_label.text = "Player ID: %s" % info.get("player_id", "")
	login_button.disabled = true
	logout_button.disabled = false
	send_event_button.disabled = false
	log_error_button.disabled = false


func _on_session_expired() -> void:
	status_label.text = "Session Expired"
	player_id_label.text = ""
	login_button.disabled = false
	logout_button.disabled = true
	send_event_button.disabled = true
	log_error_button.disabled = true


func _on_login_button_pressed() -> void:
	status_label.text = "Logging in..."
	login_button.disabled = true
	var result = await FlockClient.get_instance().auth.login_with_device("")
	if result is Dictionary and result.has("error"):
		status_label.text = "Login Failed: %s" % result["error"]
		login_button.disabled = false


func _on_logout_button_pressed() -> void:
	FlockClient.get_instance().clear_tokens()
	status_label.text = "Logged out"
	player_id_label.text = ""
	login_button.disabled = false
	logout_button.disabled = true
	send_event_button.disabled = true
	log_error_button.disabled = true


func _on_send_event_button_pressed() -> void:
	FlockClient.get_instance().analytics.log_event("test_event", {"source": "quick_start"})
	status_label.text = "Event sent"


func _on_log_error_button_pressed() -> void:
	FlockClient.get_instance().analytics.log_error("Test error from quick_start", "TEST_ERROR")
	status_label.text = "Error logged"
