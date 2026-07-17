class_name FlockException
extends RefCounted

var message: String = ""
var body: String = ""
var status_code: int = -1
var code: String = ""
var retry_after: float = -1.0

var error_code: int:
	get:
		return FlockErrorCodes.parse(code)


func _init(p_message: String = "") -> void:
	message = p_message


func _to_string() -> String:
	if body.is_empty():
		return "FlockException: %s" % message
	return "FlockException: %s\nResponse body: %s" % [message, body]


class FlockNetworkException extends FlockException:
	func _init(p_message: String = "", p_status_code: int = -1) -> void:
		super(p_message)
		status_code = p_status_code

	static func is_permanent_status(status: int) -> bool:
		if status == 408 or status == 429:
			return false
		return status >= 400 and status < 500


class FlockAuthException extends FlockException:
	func _init(p_message: String = "") -> void:
		super(p_message)


class FlockValidationException extends FlockException:
	func _init(p_message: String = "") -> void:
		super(p_message)


class FlockSerializationException extends FlockException:
	func _init(p_message: String = "") -> void:
		super(p_message)
