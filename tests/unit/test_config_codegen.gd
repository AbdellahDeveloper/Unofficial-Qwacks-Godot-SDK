extends GutTest

const TMP_DIR := "user://config_codegen_test_tmp"

var _out_dir := ""


func before_each() -> void:
	_out_dir = "%s/%d" % [TMP_DIR, OS.get_process_id()]
	_remove_dir(_out_dir)


func after_each() -> void:
	_remove_dir(_out_dir)


func _remove_dir(dir: String) -> void:
	var abs := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(abs):
		return
	var d := DirAccess.open(abs)
	if d:
		for f in d.get_files():
			DirAccess.remove_absolute("%s/%s" % [abs, f])
		for sub in d.get_directories():
			_remove_dir("%s/%s" % [dir, sub])
	DirAccess.remove_absolute(abs)


func _config(id: String, name: String, tag: String, schema: Array) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"game_id": "game",
		"game_version_id": "version",
		"schema": schema,
		"data": [],
		"tag": tag,
		"created_at": "",
		"updated_at": "",
	}


func _field(type: String, field_name: String, children: Variant = null) -> Dictionary:
	var f := {"type": type, "field_name": field_name, "type_name": ""}
	if children != null:
		f["schema"] = children
	return f


###############################################################################
# Naming
###############################################################################

func test_snake_case() -> void:
	assert_eq(FlockConfigCodegen.to_snake_case("BaseMoveSpeed"), "base_move_speed")
	assert_eq(FlockConfigCodegen.to_snake_case("The highest time"), "the_highest_time")
	assert_eq(FlockConfigCodegen.to_snake_case("InventorySlotId"), "inventory_slot_id")
	assert_eq(FlockConfigCodegen.to_snake_case("playerId"), "player_id")
	assert_eq(FlockConfigCodegen.to_snake_case("with space"), "with_space")
	assert_eq(FlockConfigCodegen.to_snake_case("dash-name"), "dash_name")
	assert_eq(FlockConfigCodegen.to_snake_case("field123"), "field123")
	assert_eq(FlockConfigCodegen.to_snake_case(""), "unnamed_field")
	assert_eq(FlockConfigCodegen.to_snake_case("1st"), "_1st")


func test_pascal_case() -> void:
	assert_eq(FlockConfigCodegen.to_pascal_case("The highest time"), "TheHighestTime")
	assert_eq(FlockConfigCodegen.to_pascal_case("player_id"), "PlayerId")
	assert_eq(FlockConfigCodegen.to_pascal_case("base-move-speed"), "BaseMoveSpeed")
	assert_eq(FlockConfigCodegen.to_pascal_case(""), "Unnamed")
	assert_eq(FlockConfigCodegen.to_pascal_case("9lives"), "_9lives")


func test_un_duplicate() -> void:
	var used := {}
	assert_eq(FlockConfigCodegen.un_duplicate("Foo", used), "Foo")
	assert_eq(FlockConfigCodegen.un_duplicate("Foo", used), "Foo_2")
	assert_eq(FlockConfigCodegen.un_duplicate("Foo", used), "Foo_3")
	assert_eq(FlockConfigCodegen.un_duplicate("Bar", used), "Bar")


func test_escape_string_literal() -> void:
	assert_eq(FlockConfigCodegen.escape_string_literal("a\"b"), "a\\\"b")
	assert_eq(FlockConfigCodegen.escape_string_literal("a\\b"), "a\\\\b")
	assert_eq(FlockConfigCodegen.escape_string_literal("a\nb"), "a\\nb")
	assert_eq(FlockConfigCodegen.escape_string_literal("plain"), "plain")


func test_sanitize_line_comment() -> void:
	assert_eq(FlockConfigCodegen.sanitize_line_comment("a\nb"), "a b")
	assert_eq(FlockConfigCodegen.sanitize_line_comment("x\r\ny"), "x  y")
	assert_eq(FlockConfigCodegen.sanitize_line_comment("a\tb"), "a?b")


###############################################################################
# Type mapping
###############################################################################

