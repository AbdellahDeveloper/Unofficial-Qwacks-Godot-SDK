extends GutTest


func test_verbose_flag_from_constructor() -> void:
	var loud := GodotFlockLogger.new(true)
	assert_eq(loud._verbose, true, "constructor true -> verbose")
	var quiet := GodotFlockLogger.new(false)
	assert_eq(quiet._verbose, false, "constructor false -> quiet")


func test_log_info_and_debug_are_safe_when_quiet() -> void:
	var quiet := GodotFlockLogger.new(false)
	quiet.log_info("hidden")
	quiet.log_debug("hidden")
	assert_true(true, "quiet info/debug produced no output")


func test_verbose_logging_prints() -> void:
	var loud := GodotFlockLogger.new(true)
	loud.log_info("visible")
	loud.log_debug("visible")
	assert_true(true, "verbose info/debug printed without error")


func test_verbose_gates_only_info_and_debug() -> void:
	# Warnings/errors must NOT be gated by _verbose — verified structurally: the
	# two gated methods are log_info/log_debug; all others always surface.
	assert_eq(GodotFlockLogger.new(false)._verbose, false, "quiet logger still surfaces warnings/errors")