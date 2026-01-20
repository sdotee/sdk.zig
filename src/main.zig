//
// Copyright (c) 2026 S.EE Development Team
//
// This source code is licensed under the MIT License,
// which is located in the LICENSE file in the source tree's root directory.
//
// File: main.zig
// Author: S.EE Development Team <dev@s.ee>
// File Created: 2026-01-20 19:30:30
//
// Modified By: S.EE Development Team <dev@s.ee>
// Last Modified: 2026-01-20 22:54:32
//

pub const client = @import("client.zig");
pub const common = @import("common.zig");
pub const shorten = @import("shorten.zig");
pub const text = @import("text.zig");
pub const file = @import("file.zig");

pub const Client = client.Client;

test "all tests" {
    // Import all files to include their tests
    _ = client;
    _ = common;
    _ = shorten;
    _ = text;
    _ = file;
}
