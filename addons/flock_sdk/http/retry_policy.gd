class_name RetryPolicy
extends RefCounted

var max_retries: int = 3
var initial_delay: float = 1.0
var max_delay: float = 30.0
var backoff_multiplier: float = 2.0
var use_jitter: bool = true


class RetryHandler extends RefCounted:
	var _policy: RetryPolicy
	var _logger: FlockLogger

	func _init(policy: RetryPolicy = null, logger: FlockLogger = null) -> void:
		_policy = policy if policy else RetryPolicy.new()
		_logger = logger

	func execute_async(operation: Callable, retry_ambiguous_failures: bool = true, max_retries_override: int = -1) -> Variant:
		var max_retries := max_retries_override if max_retries_override >= 0 else _policy.max_retries
		var attempt := 0
		var delay := _policy.initial_delay

		while true:
			attempt += 1
			if attempt > 1:
				_logger.log_debug("Attempt %d/%d" % [attempt, max_retries + 1])

			var result = await operation.call()

			if result is Dictionary and result.has("error"):
				if attempt <= max_retries:
					var error_code: String = str(result.get("code", ""))
					var status_code: int = int(result.get("status_code", 0))

					if status_code >= 400 and status_code < 500 and status_code != 408 and status_code != 429:
						return result

					if not retry_ambiguous_failures and status_code != 408 and status_code != 429:
						return result

					if error_code in ["player.invalid_login_credentials", "player.invalid_refresh_token"]:
						return result

					_logger.log_warning("Attempt %d failed: %s. Retrying in %.1fs..." % [attempt, result.get("error", ""), delay])
					await Engine.get_main_loop().create_timer(delay).timeout

					delay = minf(delay * _policy.backoff_multiplier, _policy.max_delay)
					if _policy.use_jitter:
						delay *= randf_range(0.75, 1.25)
				else:
					_logger.log_error("Operation failed after %d attempt(s)" % attempt)
					return result
			else:
				return result

		return {"error": "Retry loop exited unexpectedly"}
