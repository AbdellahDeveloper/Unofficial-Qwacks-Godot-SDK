class_name GodotFlockLogger
extends FlockLogger

# Verbose gates info/debug only; warnings and errors always surface — matches UnityFlockLogger.
var _verbose: bool = true

func _init(verbose: bool = true) -> void:
	_verbose = verbose

func log_info(message: String) -> void:
	if _verbose:
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
	if _verbose:
		print("[Flock SDK] ", message)
