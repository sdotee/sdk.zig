const std = @import("std");
const Client = @import("client.zig").Client;
const Response = @import("client.zig").Response;
const json = std.json;

/// List of domains available for the user
pub const DomainList = struct {
    domains: []const []const u8,
};

/// Tag information
pub const Tag = struct {
    id: i64,
    name: []const u8,
};

/// List of tags
pub const TagList = struct {
    tags: []const Tag,
};

/// Common invalidation/deletion parameters
pub const DeleteParams = struct {
    domain: []const u8,
    slug: []const u8,
};

/// Get list of available domains
pub fn getDomains(client: *Client) !json.Parsed(Response(DomainList)) {
    return client.request(.GET, "/domains", null, DomainList);
}

/// Get list of available tags
pub fn getTags(client: *Client) !json.Parsed(Response(TagList)) {
    return client.request(.GET, "/tags", null, TagList);
}
