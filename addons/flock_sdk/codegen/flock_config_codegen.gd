class_name FlockConfigCodegen
extends RefCounted

## Shared core for the Flock Initializer editor window and the headless CLI.
## Mirrors the C# SDK's Editor/Codegen pipeline (SchemaFetcher + SchemaHasher +
## GameConfigEmitter + ConfigAccessorEmitter) for Godot's GDScript + exported
## global classes. Fetch -> stable content hash -> emit typed accessors.

const DEFAULT_OUTPUT_DIR := "res://flock/generated"
const DEFAULT_SETTINGS_PATH := "user://flock_initializer.cfg"
const MANIFEST_FILENAME := "flock_manifest.cfg"
const SETTINGS_SECTION := "flock_initializer"

###############################################################################
# Fetch
###############################################################################

## Loads the game configs for a game version and parses them the same way the
## player-facing provider does. Headers match the C# SchemaFetcher.
static func fetch_snapshot_async(api_url: String, api_key: String, game_version_id: String) -> Dictionary:
	var base_url := _str(api_url).strip_edges().trim_suffix("/")
	if base_url.is_empty():
		return {"error": "API URL is required"}
	if _str(api_key).is_empty():
		return {"error": "API Key is required"}
	if _str(game_version_id).is_empty():
		return {"error": "Game Version ID is required"}

	var url := "%s/v1/%s" % [base_url, FlockEndpoints.GAME_CONFIG_VERSION]
	var result: Variant = await FlockHttpClient.get_async(url, {
		"X-Flock-API-Key": api_key,
		"X-Game-Version-ID": game_version_id,
	})

	if result is Dictionary and result.has("error"):
		return {"error": "Fetch failed: %s" % str(result.get("error", "unknown"))}
	if not result is Array:
		return {"error": "Unexpected response shape: %s" % str(typeof(result))}

	var configs := []
	for entry in result:
		if not entry is Dictionary:
			continue
		configs.append(GameConfigModels.parse_game_config(entry))

	return {
		"game_version_id": game_version_id,
		"configs": configs,
		"fetched_at": Time.get_datetime_string_from_system(true, true),
	}


## Resolves a game version NAME to its ID, exactly like the C# editor's
## "Resolve Game Version" (GET /v1/game_version/by-name/{name}).
static func resolve_game_version_id_async(api_url: String, api_key: String, game_version: String) -> Dictionary:
	var base_url := _str(api_url).strip_edges().trim_suffix("/")
	if base_url.is_empty():
		return {"error": "API URL is required"}
	if _str(api_key).is_empty():
		return {"error": "API Key is required"}
	if _str(game_version).is_empty():
		return {"error": "Game Version is required"}

	var url := "%s/v1/%s" % [base_url, FlockEndpoints.game_version_by_name(game_version)]
	var result: Variant = await FlockHttpClient.get_async(url, {"X-Flock-API-Key": api_key})

	if result is Dictionary and result.has("error"):
		return {"error": "Resolve failed: %s" % str(result.get("error", "unknown"))}
	if not result is Dictionary:
		return {"error": "Unexpected response shape for game version resolve"}
	var id := str(result.get("id", ""))
	if id.is_empty():
		return {"error": "Server did not return an id for game version '%s'" % game_version}
	return {"game_version_id": id, "game_version": game_version}


###############################################################################
# Content hash (mirrors C# SchemaHasher, configs scope)
###############################################################################

## Stable SHA-256 fingerprint of the schema content that drives codegen output.
## Changes iff the generated code would change, so a same-version dashboard edit
## is detectable even when the GameVersionId is unchanged. Reordering the
## server response does NOT read as drift (configs are sorted first).
static func compute_content_hash(configs: Array) -> String:
	var sorted := sort_configs(configs)
	var sb := ""
	for cfg in sorted:
		sb += "C"
		sb += _len_string(str(cfg.get("id", "")))
		sb += _len_string(str(cfg.get("name", "")))
		sb += _len_string(str(cfg.get("tag", "")))
		sb += _fields_string(cfg.get("schema", []))
	return sb.sha256_text()


