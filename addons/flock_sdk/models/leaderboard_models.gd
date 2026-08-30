class_name LeaderboardModels

# What a board's scores measure. Duration scores are in seconds — the name says so because the wire value doesn't.
const VALUE_TYPE_INTEGER := 0
const VALUE_TYPE_FLOAT := 1
const VALUE_TYPE_DURATION_SECONDS := 2

# Which end of the scale wins — high score or best time.
const DIRECTION_HIGHER := 0
const DIRECTION_LOWER := 1

# How repeated writes to the source field fold into one score.
const AGGREGATION_BEST := 0
const AGGREGATION_LATEST := 1
const AGGREGATION_SUM := 2

# How a board buckets over time. Board config — not the window key you read with.
const WINDOW_TYPE_NEVER := 0
const WINDOW_TYPE_WEEKLY := 1
const WINDOW_TYPE_SEASONAL := 2

# Whether the board ranks everyone together or per country.
const SCOPE_GLOBAL := 0
const SCOPE_COUNTRY := 1


# Which window of a board to read — a window *key*, not the board's window type. `never`/`weekly`/`seasonal`
# describe how a board buckets and are never sent here.
# The window is passed as its wire string; "" is the live window (all-time, current week, or current season).
static func window_current() -> String:
	return ""

static func window_season(season_id: String) -> String:
	return "season:" + season_id

static func window_period(period_key: String) -> String:
	return period_key


static func value_type_to_wire(value_type: int) -> String:
	match value_type:
		VALUE_TYPE_INTEGER:
			return "integer"
		VALUE_TYPE_FLOAT:
			return "float"
		VALUE_TYPE_DURATION_SECONDS:
			return "duration"
		_:
			return "integer"

static func value_type_from_wire(wire: String) -> int:
	match wire:
		"float":
			return VALUE_TYPE_FLOAT
		"duration":
			return VALUE_TYPE_DURATION_SECONDS
		_:
			return VALUE_TYPE_INTEGER

static func direction_to_wire(direction: int) -> String:
	return "lower" if direction == DIRECTION_LOWER else "higher"

static func direction_from_wire(wire: String) -> int:
	return DIRECTION_LOWER if wire == "lower" else DIRECTION_HIGHER

static func aggregation_to_wire(aggregation: int) -> String:
	match aggregation:
		AGGREGATION_LATEST:
			return "latest"
		AGGREGATION_SUM:
			return "sum"
		_:
			return "best"

static func aggregation_from_wire(wire: String) -> int:
	match wire:
		"latest":
			return AGGREGATION_LATEST
		"sum":
			return AGGREGATION_SUM
		_:
			return AGGREGATION_BEST

static func window_type_to_wire(window_type: int) -> String:
	match window_type:
		WINDOW_TYPE_WEEKLY:
			return "weekly"
		WINDOW_TYPE_SEASONAL:
			return "seasonal"
		_:
			return "never"

static func window_type_from_wire(wire: String) -> int:
	match wire:
		"weekly":
			return WINDOW_TYPE_WEEKLY
		"seasonal":
			return WINDOW_TYPE_SEASONAL
		_:
			return WINDOW_TYPE_NEVER

static func scope_to_wire(scope: int) -> String:
	return "country" if scope == SCOPE_COUNTRY else "global"

static func scope_from_wire(wire: String) -> int:
	return SCOPE_COUNTRY if wire == "country" else SCOPE_GLOBAL


# Normalizes a board's public configuration, mapping the wire strings to local enums. The player-data field it
# projects over is deliberately not exposed.
static func parse_leaderboard(data: Dictionary) -> Dictionary:
	var value_type := value_type_from_wire(str(data.get("value_type", "")))
	var direction := direction_from_wire(str(data.get("direction", "")))
	var aggregation := aggregation_from_wire(str(data.get("aggregation", "")))
	var window_type := window_type_from_wire(str(data.get("window_type", "")))
	var scope := scope_from_wire(str(data.get("scope", "")))
	var board := {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"value_type": value_type,
		"value_type_wire": value_type_to_wire(value_type),
		"direction": direction,
		"direction_wire": direction_to_wire(direction),
		"aggregation": aggregation,
		"aggregation_wire": aggregation_to_wire(aggregation),
		"window_type": window_type,
		"window_type_wire": window_type_to_wire(window_type),
		"scope": scope,
		"scope_wire": scope_to_wire(scope),
	}
	return board


# True when a bigger number ranks better — sort and label from this instead of re-reading direction everywhere.
static func is_higher_better(board: Dictionary) -> bool:
	return board.get("direction", DIRECTION_HIGHER) == DIRECTION_HIGHER


# Formats a score the way this board measures. An unranked player's null score formats as empty.
static func format_score(board: Dictionary, score: Variant) -> String:
	if score == null or not (score is int or score is float):
		return ""
	var score_value := float(score)
	if not is_finite(score_value):
		return ""
	match board.get("value_type", VALUE_TYPE_INTEGER):
		VALUE_TYPE_DURATION_SECONDS:
			return format_duration(score_value)
		VALUE_TYPE_FLOAT:
			return format_float(score_value)
		_:
			return str(roundi(score_value))


# Seconds in, clock out: h:mm:ss.fff once past an hour, m:ss.fff below it.
static func format_duration(seconds: float) -> String:
	var negative := seconds < 0.0
	var total := absf(seconds)
	var hours := int(total) / 3600
	var minutes := int(total) / 60 % 60
	var secs := int(total) % 60
	var msec := int((total - floor(total)) * 1000.0) % 1000
	var text := ""
	if hours >= 1:
		text = "%d:%02d:%02d.%03d" % [hours, minutes, secs, msec]
	else:
		text = "%d:%02d.%03d" % [minutes, secs, msec]
	return "-" + text if negative else text


# "0.##" — up to two decimals, trailing zeros stripped.
static func format_float(value: float) -> String:
	var text := "%.2f" % value
	if text.find(".") != -1:
		text = text.rstrip("0")
		text = text.rstrip(".")
	return text