# Assets

The `asset` provider manages remote assets with local caching and download support.

## Access

```gdscript
var asset = FlockClient.get_instance().asset
```

## Get All Assets

```gdscript
var result = await FlockClient.get_instance().asset.get_all_async()

if result is Array:
    for a in result:
        print("Asset: ", a.get("name", ""))
        print("ID: ", a.get("id", ""))
        print("URL: ", a.get("s3_download_url", ""))
```

## Get Asset by ID

```gdscript
var result = await FlockClient.get_instance().asset.get_by_id_async("ASSET_ID")

if result is Dictionary:
    print("Name: ", result.get("name", ""))
    print("Download URL: ", result.get("s3_download_url", ""))
    print("Updated: ", result.get("updated_at", ""))
```

## Get Asset by Name

```gdscript
var result = await FlockClient.get_instance().asset.get_by_name_async("hero_sprite")

if result is Dictionary and not result.has("error"):
    print("Found asset: ", result.get("name", ""))
```

## Download Asset

Download an asset's content:

```gdscript
var result = await FlockClient.get_instance().asset.download_async("ASSET_ID")

if result is Dictionary:
    if result.has("error"):
        print("Download failed: ", result["error"])
    else:
        # result contains the downloaded data
        print("Downloaded: ", result)
```

## Cache Management

### Clear Cache

```gdscript
FlockClient.get_instance().asset.clear_cache()
```

### Check Cache Directory

```gdscript
print("Asset cache: ", FlockClient.get_instance().asset.cache_directory)
```

## Caching Behavior

The asset provider implements a multi-layer caching strategy:

1. **Memory Cache** — Assets fetched during this session are cached in memory
2. **Disk Cache** — Downloaded assets are saved to the cache directory
3. **Snapshot Cache** — Asset index is saved for offline use
4. **Network Fetch** — Falls back to API when cache misses

### Cache Configuration

In `FlockInitConfig`:

```gdscript
config.enable_asset_cache = true
config.asset_cache_directory = ""  # Default: user://flock/assets/
config.asset_cache_max_size_mb = 100
config.asset_download_timeout = 30.0
config.asset_download_retry_count = 3
config.asset_max_concurrent_downloads = 4
```

## Offline Support

When the network is unavailable:
1. The asset index is loaded from disk snapshot
2. Individual assets are served from disk cache
3. `download_async()` returns cached data if available

```gdscript
# This works offline if the asset was previously downloaded
var asset = await FlockClient.get_instance().asset.get_by_id_async("ASSET_ID")
```

## Common Patterns

### Download All Assets

```gdscript
func download_all_assets():
    var assets = await FlockClient.get_instance().asset.get_all_async()
    if assets is Array:
        for a in assets:
            var url = a.get("s3_download_url", "")
            if not url.is_empty():
                print("Downloading: ", a.get("name", ""))
                await FlockClient.get_instance().asset.download_async(a.get("id", ""))
```

### Load Texture from Asset

```gdscript
func load_asset_texture(asset_id: String) -> Texture2D:
    var result = await FlockClient.get_instance().asset.download_async(asset_id)
    if result is PackedByteArray:
        var image = Image.new()
        image.load_png_from_buffer(result)
        return ImageTexture.create_from_image(image)
    return null
```

### Check Asset Exists

```gdscript
func asset_exists(asset_name: String) -> bool:
    var result = await FlockClient.get_instance().asset.get_by_name_async(asset_name)
    return result is Dictionary and not result.has("error")
```

## Asset Data Structure

```json
{
    "id": "01KXYZ...",
    "name": "hero_sprite",
    "s3_download_url": "https://cdn.example.com/assets/hero_sprite.png",
    "updated_at": "2024-06-15T12:00:00Z",
    "metadata": {
        "type": "texture",
        "width": 256,
        "height": 256
    }
}
```
