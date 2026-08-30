extends GutTest


func test_channels_wiring() -> void:
	assert_eq(NotificationModels.channels_to_wire(NotificationModels.CHANNEL_NONE), [], "channels none")
	assert_eq(NotificationModels.channels_to_wire(NotificationModels.CHANNEL_IN_APP | NotificationModels.CHANNEL_EMAIL | NotificationModels.CHANNEL_PUSH), ["in_app", "email", "push"], "channels in+email+push")
	assert_eq(NotificationModels.channels_to_wire(NotificationModels.CHANNEL_EMAIL), ["email"], "channels email only")


func test_platform_wiring() -> void:
	assert_eq(NotificationModels.platform_to_wire(NotificationModels.PLATFORM_ANDROID), "android", "platform android")
	assert_eq(NotificationModels.platform_to_wire(NotificationModels.PLATFORM_IOS), "ios", "platform ios")
	assert_eq(NotificationModels.platform_to_wire(NotificationModels.PLATFORM_WEB), "web", "platform web")


func test_notification_read_flag() -> void:
	assert_eq(NotificationModels.notification_is_read({"read_at": "2026-08-27T10:00:00Z"}), true, "is read true")
	assert_eq(NotificationModels.notification_is_read({"read_at": ""}), false, "is read false")
	assert_eq(NotificationModels.notification_is_read({}), false, "is read absent")


func test_data_accessors() -> void:
	assert_eq(NotificationModels.notification_get_data({"data": {"deep": "linkx"}}, "deep", "fallback"), "linkx", "get data string")
	assert_eq(NotificationModels.notification_get_data({"data": {}}, "missing", "fallback"), "fallback", "get data fallback")
	assert_eq(NotificationModels.notification_get_data_int({"data": {"x": "42"}}, "x", 0), 42, "get data int from string")