static func sort_configs(configs: Array) -> Array:
	var sorted := configs.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var aid := str(a.get("id", ""))
		var bid := str(b.get("id", ""))
		if aid != bid:
			return aid < bid
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	return sorted


static func _len_string(value: String) -> String:
	return "%d:%s" % [value.length(), value]


static func _fields_string(fields: Variant) -> String:
	var sb := "["
	if fields is Array:
		for field in fields:
			if not field is Dictionary:
				sb += "~"
				continue
			sb += "F"
			sb += _len_string(str((field as Dictionary).get("type", "")))
			sb += _len_string(str((field as Dictionary).get("field_name", "")))
			sb += _len_string(str((field as Dictionary).get("type_name", "")))
			# Field order (incl. nested children) is preserved: a reorder is a real output change.
			var child: Variant = (field as Dictionary).get("schema", null)
			if child is Array:
				sb += _fields_string(child)
			elif child is Dictionary:
				sb += _fields_string([child])
			else:
				sb += "[]"
	sb += "]"
	return sb


###############################################################################
# Type mapping (mirrors C# TypeMap)
###############################################################################

## Maps a primitive type string from the typed schema to a GDScript type.
## Optional fields arrive as "datetime?" / "integer?" - the marker is stripped;
## GDScript has no nullability annotations, so it only affects nothing.
static func map_field_type(type_string: String) -> String:
	var normalized := _str(type_string).strip_edges().to_lower()
	if normalized.ends_with("?"):
		normalized = normalized.substr(0, normalized.length() - 1).strip_edges()
	match normalized:
		"string":
			return "String"
		"integer", "int", "long", "int64":
			return "int"
		"float", "number", "double":
			return "float"
		"boolean", "bool":
			return "bool"
		"datetime", "date", "timestamp":
			return "String"
		"object":
			return "Dictionary"
		"list", "array":
			return "Array"
		"dict":
			return "Dictionary"
		_:
			return "Variant"


static func default_literal(gd_type: String) -> String:
	match gd_type:
		"int":
			return "0"
		"float":
			return "0.0"
		"bool":
			return "false"
		"Dictionary":
			return "{}"
		"Array":
			return "[]"
		"String", "Variant":
			return "\"\""
		_:
			return "null"


###############################################################################
# Naming helpers (mirrors C# CodeGenNamingHelpers)
###############################################################################

static func to_snake_case(text: String) -> String:
	if _str(text).is_empty():
		return "unnamed_field"
	var out := ""
	var prev_lower := false
	for i in text.length():
		var c := text[i]
		if _is_upper(c):
			if not out.is_empty() and prev_lower:
				out += "_"
			out += c.to_lower()
			prev_lower = false
		elif _is_lower(c) or _is_digit(c) or c == "_":
			out += c
			prev_lower = true
		else:
			out += "_"
			prev_lower = false
	if out.is_empty():
		out = "unnamed_field"
	if _is_digit(out[0]):
		out = "_" + out
	return out


static func to_pascal_case(text: String) -> String:
	var out := ""
	var next_upper := true
	for i in _str(text).length():
		var c := text[i]
		if _is_upper(c) or _is_lower(c) or _is_digit(c):
			out += c.to_upper() if next_upper else c
			next_upper = false
		else:
			next_upper = true
	if out.is_empty():
		out = "Unnamed"
	if _is_digit(out[0]):
		out = "_" + out
	return out


## Class/property names must be global-unique and deterministic. If a generated
## identifier collides (two dashboards entries producing the same name) the
## second gets a "_2" suffix, mirroring C# UnDuplicate.
static func un_duplicate(base: String, used: Dictionary) -> String:
	if not used.get(base, false):
		used[base] = true
		return base
	var i := 2
	while used.get("%s_%d" % [base, i], false):
		i += 1
	var deduped := "%s_%d" % [base, i]
	used[deduped] = true
	push_warning("[Flock Codegen] Two entries both generate '%s'; emitting '%s'. Rename one in the dashboard to keep generated names stable." % [base, deduped])
	return deduped


