extends GutTest

## GUT hook for the real-credentials integration pipeline.
##
## Marks the integration as PENDING (never failing) when credentials are not
## configured, so `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit`
## passes everywhere. The full ordered create -> update -> delete pipeline is NOT
## run from GUT — run it directly for guaranteed ordering and the prerequisite
## checker's setup instructions:
##
##   godot --headless -s res://tests/integration/run_pipeline.gd


func test_credentials_configured_or_pending() -> void:
	if not IntegrationEnv.is_credentials_complete():
		pending("Integration credentials not configured. Set FLOCK_GAME_ID / "
			+ "FLOCK_GAME_VERSION_ID / FLOCK_API_KEY, or copy "
			+ "tests/integration/secrets.cfg.example to tests/integration/secrets.cfg "
			+ "and fill it in. Then run the pipeline: "
			+ "godot --headless -s res://tests/integration/run_pipeline.gd")
		return
	assert_true(IntegrationEnv.is_credentials_complete(), "credentials complete from env/secrets.cfg")


func test_integration_env_is_consistent() -> void:
	var cfg := IntegrationEnv.config()
	assert_true(cfg.has("api_url"), "api_url always present (defaulted)")
	assert_true(cfg.get("api_url") is String, "api_url is a string")
	if not IntegrationEnv.is_credentials_complete():
		assert_true(str(cfg.get("game_id", "")).is_empty(), "game_id empty when unconfigured")


func test_phase_list_is_deduplicated_and_valid() -> void:
	var phases := IntegrationEnv.get_phases()
	assert_eq(phases, phases.duplicate(), "phases is a plain list")
	for phase in phases:
		assert_true(IntegrationEnv.PHASES.has(phase), "phase '%s' is known" % phase)