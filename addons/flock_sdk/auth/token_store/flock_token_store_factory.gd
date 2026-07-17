class_name FlockTokenStoreFactory

static func create() -> FlockTokenStore:
	match OS.get_name():
		"Windows":
			# Use ConfigFile with encrypted file flag for Windows
			return FlockConfigFileTokenStore.new()
		"Linux":
			return FlockConfigFileTokenStore.new()
		"macOS":
			# Could use Keychain via GDExtension, fallback to ConfigFile
			return FlockConfigFileTokenStore.new()
		"Android":
			# Could use Android Keystore via GDExtension, fallback to ConfigFile
			return FlockConfigFileTokenStore.new()
		"iOS":
			# Could use Keychain via GDExtension, fallback to ConfigFile
			return FlockConfigFileTokenStore.new()
		"Web":
			return FlockConfigFileTokenStore.new()
		_:
			return FlockConfigFileTokenStore.new()
