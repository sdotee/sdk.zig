const std = @import("std");
const Client = @import("client.zig").Client;
const json = std.json;

/// Parameters for creating a shortened URL
pub const CreateShortParams = struct {
    target_url: []const u8,
    domain: []const u8,
    custom_slug: ?[]const u8 = null,
    title: ?[]const u8 = null,
    password: ?[]const u8 = null,
    expire_at: ?i64 = null,
    expiration_redirect_url: ?[]const u8 = null,
    tag_ids: ?[]const i64 = null,
};

/// Parameters for updating a shortened URL
pub const UpdateShortParams = struct {
    domain: []const u8,
    slug: []const u8,
    target_url: []const u8,
    title: []const u8,
};

/// Parameters for deleting a shortened URL
pub const DeleteShortParams = @import("common.zig").DeleteParams;

/// Shortened URL details
pub const ShortURL = struct {
    short_url: []const u8,
    slug: []const u8,
    custom_slug: ?[]const u8 = null,
};

/// Create a new shortened URL
pub fn create(client: *Client, params: CreateShortParams) !json.Parsed(@import("client.zig").Response(ShortURL)) {
    return client.request(.POST, "/shorten", params, ShortURL);
}

/// Parameters for creating a shortened URL (Simple Mode)
pub const CreateShortSimpleParams = struct {
    url: []const u8,
    signature: ?[]const u8 = null,
    domain: ?[]const u8 = null,
    custom_slug: ?[]const u8 = null,
    title: ?[]const u8 = null,
    tag_ids: ?[]const i64 = null,
    password: ?[]const u8 = null,
    expire_at: ?i64 = null,
    json: ?bool = true,
};

/// Create a new shortened URL (Simple Mode)
pub fn createSimple(client: *Client, params: CreateShortSimpleParams) !json.Parsed(@import("client.zig").Response(ShortURL)) {
    var p = params;
    if (p.signature == null) {
        p.signature = client.api_key;
    }
    return client.request(.GET, "/shorten", p, ShortURL);
}

/// Update an existing shortened URL
pub fn update(client: *Client, params: UpdateShortParams) !json.Parsed(@import("client.zig").Response(json.Value)) {
    return client.request(.PUT, "/shorten", params, json.Value);
}

/// Delete a shortened URL
pub fn delete(client: *Client, params: DeleteShortParams) !json.Parsed(@import("client.zig").Response(json.Value)) {
    return client.request(.DELETE, "/shorten", params, json.Value);
}

test "parse create response" {
    const response_json =
        \\{
        \\ "code": 200,
        \\ "message": "success",
        \\ "data": {
        \\ "short_url": "https://s.ee/myshorturl",
        \\ "slug": "myshorturl",
        \\ "custom_slug": "myshorturl"
        \\ }
        \\}
    ;

    const parsed = try json.parseFromSlice(
        @import("client.zig").Response(ShortURL),
        std.testing.allocator,
        response_json,
        .{ .ignore_unknown_fields = true },
    );
    defer parsed.deinit();

    try std.testing.expectEqual(200, parsed.value.code);
    try std.testing.expectEqualStrings("https://s.ee/myshorturl", parsed.value.data.?.short_url);
}
