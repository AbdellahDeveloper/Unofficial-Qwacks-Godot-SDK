class_name GodotFlockLogger
extends FlockLogger

func log_info(message: String) -> void:
	print("[Flock SDK] ", message)

func log_warning(message: String) -> void:
	push_warning("[Flock SDK] ", message)

func log_error(message: String) -> void:
	push_error("[Flock SDK] ", message)

func log_error_exception(message: String, exception: String) -> void:
	push_error("[Flock SDK] %s\nException: %s" % [message, exception])

func log_exception(exception: String) -> void:
	push_error("[Flock SDK] Exception: ", exception)

func log_debug(message: String) -> void:
	print("[Flock SDK] ", message)