func test_map_field_type() -> void:
	assert_eq(FlockConfigCodegen.map_field_type("string"), "String")
	assert_eq(FlockConfigCodegen.map_field_type("String"), "String")
	assert_eq(FlockConfigCodegen.map_field_type("integer?"), "int")
	assert_eq(FlockConfigCodegen.map_field_type("int"), "int")
	assert_eq(FlockConfigCodegen.map_field_type("float"), "float")
	assert_eq(FlockConfigCodegen.map_field_type("double"), "float")
	assert_eq(FlockConfigCodegen.map_field_type("bool"), "bool")
	assert_eq(FlockConfigCodegen.map_field_type("datetime?"), "String")
	assert_eq(FlockConfigCodegen.map_field_type("list"), "Array")
	assert_eq(FlockConfigCodegen.map_field_type("array"), "Array")
	assert_eq(FlockConfigCodegen.map_field_type("object"), "Dictionary")
	assert_eq(FlockConfigCodegen.map_field_type("dict"), "Dictionary")
	assert_eq(FlockConfigCodegen.map_field_type("mystery"), "Variant")


func test_default_literal() -> void:
	assert_eq(FlockConfigCodegen.default_literal("int"), "0")
	assert_eq(FlockConfigCodegen.default_literal("float"), "0.0")
	assert_eq(FlockConfigCodegen.default_literal("bool"), "false")
	assert_eq(FlockConfigCodegen.default_literal("String"), "\"\"")
	assert_eq(FlockConfigCodegen.default_literal("Dictionary"), "{}")
	assert_eq(FlockConfigCodegen.default_literal("Array"), "[]")
	assert_eq(FlockConfigCodegen.default_literal("Variant"), "\"\"")
	assert_eq(FlockConfigCodegen.default_literal("nope"), "null")


###############################################################################
# Content hash
###############################################################################

func test_hash_stable_and_order_independent() -> void:
	var a := _config("a1", "Alpha", "gameplay", [_field("float", "BaseMoveSpeed")])
	var b := _config("b2", "Beta", "", [_field("integer?", "MaxLives")])
	assert_eq(
		FlockConfigCodegen.compute_content_hash([a, b]),
		FlockConfigCodegen.compute_content_hash([b, a]),
		"config list reorder must not read as drift")


func test_hash_changes_when_field_type_changes() -> void:
	var base := _config("a1", "Alpha", "", [_field("float", "Speed")])
	var changed := _config("a1", "Alpha", "", [_field("integer", "Speed")])
	assert_ne(
		FlockConfigCodegen.compute_content_hash([base]),
		FlockConfigCodegen.compute_content_hash([changed]),
		"type change must change the hash")


func test_hash_changes_when_field_name_changes() -> void:
	var base := _config("a1", "Alpha", "", [_field("string", "name")])
	var changed := _config("a1", "Alpha", "", [_field("string", "title")])
	assert_ne(
		FlockConfigCodegen.compute_content_hash([base]),
		FlockConfigCodegen.compute_content_hash([changed]))


func test_hash_changes_on_nested_schema() -> void:
	var no_children := _config("a1", "Alpha", "", [_field("list", "Items")])
	var with_children := _config("a1", "Alpha", "", [_field("list", "Items", [_field("string", "item_name")])])
	assert_ne(
		FlockConfigCodegen.compute_content_hash([no_children]),
		FlockConfigCodegen.compute_content_hash([with_children]),
		"adding list children must change the hash")


func test_hash_changes_when_config_added() -> void:
	var a := _config("a1", "Alpha", "", [_field("string", "name")])
	var b := _config("b2", "Beta", "", [_field("string", "name")])
	assert_ne(
		FlockConfigCodegen.compute_content_hash([a]),
		FlockConfigCodegen.compute_content_hash([a, b]))


func test_hash_length() -> void:
	var hash := FlockConfigCodegen.compute_content_hash([_config("a1", "Alpha", "", [_field("float", "Speed")])])
	assert_eq(hash.length(), 64, "sha256 hex is 64 chars")


###############################################################################
# Emit + manifest + regeneration
###############################################################################

var _gameplay_schema := [
	_field("float", "BaseMoveSpeed"),
	_field("string", "PlayerName"),
	_field("list", "InventoryItems", [_field("string", "item_name")]),
]


