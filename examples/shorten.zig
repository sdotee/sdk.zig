const std = @import("std");
const see = @import("see-zig-sdk");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    const api_key = env_map.get("SEE_API_KEY") orelse {
        std.debug.print("Error: SEE_API_KEY environment variable is required\n", .{});
        return;
    };
    const api_base = env_map.get("SEE_API_BASE");

    var client = try see.Client.init(allocator, api_key, api_base);
    defer client.deinit();

    // 1. Fetch available domain list
    std.debug.print("=== Fetching available domains ===\n", .{});
    const domains_result = try see.common.getDomains(&client);
    defer domains_result.deinit();

    if (domains_result.value.data) |domains_data| {
        std.debug.print("Available domains:\n", .{});
        for (domains_data.domains) |domain| {
            std.debug.print("  - {s}\n", .{domain});
        }
    } else {
        std.debug.print("Failed to get domains: {s}\n", .{domains_result.value.message});
    }

    std.debug.print("\n", .{});

    // 2. Create short URL
    std.debug.print("=== Creating short URL ===\n", .{});
    const create_params = see.shorten.CreateShortParams{
        .target_url = "https://ziglang.org",
        .domain = "s.ee",
        .title = "Zig Programming Language",
    };

    const result = try see.shorten.create(&client, create_params);
    defer result.deinit();

    var created_domain: []const u8 = undefined;
    var created_slug: []const u8 = undefined;

    if (result.value.data) |data| {
        std.debug.print("Short URL created successfully!\n", .{});
        std.debug.print("  URL: {s}\n", .{data.short_url});
        std.debug.print("  Slug: {s}\n", .{data.slug});

        // Extract domain from short_url for subsequent operations
        // e.g. "https://s.ee/abc123" -> "s.ee"
        const url = data.short_url;
        const protocol_end = std.mem.indexOf(u8, url, "://") orelse return error.InvalidURL;
        const domain_start = protocol_end + 3;
        const path_start = std.mem.indexOfPos(u8, url, domain_start, "/") orelse return error.InvalidURL;
        created_domain = url[domain_start..path_start];
        created_slug = data.slug;
    } else {
        std.debug.print("Failed to create short URL: {s}\n", .{result.value.message});
        return;
    }

    std.debug.print("\n", .{});

    // 3. Update short URL
    std.debug.print("=== Updating short URL ===\n", .{});
    const update_params = see.shorten.UpdateShortParams{
        .domain = created_domain,
        .slug = created_slug,
        .target_url = "https://ziglang.org/documentation/master/",
        .title = "Zig Documentation",
    };

    const update_result = try see.shorten.update(&client, update_params);
    defer update_result.deinit();

    if (update_result.value.code == 200) {
        std.debug.print("Short URL updated successfully!\n", .{});
        std.debug.print("  Message: {s}\n", .{update_result.value.message});
    } else {
        std.debug.print("Failed to update short URL: {s}\n", .{update_result.value.message});
    }

    std.debug.print("\n", .{});

    // 4. Delete short URL
    // Note: DELETE requests with body are not supported in Zig 0.15's HTTP client
    std.debug.print("=== Deleting short URL (skipped) ===\n", .{});
    std.debug.print("Note: DELETE with body is not supported in Zig 0.15's HTTP client.\n", .{});
    std.debug.print("The short URL is: https://{s}/{s}\n", .{ created_domain, created_slug });
    std.debug.print("You can manually delete it through the web interface.\n", .{});

    // Uncomment when Zig's HTTP client supports DELETE with body:
    // const delete_params = see.shorten.DeleteShortParams{
    //     .domain = created_domain,
    //     .slug = created_slug,
    // };
    // const delete_result = try see.shorten.delete(&client, delete_params);
    // defer delete_result.deinit();
    // if (delete_result.value.code == 200) {
    //     std.debug.print("Short URL deleted successfully!\n", .{});
    // }
}
