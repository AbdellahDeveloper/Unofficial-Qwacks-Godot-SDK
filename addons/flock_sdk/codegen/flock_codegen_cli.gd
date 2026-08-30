extends SceneTree

## Headless Flock config codegen entry point for CI / command line.
##
## Usage (from the project root):
##   godot --headless -s res://addons/flock_sdk/codegen/flock_codegen_cli.gd -- \
##       --api-url=https://api-flock.qwacks.com \
##       --api-key=<key> \
##       --game-version-id=<id> \
##       --out=res://flock/generated
##
## Options:
##   --api-url=...            API base URL (default: from user:// settings file)
##   --api-key=...            X-Flock-API-Key credential
##   --game-version-id=...    baked game version id
##   --game-version=...       game version NAME (resolved to its id first)
##   --out=...                generated output directory
##   --mode=sync|verify       sync = regenerate when the schema changed (default);
##                            verify = fetch, compare, write nothing
##   --force                  regenerate even when the hash is unchanged
##   --settings=path          settings .cfg to load defaults from
##
## Exit codes: 0 success / nothing to do, 1 could not run, 2 drift (verify only).

const DEFAULT_MODE := "sync"
const BANNER := "[Flock Config Codegen]"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exit_code := 1
	var settings := {}
	var args := _parse_args(OS.get_cmdline_user_args())

	var settings_path := str(args.get("settings", FlockConfigCodegen.DEFAULT_SETTINGS_PATH))
	settings = FlockConfigCodegen.load_settings(settings_path)
	# CLI flags win over the settings file.
	if args.has("api-url"):
		settings["api_url"] = args["api-url"]
	if args.has("api-key"):
		settings["api_key"] = args["api-key"]
	if args.has("game-version-id"):
		settings["game_version_id"] = args["game-version-id"]
	if args.has("output-dir") or args.has("out"):
		settings["output_dir"] = str(args.get("output-dir", args.get("out", "")))
	if args.has("game-version"):
		settings["game_version"] = args["game-version"]

	var mode := str(args.get("mode", DEFAULT_MODE)).to_lower()
	var force := bool(args.get("force", false))

	if mode == "verify":
		exit_code = await _verify(settings, force)
	else:
		exit_code = await _sync(settings, force)
	quit(exit_code)


func _sync(settings: Dictionary, force: bool) -> int:
	if not _validate(settings):
		return 1

	var api_url := str(settings.get("api_url", "")).strip_edges().trim_suffix("/")
	var api_key := str(settings.get("api_key", ""))
	var game_version_id := str(settings.get("game_version_id", ""))

	# A version NAME alone is enough: resolve it the way the editor does.
	if game_version_id.is_empty() and not str(settings.get("game_version", "")).is_empty():
		print("%s Resolving game version '%s'..." % [BANNER, settings.get("game_version")])
		var resolved = await FlockConfigCodegen.resolve_game_version_id_async(api_url, api_key, str(settings.get("game_version", "")))
		if resolved.has("error"):
			print("%s %s" % [BANNER, resolved.get("error")])
			return 1
		game_version_id = str(resolved.get("game_version_id", ""))

	var result = await FlockConfigCodegen.generate_async(api_url, api_key, game_version_id, str(settings.get("output_dir", "")), force)
	if result.has("error"):
		print("%s %s" % [BANNER, result.get("error")])
		return 1

	if result.get("status") == "up_to_date":
		print("%s Up to date - schema hash %s unchanged since last sync." % [BANNER, result.get("content_hash")])
		return 0

	print("%s Generated %d config accessor(s) (%d skipped) into %s." % [
		BANNER, result.get("emitted", 0), result.get("skipped", 0), result.get("output_dir")])
	print("%s   game_version_id=%s" % [BANNER, result.get("game_version_id")])
	print("%s   content_hash=%s" % [BANNER, result.get("content_hash")])
	if result.get("was_in_sync", false):
		print("%s   (--force used: regenerated identical snapshot)" % BANNER)
	elif result.get("previous_hash", "") != "":
		print("%s   previous_hash=%s" % [BANNER, result.get("previous_hash")])
	return 0


func _verify(settings: Dictionary, _force: bool) -> int:
	if not _validate(settings):
		return 1

	var api_url := str(settings.get("api_url", "")).strip_edges().trim_suffix("/")
	var api_key := str(settings.get("api_key", ""))
	var game_version_id := str(settings.get("game_version_id", ""))
	print("%s Verify: fetching configs for game_version_id=%s ..." % [BANNER, game_version_id])

	var snapshot = await FlockConfigCodegen.fetch_snapshot_async(api_url, api_key, game_version_id)
	if snapshot.has("error"):
		print("%s %s" % [BANNER, snapshot.get("error")])
		return 1

	var drift := FlockConfigCodegen.check_drift(snapshot, str(settings.get("output_dir", "")))
	var manifest := drift.get("manifest", {})
	if not manifest.get("exists", false):
		print("%s Drift: no generated manifest at %s. Run sync and commit the output." % [BANNER, settings.get("output_dir")])
		return 2
	if str(manifest.get("game_version_id", "")) != str(drift.get("game_version_id", "")):
		print("%s Drift: generated code is for game_version_id='%s' but the backend now reports '%s'. Run sync and commit." % [
			BANNER, manifest.get("game_version_id"), drift.get("game_version_id")])
		return 2
	if str(manifest.get("content_hash", "")) != str(drift.get("content_hash", "")):
		print("%s Drift: backend schema content changed (fields/types/tags) since the committed code was generated. Run sync and commit." % BANNER)
		print("%s   committed=%s" % [BANNER, manifest.get("content_hash")])
		print("%s   backend =%s" % [BANNER, drift.get("content_hash")])
		return 2

	print("%s Verify OK - generated configs match backend (content hash %s)." % [BANNER, drift.get("content_hash")])
	return 0


func _validate(settings: Dictionary) -> bool:
	var api_url := str(settings.get("api_url", "")).strip_edges()
	var api_key := str(settings.get("api_key", ""))
	var game_version := str(settings.get("game_version", ""))
	var game_version_id := str(settings.get("game_version_id", ""))
	if api_url.is_empty() or api_key.is_empty():
		print("%s Missing credentials. Pass --api-url and --api-key (or save them from the Flock Initializer window)." % BANNER)
		return false
	if game_version_id.is_empty() and game_version.is_empty():
		print("%s Missing game version. Pass --game-version-id (baked) or --game-version (name)." % BANNER)
		return false
	return true


func _parse_args(raw: Array) -> Dictionary:
	var args := {}
	for piece in raw:
		var text := str(piece)
		if text.begins_with("--"):
			text = text.substr(2)
		var parts := text.split("=", true, 1)
		var value: Variant = true
		if parts.size() > 1:
			value = parts[1]
		args[parts[0]] = value
	return args