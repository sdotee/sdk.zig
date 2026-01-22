const std = @import("std");
const json = std.json;
const http = std.http;
const Allocator = std.mem.Allocator;

/// Generic response wrapper for API responses
pub fn Response(comptime T: type) type {
    return struct {
        code: i64,
        message: []const u8,
        data: ?T = null,
    };
}

/// S.EE API Client
/// Handles authentication and HTTP requests to the API
pub const Client = struct {
    allocator: Allocator,
    api_key: []const u8,
    base_url: []const u8,
    http_client: http.Client,

    const default_base_url = "https://s.ee/api/v1";

    /// Initialize a new API client
    /// - allocator: Memory allocator
    /// - api_key: Your S.EE API key
    /// - base_url: Optional API base URL (defaults to "https://s.ee/api/v1")
    pub fn init(allocator: Allocator, api_key: []const u8, base_url: ?[]const u8) !Client {
        return .{
            .allocator = allocator,
            .api_key = try allocator.dupe(u8, api_key),
            .base_url = try allocator.dupe(u8, base_url orelse default_base_url),
            .http_client = .{ .allocator = allocator },
        };
    }

    /// Deinitialize the client and free resources
    pub fn deinit(self: *Client) void {
        self.allocator.free(self.api_key);
        self.allocator.free(self.base_url);
        self.http_client.deinit();
    }

    /// Send a JSON request to the API
    /// - method: HTTP method (GET, POST, PUT, DELETE)
    /// - path: API endpoint path
    /// - params: Request parameters (will be serialized to JSON)
    /// - ResponseType: Expected response data type
    pub fn request(self: *Client, method: http.Method, path: []const u8, params: anytype, comptime ResponseType: type) !json.Parsed(Response(ResponseType)) {
        const url = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ self.base_url, path });
        defer self.allocator.free(url);
        return self.doRequestInternal(method, url, params, Response(ResponseType));
    }

    /// Send a multipart/form-data request (for file uploads)
    /// - path: API endpoint path
    /// - file_content: content of the file to upload
    /// - filename: name of the file
    /// - ResponseType: Expected response data type
    pub fn multipartRequest(self: *Client, path: []const u8, file_content: []const u8, filename: []const u8, comptime ResponseType: type) !json.Parsed(Response(ResponseType)) {
        const url = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ self.base_url, path });
        defer self.allocator.free(url);

        const boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW";
        const content_type = try std.fmt.allocPrint(self.allocator, "multipart/form-data; boundary={s}", .{boundary});
        defer self.allocator.free(content_type);

        const uri = try std.Uri.parse(url);

        var req = try self.http_client.request(.POST, uri, .{
            .keep_alive = false,
            .headers = .{
                .authorization = .{ .override = self.api_key },
                .content_type = .{ .override = content_type },
            },
        });
        defer req.deinit();

        // Build multipart body
        const part_head = try std.fmt.allocPrint(
            self.allocator,
            "--{s}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{s}\"\r\nContent-Type: application/octet-stream\r\n\r\n",
            .{ boundary, filename },
        );
        defer self.allocator.free(part_head);

        const part_tail = try std.fmt.allocPrint(self.allocator, "\r\n--{s}--\r\n", .{boundary});
        defer self.allocator.free(part_tail);

        const total_len = part_head.len + file_content.len + part_tail.len;
        req.transfer_encoding = .{ .content_length = total_len };

        var body = try req.sendBodyUnflushed(&.{});
        try body.writer.writeAll(part_head);
        try body.writer.writeAll(file_content);
        try body.writer.writeAll(part_tail);
        try body.end();
        try req.connection.?.flush();

        var response = try req.receiveHead(&.{});
        const body_payload = try self.readResponseBody(&response);
        defer self.allocator.free(body_payload);

        return json.parseFromSlice(Response(ResponseType), self.allocator, body_payload, .{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        });
    }

    fn doRequestInternal(self: *Client, method: http.Method, url: []const u8, params: anytype, comptime T: type) !json.Parsed(T) {
        const uri = try std.Uri.parse(url);

        var req = try self.http_client.request(method, uri, .{
            .keep_alive = false,
            .headers = .{
                .authorization = .{ .override = self.api_key },
                .content_type = .{ .override = "application/json" },
            },
        });
        defer req.deinit();

        // Prepare request body if params provided
        var body_str: ?[]u8 = null;
        defer if (body_str) |s| self.allocator.free(s);

        if (@TypeOf(params) != @TypeOf(null)) {
            body_str = try std.fmt.allocPrint(self.allocator, "{f}", .{json.fmt(params, .{})});
        }

        // Send request
        // Note: DELETE requests with body require special handling in Zig's HTTP client
        if (body_str) |body| {
            if (method == .DELETE) {
                // For DELETE with body, manually construct and send the request
                // Set content length
                req.transfer_encoding = .{ .content_length = body.len };
                // Write headers and body manually
                var writer = &req.connection.?.stream_writer;
                // First send headers
                try req.sendBodiless();
                // Then write the body directly to stream
                try writer.interface.writeAll(body);
                try writer.interface.flush();
            } else {
                req.transfer_encoding = .{ .content_length = body.len };
                var writer = try req.sendBodyUnflushed(&.{});
                try writer.writer.writeAll(body);
                try writer.end();
                try req.connection.?.flush();
            }
        } else {
            if (method == .POST or method == .PUT or method == .DELETE) {
                req.transfer_encoding = .{ .content_length = 0 };
            }
            try req.sendBodiless();
        }

        // Receive response
        var response = try req.receiveHead(&.{});
        const body_payload = try self.readResponseBody(&response);
        defer self.allocator.free(body_payload);

        return json.parseFromSlice(T, self.allocator, body_payload, .{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        });
    }

    fn readResponseBody(self: *Client, response: *http.Client.Response) ![]u8 {
        // Prepare decompression buffers
        const decompress_buffer: []u8 = switch (response.head.content_encoding) {
            .identity => &.{},
            .zstd => try self.allocator.alloc(u8, std.compress.zstd.default_window_len),
            .deflate, .gzip => try self.allocator.alloc(u8, std.compress.flate.max_window_len),
            .compress => return error.UnsupportedCompressionMethod,
        };
        defer if (response.head.content_encoding != .identity) self.allocator.free(decompress_buffer);

        var transfer_buffer: [4096]u8 = undefined;
        var decompress: http.Decompress = undefined;
        const reader = response.readerDecompressing(&transfer_buffer, &decompress, decompress_buffer);

        return reader.allocRemaining(self.allocator, .unlimited) catch |err| switch (err) {
            error.ReadFailed => return response.bodyErr().?,
            else => |e| return e,
        };
    }
};
