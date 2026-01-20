const std = @import("std");
const Client = @import("client.zig").Client;
const Response = @import("client.zig").Response;
const json = std.json;

pub const FileUploadResponse = struct {
    url: []const u8,
    delete: []const u8,
    filename: []const u8,
    size: i64,
    hash: []const u8,
    width: i64,
    height: i64,
    storename: []const u8,
    path: []const u8,
};

pub const FileDomainList = struct {
    domains: []const []const u8,
};

pub const FileDeleteResponse = struct {
    code: []const u8,
    message: []const u8,
    success: bool,
};

pub fn upload(client: *Client, file_content: []const u8, filename: []const u8) !json.Parsed(Response(FileUploadResponse)) {
    return client.multipartRequest("/file/upload", file_content, filename, FileUploadResponse);
}

pub fn delete(client: *Client, delete_hash: []const u8) !json.Parsed(FileDeleteResponse) {
    const path = try std.fmt.allocPrint(client.allocator, "/file/delete/{s}", .{delete_hash});
    defer client.allocator.free(path);

    const url = try std.fmt.allocPrint(client.allocator, "{s}{s}", .{ client.base_url, path });
    defer client.allocator.free(url);

    return client.requestAny(.GET, url, null, FileDeleteResponse);
}

pub fn getDomains(client: *Client) !json.Parsed(Response(FileDomainList)) {
    return client.request(.GET, "/file/domains", null, FileDomainList);
}

test "parse upload response" {
    const response_json =
        \\{
        \\ "code": 200,
        \\ "message": "success",
        \\ "data": {
        \\ "url": "https://s.ee/f/file.png",
        \\ "delete": "delkey123",
        \\ "filename": "file.png",
        \\ "size": 1024,
        \\ "hash": "abc",
        \\ "width": 100,
        \\ "height": 100,
        \\ "storename": "store.png",
        \\ "path": "/f/store.png"
        \\ }
        \\}
    ;

    const parsed = try json.parseFromSlice(
        Response(FileUploadResponse),
        std.testing.allocator,
        response_json,
        .{ .ignore_unknown_fields = true },
    );
    defer parsed.deinit();

    try std.testing.expectEqual(200, parsed.value.code);
    try std.testing.expectEqualStrings("https://s.ee/f/file.png", parsed.value.data.?.url);
    try std.testing.expectEqual(1024, parsed.value.data.?.size);
}

test "parse delete response" {
    const response_json =
        \\{
        \\ "code": "200",
        \\ "message": "success",
        \\ "success": true
        \\}
    ;

    const parsed = try json.parseFromSlice(
        FileDeleteResponse,
        std.testing.allocator,
        response_json,
        .{ .ignore_unknown_fields = true },
    );
    defer parsed.deinit();

    try std.testing.expectEqualStrings("200", parsed.value.code);
    try std.testing.expect(parsed.value.success);
}