static func escape_string_literal(text: String) -> String:
	var out := ""
	for i in _str(text).length():
		match text[i]:
			"\\":
				out += "\\\\"
			"\"":
				out += "\\\""
			"\n":
				out += "\\n"
			"\r":
				out += "\\r"
			"\t":
				out += "\\t"
			_:
				out += text[i]
	return out


## Values that go in a line comment: newlines and raw control chars would break
## the comment, so collapse them (mirrors C# SanitizeForLineComment).
static func sanitize_line_comment(text: String) -> String:
	var out := ""
	for i in _str(text).length():
		var c := text[i]
		if c == "\r" or c == "\n":
			out += " "
		elif c < " ":
			out += "?"
		else:
			out += c
	return out


static func _is_upper(c: String) -> bool:
	return c >= "A" and c <= "Z"


static func _is_lower(c: String) -> bool:
	return c >= "a" and c <= "z"


static func _is_digit(c: String) -> bool:
	return c >= "0" and c <= "9"


###############################################################################
# Manifest
###############################################################################

## Reads the last-sync manifest written under the output dir. Returns
## {"exists": false} when nothing has been generated yet.
static func read_manifest(output_dir: String) -> Dictionary:
	var path := "%s/%s" % [output_dir, MANIFEST_FILENAME]
	if not FileAccess.file_exists(path):
		return {"exists": false}
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return {"exists": false}
	return {
		"exists": true,
		"game_version_id": str(cf.get_value(SETTINGS_SECTION, "game_version_id", "")),
		"content_hash": str(cf.get_value(SETTINGS_SECTION, "content_hash", "")),
	}


## Compares a fetched snapshot against what's on disk. Returns the newly
## computed hash and whether regeneration is needed (missing manifest, different
## game version, or different content).
static func check_drift(snapshot: Dictionary, output_dir: String) -> Dictionary:
	var hash := compute_content_hash(snapshot.get("configs", []))
	var version := str(snapshot.get("game_version_id", ""))
	var manifest := read_manifest(output_dir)
	return {
		"in_sync": manifest.exists
			and str(manifest.get("game_version_id", "")) == version
			and str(manifest.get("content_hash", "")) == hash,
		"content_hash": hash,
		"game_version_id": version,
		"manifest": manifest,
	}


static func _write_manifest(output_dir: String, game_version_id: String, content_hash: String) -> void:
	var cf := ConfigFile.new()
	cf.set_value(SETTINGS_SECTION, "game_version_id", game_version_id)
	cf.set_value(SETTINGS_SECTION, "content_hash", content_hash)
	cf.set_value(SETTINGS_SECTION, "generated_at", Time.get_datetime_string_from_system(true, true))
	# ConfigFile.save accepts res:// paths; write through UserDir-independent path handling for emit.
	cf.save(_abs_path("%s/%s" % [output_dir, MANIFEST_FILENAME]))


###############################################################################
# Settings (shared between editor window and CLI)
###############################################################################

static func load_settings(path: String) -> Dictionary:
	var out := {"api_url": "", "api_key": "", "game_version": "", "game_version_id": "", "output_dir": DEFAULT_OUTPUT_DIR}
	var cf := ConfigFile.new()
	if cf.load(path) == OK:
		for key in out:
			out[key] = str(cf.get_value(SETTINGS_SECTION, key, out[key]))
	if _str(out.get("output_dir")).is_empty():
		out["output_dir"] = DEFAULT_OUTPUT_DIR
	return out


static func save_settings(path: String, settings: Dictionary) -> void:
	var cf := ConfigFile.new()
	for key in settings:
		cf.set_value(SETTINGS_SECTION, key, settings[key])
	cf.save(path)


###############################################################################
# Emission
###############################################################################

