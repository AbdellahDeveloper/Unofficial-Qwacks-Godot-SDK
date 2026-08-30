extends GutTest


func test_leaderboard_parsing() -> void:
	var board := LeaderboardModels.parse_leaderboard({
		"id": "lb1", "name": "Speedrun", "value_type": "duration", "direction": "lower",
		"aggregation": "best", "window_type": "weekly", "scope": "global"
	})
	assert_eq(board["value_type"], LeaderboardModels.VALUE_TYPE_DURATION_SECONDS, "lb value type")
	assert_eq(board["direction"], LeaderboardModels.DIRECTION_LOWER, "lb direction")
	assert_eq(board["aggregation"], LeaderboardModels.AGGREGATION_BEST, "lb aggregation")
	assert_eq(board["window_type"], LeaderboardModels.WINDOW_TYPE_WEEKLY, "lb window type")
	assert_eq(board["scope"], LeaderboardModels.SCOPE_GLOBAL, "lb scope")
	assert_eq(LeaderboardModels.is_higher_better(board), false, "lb is higher better (lower)")


func test_is_higher_better() -> void:
	var int_board := LeaderboardModels.parse_leaderboard({"value_type": "integer", "direction": "higher", "aggregation": "sum", "window_type": "never", "scope": "country"})
	assert_eq(LeaderboardModels.is_higher_better(int_board), true, "int board higher")


func test_format_score() -> void:
	var int_board := LeaderboardModels.parse_leaderboard({"value_type": "integer"})
	assert_eq(LeaderboardModels.format_score(int_board, 7.4), "7", "format int")
	assert_eq(LeaderboardModels.format_score(int_board, null), "", "format int null")
	assert_eq(LeaderboardModels.format_score(int_board, INF), "", "format int inf")

	var float_board := LeaderboardModels.parse_leaderboard({"value_type": "float"})
	assert_eq(LeaderboardModels.format_score(float_board, 3.5), "3.5", "format float 3.5")
	assert_eq(LeaderboardModels.format_score(float_board, 3.0), "3", "format float 3.0")
	assert_eq(LeaderboardModels.format_score(float_board, 3.14159), "3.14", "format float 3.14159")


func test_format_duration() -> void:
	assert_eq(LeaderboardModels.format_duration(65.5), "1:05.500", "duration 65.5")
	assert_eq(LeaderboardModels.format_duration(3661.25), "1:01:01.250", "duration 3661.25")
	assert_eq(LeaderboardModels.format_duration(-65.5), "-1:05.500", "duration negative")
	assert_eq(LeaderboardModels.format_duration(9.0), "0:09.000", "duration 9")