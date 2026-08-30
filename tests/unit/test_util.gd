extends GutTest


func test_ensure_dir_creates_nested_paths() -> void:
	var base := OS.get_temp_dir().path_join("flocktest_util_%d" % Time.get_ticks_msec())
	DirAccess.remove_absolute(base)
	var nested := base.path_join("a").path_join("b").path_join("c")
	assert_eq(DirAccess.dir_exists_absolute(nested), false, "nested dir absent before")
	FlockUtil.ensure_dir(nested)
	assert_eq(DirAccess.dir_exists_absolute(nested), true, "nested dir created")
	assert_eq(DirAccess.dir_exists_absolute(base), true, "parent chain created")


func test_ensure_dir_existing_noop() -> void:
	var base := OS.get_temp_dir().path_join("flocktest_util_%d" % Time.get_ticks_msec())
	DirAccess.remove_absolute(base)
	DirAccess.make_dir_recursive_absolute(base)
	FlockUtil.ensure_dir(base)
	assert_eq(DirAccess.dir_exists_absolute(base), true, "existing dir untouched")


func test_util_known_paths() -> void:
	assert_true(FlockUtil.flock_data_dir().ends_with("Flock"), "data dir under user dir")
	assert_true(FlockUtil.flock_snapshots_dir().ends_with("snapshots"), "snapshots dir")
	assert_true(FlockUtil.flock_token_access_path().ends_with("access_token"), "access token path")
	assert_true(FlockUtil.flock_token_refresh_path().ends_with("refresh_token"), "refresh token path")