## Wipes the output dir, emits one typed .gd per config plus the static accessor
## class, and records the manifest. Sorting is deterministic so file output and
## the content hash always agree.
static func emit_snapshot(snapshot: Dictionary, output_dir: String) -> Dictionary:
	var version_id := str(snapshot.get("game_version_id", ""))
	var configs := sort_configs(snapshot.get("configs", []))
	_reset_dir(output_dir)

	var content_hash := compute_content_hash(configs)
	var used_class_names := {}
	var entries := []
	var emitted := 0
	var skipped := 0
	for cfg in configs:
		var schema: Array = cfg.get("schema", [])
		if schema.size() == 0:
			push_warning("[Flock Codegen] GameConfig '%s' (id=%s) has no schema; skipping." % [_display(str(cfg.get("name", "")), cfg), str(cfg.get("id", ""))])
			skipped += 1
			continue
		var cls_name := un_duplicate(to_pascal_case(str(cfg.get("name", ""))) + "Config", used_class_names)
		var source := _build_config_source(cfg, cls_name, content_hash)
		_write_file(output_dir, "%s.gd" % cls_name, source)
		entries.append({
			"name": str(cfg.get("name", "")),
			"class_name": cls_name,
			"snake": to_snake_case(str(cfg.get("name", ""))),
		})
		emitted += 1

	_write_file(output_dir, "flock_config_accessors.gd", _build_accessors_source(entries, version_id))
	_write_manifest(output_dir, version_id, content_hash)

	return {
		"status": "generated",
		"game_version_id": version_id,
		"content_hash": content_hash,
		"configs": configs.size(),
		"emitted": emitted,
		"skipped": skipped,
		"output_dir": output_dir,
	}


## Fetch -> drift check -> generate only when the schema actually changed (or
## force). This is the one entry point both the editor window and the CLI call.
static func generate_async(api_url: String, api_key: String, game_version_id: String, output_dir: String, force: bool = false) -> Dictionary:
	var snapshot = await fetch_snapshot_async(api_url, api_key, game_version_id)
	if snapshot.has("error"):
		return snapshot
	var drift := check_drift(snapshot, output_dir)
	if not force and drift["in_sync"]:
		return {
			"status": "up_to_date",
			"game_version_id": drift["game_version_id"],
			"content_hash": drift["content_hash"],
			"output_dir": output_dir,
		}
	var emitted := emit_snapshot(snapshot, output_dir)
	emitted["was_in_sync"] = drift["in_sync"]
	emitted["previous_hash"] = str(drift["manifest"].get("content_hash", "")) if drift["manifest"].get("exists", false) else ""
	return emitted


static func _display(name: String, cfg: Dictionary) -> String:
	return name if not _str(name).is_empty() else "unnamed(%s)" % str(cfg.get("id", "?"))


static func _build_config_source(config: Dictionary, cls_name: String, content_hash: String) -> String:
	var id := str(config.get("id", ""))
	var name := str(config.get("name", ""))
	var tag := str(config.get("tag", ""))
	var schema: Array = config.get("schema", [])

	var lines := PackedStringArray()
	lines.append("## Auto-generated by Flock Config Codegen. Do not edit by hand.")
	lines.append("## Source: %s" % sanitize_line_comment("GameConfig id=%s name=%s tag=%s" % [id, name, tag]))
	lines.append("class_name %s" % cls_name)
	lines.append("extends RefCounted")
	lines.append("")
	lines.append("## Backend schema id of this config.")
	lines.append("const FLOCK_SCHEMA_ID := %s" % _quote(id))
	lines.append("## Display name on the dashboard.")
	lines.append("const FLOCK_SCHEMA_NAME := %s" % _quote(name))
	lines.append("## Content hash of the schema this file was generated from.")
	lines.append("const FLOCK_SCHEMA_HASH := %s" % _quote(content_hash))
	lines.append("")
	lines.append("var _data: Dictionary = {}")
	lines.append("")
	lines.append("func _init(data: Dictionary = {}) -> void:")
	lines.append("\t_data = data")
	lines.append("")

	var used_props := {}
	for field in schema:
		if not field is Dictionary:
			continue
		var field_name := str((field as Dictionary).get("field_name", ""))
		if field_name.is_empty():
			continue
		var type_string := str((field as Dictionary).get("type", ""))
		var gd_type := map_field_type(type_string)
		var prop_name := un_duplicate(to_snake_case(field_name), used_props)
		lines.append("## Field '%s' (type %s)." % [sanitize_line_comment(field_name), sanitize_line_comment(_str(type_string).strip_edges())])
		lines.append("var %s: %s:" % [prop_name, gd_type])
		lines.append("\tget:")
		lines.append("\t\treturn _data.get(%s, %s)" % [_quote(field_name), default_literal(gd_type)])
		lines.append("")

	lines.append("")
	return "\n".join(lines)


