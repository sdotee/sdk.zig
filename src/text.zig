const std = @import("std");
const Client = @import("client.zig").Client;
const json = std.json;

/// Parameters for creating a text paste
pub const CreateTextParams = struct {
    content: []const u8,
    domain: ?[]const u8 = null,
    custom_slug: ?[]const u8 = null,
    title: ?[]const u8 = null,
    text_type: ?[]const u8 = null,
    password: ?[]const u8 = null,
    expire_at: ?i64 = null,
    tag_ids: ?[]const i64 = null,
};

/// Parameters for updating a text paste
pub const UpdateTextParams = struct {
    domain: []const u8,
    slug: []const u8,
    content: []const u8,
    title: ?[]const u8 = null,
};

/// Parameters for deleting a text paste
pub const DeleteTextParams = @import("common.zig").DeleteParams;

/// Text paste data
pub const TextData = struct {
    short_url: []const u8,
    slug: []const u8,
    custom_slug: ?[]const u8 = null,
};

/// Create a new text paste
pub fn create(client: *Client, params: CreateTextParams) !json.Parsed(@import("client.zig").Response(TextData)) {
    return client.request(.POST, "/text", params, TextData);
}

/// Update an existing text paste
pub fn update(client: *Client, params: UpdateTextParams) !json.Parsed(@import("client.zig").Response(json.Value)) {
    return client.request(.PUT, "/text", params, json.Value);
}

/// Delete a text paste
pub fn delete(client: *Client, params: DeleteTextParams) !json.Parsed(@import("client.zig").Response(json.Value)) {
    return client.request(.DELETE, "/text", params, json.Value);
}

/// Get available domains for text sharing
pub fn getDomains(client: *Client) !json.Parsed(@import("client.zig").Response(@import("common.zig").DomainList)) {
    return client.request(.GET, "/text/domains", null, @import("common.zig").DomainList);
}

test "parse create text response" {
    const response_json =
        \\{
        \\ "code": 200,
        \\ "message": "success",
        \\ "data": {
        \\ "short_url": "https://s.ee/txt123",
        \\ "slug": "txt123",
        \\ "custom_slug": null
        \\ }
        \\}
    ;

    const parsed = try json.parseFromSlice(
        @import("client.zig").Response(TextData),
        std.testing.allocator,
        response_json,
        .{ .ignore_unknown_fields = true },
    );
    defer parsed.deinit();

    try std.testing.expectEqual(200, parsed.value.code);
    try std.testing.expectEqualStrings("https://s.ee/txt123", parsed.value.data.?.short_url);
}
