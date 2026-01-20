# Zig SDK for S.EE API(Experimental)

**Notice: This SDK is currently experimental and may undergo significant changes. Use with caution.**

Zig SDK for S.EE API - A comprehensive SDK for shortening URLs, sharing text, and uploading files.

## Features

- **Short URLs**: Create, update, and manage short links
- **Text Sharing**: Share text content with optional password protection and expiration
- **File Upload**: Upload and share files
- **Domain Management**: List available domains for your services
- **Tag Support**: Organize your links and content with tags

## Installation

Add this package to your `build.zig.zon` as a dependency:

```zig
.dependencies = .{
    .@"see-zig-sdk" = .{
        .url = "https://github.com/sdotee/sdk.zig/archive/refs/tags/v0.1.0.tar.gz",
        .hash = "...",
    },
},
```

Or clone it directly into your project:

```bash
git clone git@github.com:sdotee/sdk.zig.git
```

## Quick Start

```zig
const std = @import("std");
const see = @import("see-zig-sdk");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "YOUR_API_KEY";
    var client = try see.Client.init(allocator, api_key, null);
    defer client.deinit();

    // Now you can use the client with various modules:
    // - see.common for domains and tags
    // - see.shorten for short URLs
    // - see.text for text sharing
    // - see.file for file uploads
}
```

## Examples

To run the examples, set the `SEE_API_KEY` environment variable:

```bash
export SEE_API_KEY="your_api_key"

zig build example-shorten  # Create and update short URLs
zig build example-text     # Share and update text content
zig build example-file     # Upload and manage files
```

For complete usage examples with detailed code, see:

- [examples/shorten.zig](examples/shorten.zig) - Short URL management with domain listing
- [examples/text.zig](examples/text.zig) - Text sharing with password and expiration
- [examples/file.zig](examples/file.zig) - File upload and deletion

## Known Limitations

### DELETE Operations

DELETE operations for short URLs and text pastes are **not supported** in Zig 0.15.x due to standard library limitations.

**Why**: The S.EE API requires DELETE requests with JSON body, but `std.http.Client` doesn't support request bodies for DELETE methods:

```zig
// From Zig's std.http
pub fn requestHasBody(m: Method) bool {
    return switch (m) {
        .POST, .PUT, .PATCH => true,
        .GET, .HEAD, .DELETE, .CONNECT, .OPTIONS, .TRACE => false,
    };
}
```

**Workarounds**:
- Use the web interface for deletions
- File deletions work (they use GET with delete key)
- Wait for future Zig versions with flexible HTTP APIs

The `delete()` functions are included for API completeness and will work once Zig supports this pattern.

## API Reference

### Client
- `init(allocator, api_key, base_url)` - Initialize client
- `deinit(self)` - Clean up resources

### Modules
- **`see.common`** - `getDomains()`, `getTags()`
- **`see.shorten`** - `create()`, `update()`, ~~`delete()`~~ ⚠️
- **`see.text`** - `create()`, `update()`, ~~`delete()`~~ ⚠️
- **`see.file`** - `upload()`, `deleteFile()`, `getDomains()`

⚠️ = Not working in Zig 0.15.x (see Known Limitations)

## Testing

Run tests with:

```bash
zig build test
```

## Requirements

- Zig 0.15.0 or later
- S.EE API key (get one at https://s.ee)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
Requirements

- Zig 0.15.0 or later
- S.EE API key (get one at https://s.ee)

## Testing

```bash
zig build test
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Links

- [S.EE Official Website](https://s.ee)
- [S.EE API Documentation](https://s.ee/docs)
- [S.EE GitHub Repository](https://github.com/sdotee)
