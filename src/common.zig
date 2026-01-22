const std = @import("std");
const Client = @import("client.zig").Client;
const Response = @import("client.zig").Response;
const json = std.json;

pub const DomainList = struct {
    domains: []const []const u8,
};

pub const Tag = struct {
    id: i64,
    name: []const u8,
};

pub const TagList = struct {
    tags: []const Tag,
};

pub const DeleteParams = struct {
    domain: []const u8,
    slug: []const u8,
};

pub fn getDomains(client: *Client) !json.Parsed(Response(DomainList)) {
    return client.request(.GET, "/domains", null, DomainList);
}

pub fn getTags(client: *Client) !json.Parsed(Response(TagList)) {
    return client.request(.GET, "/tags", null, TagList);
}
