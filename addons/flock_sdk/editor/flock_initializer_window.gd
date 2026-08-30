@tool
class_name FlockInitializerWindow
extends Window

## Editor-side "Flock Initializer": generate / regenerate typed game-config
## accessors from the live schema. Opens from Project > Tools > Flock Initializer.
## Works both in the running editor and headless (the CLI uses the same
## FlockConfigCodegen core and shares user://flock_initializer.cfg).

const DEFAULT_SIZE := Vector2i(600, 720)

var _api_url_edit: LineEdit
var _api_key_edit: LineEdit
var _game_version_edit: LineEdit
var _game_version_id_edit: LineEdit
var _output_dir_edit: LineEdit
var _force_check: CheckButton
var _status_label: Label
var _log: RichTextLabel
var _generate_button: Button
var _resolve_button: Button
var _busy := false


func _ready() -> void:
	title = "Flock Initializer"
	min_size = DEFAULT_SIZE
	close_requested.connect(_on_close_requested)
	_build_ui()
	_load_settings_into_fields()
	_refresh_status()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	var title_label := Label.new()
	title_label.text = "Flock Initializer"
	title_label.add_theme_font_size_override("font_size", 18)
	header.add_child(title_label)
	var subtitle := Label.new()
	subtitle.text = "Generate typed game-config accessors. Regenerates automatically when the schema hash changes."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(subtitle)
	root.add_child(header)

	root.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	# ---- Credentials ----
	content.add_child(_section_label("API Credentials"))
	_api_url_edit = _text_field("API URL", "https://api-flock.qwacks.com", content)
	_api_key_edit = _text_field("API Key", "", content)
	_api_key_edit.secret = true
	_game_version_edit = _text_field("Game Version (name)", "e.g. 1.0.0", content)

	var resolve_row := HBoxContainer.new()
	resolve_row.add_theme_constant_override("separation", 8)
	_resolve_button = Button.new()
	_resolve_button.text = "Resolve"
	_resolve_button.tooltip_text = "Resolves the Game Version name to its baked ID (GET /v1/game_version/by-name/{name})."
	_resolve_button.pressed.connect(_on_resolve_pressed)
	resolve_row.add_child(_resolve_button)
	var gvid_label := Label.new()
	gvid_label.text = "Game Version ID"
	gvid_label.set_custom_minimum_size(Vector2(150, 0))
	gvid_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resolve_row.add_child(gvid_label)
	_game_version_id_edit = LineEdit.new()
	_game_version_id_edit.placeholder_text = "starts with 01KZ4..."
	_game_version_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resolve_row.add_child(_game_version_id_edit)
	content.add_child(resolve_row)

	# ---- Output ----
	content.add_child(_section_label("Output"))
	_output_dir_edit = _text_field("Output folder", FlockConfigCodegen.DEFAULT_OUTPUT_DIR, content)
	var output_row := HBoxContainer.new()
	output_row.add_theme_constant_override("separation", 8)
	var open_button := Button.new()
	open_button.text = "Open Output Folder"
	open_button.pressed.connect(_on_open_output_pressed)
	output_row.add_child(open_button)
	content.add_child(output_row)

	# ---- Status ----
	content.add_child(_section_label("Status"))
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 12)
	content.add_child(_status_label)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh Status"
	refresh_button.pressed.connect(_refresh_status)
	content.add_child(refresh_button)

	content.add_child(_section_label("Settings"))

	# ---- Log ----
	var log_label := _section_label("Log")
	root.add_child(log_label)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = false
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.custom_minimum_size = Vector2(0, 140)
	root.add_child(_log)

	# ---- Actions ----
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_generate_button = Button.new()
	_generate_button.text = "Generate Code"
	_generate_button.tooltip_text = "Fetches the live schema and regenerates when the content hash changed. Use Force to rewrite identical output."
	_generate_button.pressed.connect(_on_generate_pressed)
	actions.add_child(_generate_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	_force_check = CheckButton.new()
	_force_check.text = "Force regenerate"
	_force_check.tooltip_text = "Rewrite generated code even when the backend schema is unchanged."
	actions.add_child(_force_check)
	var save_button := Button.new()
	save_button.text = "Save Settings"
	save_button.tooltip_text = "Persists these credentials to user://flock_initializer.cfg so the headless CLI can reuse them."
	save_button.pressed.connect(_on_save_pressed)
	actions.add_child(save_button)
	root.add_child(actions)


func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	return label


func _text_field(label_text: String, placeholder: String, parent: Control) -> LineEdit:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	row.add_child(edit)
	parent.add_child(row)
	return edit


func _on_close_requested() -> void:
	queue_free()


###############################################################################
# Settings
###############################################################################

func _settings_from_fields() -> Dictionary:
	return {
		"api_url": _api_url_edit.text.strip_edges(),
		"api_key": _api_key_edit.text.strip_edges(),
		"game_version": _game_version_edit.text.strip_edges(),
		"game_version_id": _game_version_id_edit.text.strip_edges(),
		"output_dir": _output_dir_edit.text.strip_edges(),
	}


func _load_settings_into_fields() -> void:
	var settings := FlockConfigCodegen.load_settings(FlockConfigCodegen.DEFAULT_SETTINGS_PATH)
	_api_url_edit.text = str(settings.get("api_url", ""))
	_api_key_edit.text = str(settings.get("api_key", ""))
	_game_version_edit.text = str(settings.get("game_version", ""))
	_game_version_id_edit.text = str(settings.get("game_version_id", ""))
	_output_dir_edit.text = str(settings.get("output_dir", FlockConfigCodegen.DEFAULT_OUTPUT_DIR))


func _on_save_pressed() -> void:
	FlockConfigCodegen.save_settings(FlockConfigCodegen.DEFAULT_SETTINGS_PATH, _settings_from_fields())
	_append_log("Settings saved to %s." % FlockConfigCodegen.DEFAULT_SETTINGS_PATH)


###############################################################################
# Actions
###############################################################################

func _set_busy(busy: bool) -> void:
	_busy = busy
	_generate_button.disabled = busy
	_resolve_button.disabled = busy


func _on_resolve_pressed() -> void:
	if _busy:
		return
	var settings := _settings_from_fields()
	if settings["api_url"].is_empty() or settings["api_key"].is_empty() or settings["game_version"].is_empty():
		_append_log("Resolve needs API URL, API Key and a Game Version name.")
		return
	_set_busy(true)
	_append_log("Resolving game version '%s'..." % settings["game_version"])
	var result = await FlockConfigCodegen.resolve_game_version_id_async(settings["api_url"], settings["api_key"], settings["game_version"])
	_set_busy(false)
	if result.has("error"):
		_append_log("Resolve failed: %s" % result["error"])
		return
	_game_version_id_edit.text = str(result["game_version_id"])
	_append_log("Resolved -> %s" % result["game_version_id"])
	FlockConfigCodegen.save_settings(FlockConfigCodegen.DEFAULT_SETTINGS_PATH, _settings_from_fields())


func _on_generate_pressed() -> void:
	if _busy:
		return
	var settings := _settings_from_fields()
	if settings["api_url"].is_empty() or settings["api_key"].is_empty():
		_append_log("Enter the API URL and API Key first.")
		return
	if settings["game_version_id"].is_empty() and settings["game_version"].is_empty():
		_append_log("Enter a Game Version ID (or a Game Version name to resolve).")
		return

	_set_busy(true)
	var game_version_id: String = settings["game_version_id"]
	if game_version_id.is_empty():
		_append_log("Resolving game version '%s'..." % settings["game_version"])
		var resolved = await FlockConfigCodegen.resolve_game_version_id_async(settings["api_url"], settings["api_key"], settings["game_version"])
		if resolved.has("error"):
			_append_log("Resolve failed: %s" % resolved["error"])
			_set_busy(false)
			return
		game_version_id = str(resolved["game_version_id"])
		_game_version_id_edit.text = game_version_id
		settings["game_version_id"] = game_version_id

	var output_dir := str(settings["output_dir"])
	if output_dir.is_empty():
		output_dir = FlockConfigCodegen.DEFAULT_OUTPUT_DIR
		_output_dir_edit.text = output_dir

	_append_log("Fetching configs for game version id=%s ..." % game_version_id)
	var snapshot = await FlockConfigCodegen.fetch_snapshot_async(settings["api_url"], settings["api_key"], game_version_id)
	if snapshot.has("error"):
		_append_log("Fetch failed: %s" % snapshot["error"])
		_set_busy(false)
		_refresh_status()
		return

	var drift := FlockConfigCodegen.check_drift(snapshot, output_dir)
	var force := _force_check.button_pressed
	if not force and drift["in_sync"]:
		_append_log("Up to date - content hash %s unchanged. Use Force regenerate to rewrite anyway." % drift["content_hash"])
	else:
		if drift["in_sync"]:
			_append_log("Force: regenerating an identical snapshot (hash %s)." % drift["content_hash"])
		else:
			var prior := "(none)"
			if drift["manifest"].get("exists", false):
				prior = str(drift["manifest"].get("content_hash", ""))
			if prior: _append_log("Schema changed: previous %s -> new %s. Regenerating." % [prior, drift["content_hash"]])
		var emitted := FlockConfigCodegen.emit_snapshot(snapshot, output_dir)
		_append_log("Generated %d/%d config accessor(s) (%d skipped) into %s." % [
			emitted.get("emitted", 0), emitted.get("configs", 0), emitted.get("skipped", 0), output_dir])
		_append_log("  FLOCK_SCHEMA_HASH %s" % emitted.get("content_hash", ""))

	FlockConfigCodegen.save_settings(FlockConfigCodegen.DEFAULT_SETTINGS_PATH, _settings_from_fields())
	_set_busy(false)
	_refresh_status()


func _on_open_output_pressed() -> void:
	var output_dir := _output_dir_edit.text.strip_edges()
	if output_dir.is_empty():
		output_dir = FlockConfigCodegen.DEFAULT_OUTPUT_DIR
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output_dir)):
		_append_log("Output folder does not exist yet - run Generate first.")
		return
	OS.shell_open(ProjectSettings.globalize_path(output_dir))


func _refresh_status() -> void:
	var manifest := FlockConfigCodegen.read_manifest(_output_dir_edit.text.strip_edges())
	if manifest.get("exists", false):
		_status_label.text = "Generated for game version id='%s'\ncontent hash %s\nTurn on Force and press Generate to rewrite identical output." % [
			manifest.get("game_version_id"), manifest.get("content_hash")]
	else:
		_status_label.text = "No generated code yet. Press Generate Code to fetch the live schema and emit typed accessors."


func _append_log(text: String) -> void:
	_log.append_text(text + "\n")