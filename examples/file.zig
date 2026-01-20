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

    // Get file domains
    std.debug.print("Getting file domains...\n", .{});
    const domains_res = try see.file.getDomains(&client);
    defer domains_res.deinit();

    if (domains_res.value.data) |data| {
        std.debug.print("Available file domains:\n", .{});
        for (data.domains) |domain| {
            std.debug.print("  - {s}\n", .{domain});
        }
    } else {
        std.debug.print("Failed to get domains: {s}\n", .{domains_res.value.message});
    }
    std.debug.print("\n", .{});

    // Upload file
    std.debug.print("Uploading file...\n", .{});

    // Add timestamp to make each upload unique
    const timestamp = std.time.timestamp();
    const file_content = try std.fmt.allocPrint(allocator, "Hello world from Zig SDK File Upload Example!\nTimestamp: {d}", .{timestamp});
    defer allocator.free(file_content);
    const filename = "example.txt";

    const upload_res = try see.file.upload(&client, file_content, filename);
    defer upload_res.deinit();

    if (upload_res.value.data) |data| {
        std.debug.print("File uploaded successfully!\n", .{});
        std.debug.print("URL: {s}\n", .{data.url});
        std.debug.print("Delete Key: {s}\n", .{data.delete});
        std.debug.print("Hash: {s}\n", .{data.hash});
        std.debug.print("Size: {d} bytes\n", .{data.size});
        std.debug.print("\n", .{});

        // Delete the uploaded file using the hash (delete key)
        std.debug.print("Deleting file...\n", .{});
        const delete_res = try see.file.delete(&client, data.hash);
        defer delete_res.deinit();

        if (delete_res.value.success) {
            std.debug.print("File deleted successfully!\n", .{});
            std.debug.print("Message: {s}\n", .{delete_res.value.message});
        } else {
            std.debug.print("Delete failed: {s}\n", .{delete_res.value.message});
        }
    } else {
        std.debug.print("Upload failed: {s}\n", .{upload_res.value.message});
    }
}