static func _build_accessors_source(entries: Array, game_version_id: String) -> String:
	var lines := PackedStringArray()
	lines.append("## Auto-generated by Flock Config Codegen. Do not edit by hand.")
	lines.append("## Static, typed accessors for the game configs of game version id=%s." % game_version_id)
	lines.append("## Requires the SDK to be initialized (FlockClient.create) with the same")
	lines.append("## credentials the tool ran with.")
	lines.append("class_name FlockConfigAccessors")
	lines.append("extends RefCounted")
	lines.append("")

	var used := {}
	for entry in entries:
		var snake := un_duplicate(str(entry.get("snake", "")), used)
		var cls_name := str(entry.get("class_name", ""))
		lines.append("## Fetches '%s' and wraps it as a typed %s." % [sanitize_line_comment(str(entry.get("name", ""))), cls_name])
		lines.append("static func get_%s_async(client: FlockClient = null) -> %s:" % [snake, cls_name])
		lines.append("\tif client == null:")
		lines.append("\t\tclient = FlockClient.get_instance()")
		lines.append("\tif client == null or not FlockClient.is_initialized:")
		lines.append("\t\tpush_error(\"[Flock Configs] SDK is not initialized.\")")
		lines.append("\t\treturn null")
		lines.append("\tvar result: Variant = await client.config.get_game_config_by_name(%s)" % _quote(str(entry.get("name", ""))))
		lines.append("\tif result is Dictionary and result.has(\"error\"):")
		lines.append("\t\tpush_error(\"[Flock Configs] fetch of \" + %s + \" failed: \" + str(result.get(\"error\", \"unknown\")))" % _quote(str(entry.get("name", ""))))
		lines.append("\t\treturn null")
		lines.append("\tvar parsed := GameConfigModels.parse_game_config(result)")
		lines.append("\tvar data := GameConfigModels.get_data_as(parsed.get(\"data\", []))")
		lines.append("\treturn %s.new(data)" % cls_name)
		lines.append("")

	lines.append("")
	return "\n".join(lines)


static func _quote(text: String) -> String:
	return "\"" + escape_string_literal(_str(text)) + "\""


###############################################################################
# Filesystem helpers
###############################################################################

## Null-safe string coercion: GDScript's `or` returns bool, so the Python-style
## `(value or "")` idiom is not available.
static func _str(value: Variant) -> String:
	return "" if value == null else str(value)


static func _abs_path(path: String) -> String:
	return ProjectSettings.globalize_path(path)


static func _reset_dir(dir: String) -> void:
	var abs := _abs_path(dir)
	_remove_recursive_abs(abs)
	DirAccess.make_dir_recursive_absolute(abs)


## DirAccess.remove_absolute only deletes EMPTY directories, so a stale generated
## folder (files from a previous sync) would otherwise survive regeneration.
static func _remove_recursive_abs(abs: String) -> void:
	if not DirAccess.dir_exists_absolute(abs):
		return
	var dir := DirAccess.open(abs)
	if dir == null:
		return
	for f in dir.get_files():
		DirAccess.remove_absolute("%s/%s" % [abs, f])
	for sub in dir.get_directories():
		_remove_recursive_abs("%s/%s" % [abs, sub])
	DirAccess.remove_absolute(abs)


static func _write_file(dir: String, filename: String, content: String) -> void:
	var abs := _abs_path(dir)
	var f := FileAccess.open("%s/%s" % [abs, filename], FileAccess.WRITE)
	if f == null:
		push_error("[Flock Codegen] Could not write %s: %s" % [filename, error_string(FileAccess.get_open_error())])
		return
	f.store_string(content)
	f.close()