func test_emit_writes_files_and_manifest() -> void:
	var snapshot := {
		"game_version_id": "version-1",
		"configs": [_config("c1", "Gameplay", "gameplay", _gameplay_schema)],
	}
	var result := FlockConfigCodegen.emit_snapshot(snapshot, _out_dir)
	assert_eq(result.get("emitted"), 1)
	assert_true(FileAccess.file_exists(_out_dir + "/GameplayConfig.gd"))
	assert_true(FileAccess.file_exists(_out_dir + "/flock_config_accessors.gd"))
	assert_true(FileAccess.file_exists(_out_dir + "/flock_manifest.cfg"))

	var manifest := FlockConfigCodegen.read_manifest(_out_dir)
	assert_true(manifest.get("exists", false))
	assert_eq(manifest.get("game_version_id"), "version-1")
	assert_eq(manifest.get("content_hash"), result.get("content_hash"))


func test_generated_source_shape() -> void:
	var snapshot := {
		"game_version_id": "version-1",
		"configs": [_config("c1", "Gameplay", "gameplay", _gameplay_schema)],
	}
	var result := FlockConfigCodegen.emit_snapshot(snapshot, _out_dir)
	var source := FileAccess.get_file_as_string(_out_dir + "/GameplayConfig.gd")
	assert_true(source.contains("class_name GameplayConfig"))
	assert_true(source.contains("extends RefCounted"))
	assert_true(source.contains("const FLOCK_SCHEMA_HASH := \"%s\"" % result.get("content_hash")))
	assert_true(source.contains("var base_move_speed: float:"))
	assert_true(source.contains("var player_name: String"))
	assert_true(source.contains("var inventory_items: Array"))
	assert_true(source.contains("_data.get(\"BaseMoveSpeed\", 0.0)"))

	var accessors := FileAccess.get_file_as_string(_out_dir + "/flock_config_accessors.gd")
	assert_true(accessors.contains("class_name FlockConfigAccessors"))
	assert_true(accessors.contains("static func get_gameplay_async(client: FlockClient = null) -> GameplayConfig:"))
	assert_true(accessors.contains("client.config.get_game_config_by_name(\"Gameplay\")"))
	assert_true(accessors.contains(
		"push_error(\"[Flock Configs] fetch of \" + \"Gameplay\" + \" failed: \" + str(result.get(\"error\", \"unknown\")))"))


func test_drift_detects_schema_change() -> void:
	var snapshot := {
		"game_version_id": "version-1",
		"configs": [_config("c1", "Gameplay", "gameplay", _gameplay_schema)],
	}
	FlockConfigCodegen.emit_snapshot(snapshot, _out_dir)
	var drift := FlockConfigCodegen.check_drift(snapshot, _out_dir)
	assert_true(drift.get("in_sync"), "identical snapshot is up to date")

	var changed_schema := [_field("integer", "BaseMoveSpeed")]
	var changed := {
		"game_version_id": "version-1",
		"configs": [_config("c1", "Gameplay", "gameplay", changed_schema)],
	}
	var drift2 := FlockConfigCodegen.check_drift(changed, _out_dir)
	assert_false(drift2.get("in_sync"), "changed schema needs regeneration")


func test_drift_detects_version_change() -> void:
	var snapshot := {
		"game_version_id": "version-1",
		"configs": [_config("c1", "Gameplay", "gameplay", _gameplay_schema)],
	}
	FlockConfigCodegen.emit_snapshot(snapshot, _out_dir)
	var other_version := {
		"game_version_id": "version-2",
		"configs": [_config("c1", "Gameplay", "gameplay", _gameplay_schema)],
	}
	var drift := FlockConfigCodegen.check_drift(other_version, _out_dir)
	assert_false(drift.get("in_sync"), "different game version needs regeneration")


func test_drift_no_manifest() -> void:
	var snapshot := {
		"game_version_id": "version-1",
		"configs": [_config("c1", "Gameplay", "gameplay", _gameplay_schema)],
	}
	var drift := FlockConfigCodegen.check_drift(snapshot, _out_dir)
	assert_false(drift.get("in_sync"), "no manifest means regeneration is needed")
	assert_false(drift.get("manifest").get("exists", true))