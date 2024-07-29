const std = @import("std");
const lexer = @import("./lexer.zig");

pub fn start() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var buf: [1024]u8 = undefined;

    while (true) {
        if(try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |input| {
            var l = lexer.Lexer {
                .input = input,
                .allocator = allocator,
            };

            l.readChar();

            while(l.ch != 0) {
                const token = try l.nextToken();
                try stdout.print("TokenType: {any}, Literal: {s}\n", .{token.type, token.literal});
            }
        }
    }
}
