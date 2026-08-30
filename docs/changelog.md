# Changelog

## 1.37.0 (2026-08-27)

Ported from the official Unity C# SDK (releases 1.29 through 1.37).

### Notifications (1.37 / 1.32 / 1.29)
- In-app mailbox: inbox, unread count, and summary fetches
- New-notification events raised once per notification, tracked by a persistent watermark
- Template catalog (`get_templates_async`, `get_template_by_name_async` with locale)
- Schedule, cancel, and list scheduled notifications
- Mark-read and mark-all-read with `unread_count_changed` events

### Shop rewards (1.36)
- Reward parsing on shop items and purchase results (`type`, `code`, `amount`)
- `consume_async` inventory consumption with granted rewards

### Error hints (1.35)
- `FlockErrorHints` and composed error messages (`FlockException`), including 422 detail extraction

### Account linking (1.31)
- `link_*_async` / `unlink_*_async` for every auth provider, `is_linked`, and linked-account list

### Leaderboards (1.33 / 1.30)
- Boards by name with session memos, standings, signed-in-player rank, and "around me" neighborhoods

### Offline command queue (1.34 / 1.33)
- Writes reach disk before being reported as queued; replayed on reconnect
- Per-write attempt counter with a replay cap — permanent 4xx rejections (except 408/429, 401, bare 403) drop the write instead of blocking the queue
- Optimistic cache rows are evicted when a queued write is rejected, so the next read refetches authoritative state
- Clear "queued for sync" vs "not saved — lost on exit" messaging

### Analytics offline pipeline (1.33)
- Event cache is write-ahead with atomic renames; `clear()` bumps an epoch guard so an in-flight flush can't send erased events
- Batch flush classifies failures: permanent rejections (backend-coded 403 and non-408/429 4xx) drop the batch; transient ones defer
- Session ends are spooled to disk before any network attempt and retried until the server confirms them; duplicate ends (quit + crash recovery) are skipped
- `FlockSession.report_end_spool_failed()` keeps the live termination marker when the end can't be persisted
- Consent now gates egress too: revocation halts all flush paths, not just collection
- `log_event` distinguishes "queued" from "NOT queued — never delivered" (e.g. cache failures)
- Dirty-shutdown termination events are consent-aware and only cleared after a durable enqueue
- Queued events survive logout (`handle_auth_cleared` no longer clears caches)

### Logger severity (1.33)
- `GodotFlockLogger(verbose)` gates info/debug; warnings and errors always surface

### Fixes
- Fixed parse errors in leaderboard/notification providers from GDScript lambda indentation layout
- Fixed `Time.get_datetime_dict_from_unix_time` misuse (2-arg call)
- `FlockUtil.ensure_dir` now creates arbitrarily nested directories (snapshot scopes, token paths)

### Not ported
- Unity's "pin" pattern that holds a fetch `Task` in flight for both a snapshot hit and the live request has no GDScript analog: Godot forbids calling coroutines without `await`. The Godot fetchers instead track shared fetch completion flags (`_all_*_fetched`), which already prevent duplicate or raced serving.

---

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
