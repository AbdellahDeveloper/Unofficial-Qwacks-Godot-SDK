class_name FlockTokenStore
extends RefCounted

func save_tokens(_access_token: String, _refresh_token: String) -> void:
	push_warning("[Flock SDK] TokenStore.save_tokens not implemented")

func load_tokens() -> Dictionary:
	return {}

func clear() -> void:
	pass
