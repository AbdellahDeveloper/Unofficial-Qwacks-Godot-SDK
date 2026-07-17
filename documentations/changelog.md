# Changelog

## 1.28.0 (2026-07-17)

### Features
- Initial release of the Godot GDScript port
- Full authentication support (Email, Device, Google, Apple, Steam, Facebook, Discord)
- Player data CRUD with template system
- Game configuration with live patching
- In-game shop with purchase flow
- Remote asset management with caching
- Command system with offline write queue
- Analytics with session tracking, events, and transactions
- Error logging and exception tracking
- Consent management for GDPR compliance
- Automatic session restore on app restart
- Auto-initializer node for Inspector configuration

### Bug Fixes
- Fixed HTTPRequest node not in tree error
- Fixed `signal` keyword collision in FlockEvents
- Fixed JWT token parsing edge cases
- Fixed analytics session end sending wrong data
- Fixed command provider flush timer lifecycle

### Known Issues
- Analytics batch endpoints may return 422 for certain payload formats (server-side)
- Asset download returns raw bytes (type-specific loading is application-specific)

---

## Previous Versions

See the [Unity C# SDK changelog](https://github.com/QwackStack/FlockUnitySdk) for version history prior to the Godot port.
