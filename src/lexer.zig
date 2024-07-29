const std = @import("std");
const token_lib = @import("./token.zig");
const Token = token_lib.Token;
const TokenType = token_lib.TokenType;

pub const Lexer = struct {
    input: []const u8,
    position: usize = 0,
    read_pos: usize = 0,
    ch: u8 = undefined,

    pub fn readChar(self: *Lexer) !void {
        if (self.read_pos >= self.input.len) self.ch = 0 else self.ch = self.input[self.read_pos];
        self.position = self.read_pos;
        self.read_pos += 1;
    }

    pub fn nextToken(self: *Lexer) !Token {
        var token: Token = .{};

        switch(self.ch) {
            '=' => token.init(TokenType.assign, getConstantLiteral(self.ch)),
            ';' => token.init(TokenType.semicolon, getConstantLiteral(self.ch)),
            '(' => token.init(TokenType.lparen, getConstantLiteral(self.ch)),
            ')' => token.init(TokenType.rparen, getConstantLiteral(self.ch)),
            ',' => token.init(TokenType.comma, getConstantLiteral(self.ch)),
            '+' => token.init(TokenType.plus, getConstantLiteral(self.ch)),
            '{' => token.init(TokenType.lbrace, getConstantLiteral(self.ch)),
            '}' => token.init(TokenType.rbrace, getConstantLiteral(self.ch)),
            0 => token.init(TokenType.eof, getConstantLiteral(0)),
            else => _ = .{},
        }

        try self.readChar();
        return token;
    }

    fn getConstantLiteral(ch: u8) []const u8 {
        switch(ch) {
            '=' => return "=",
            ';' => return ";",
            '(' => return "(",
            ')' => return ")",
            ',' => return ",",
            '+' => return "+",
            '{' => return "{",
            '}' => return "}",
            else => return "",
        }
    }
};



test "lexing" {
    const input = "=+(){},;";

    const expected = [_]Token{
        Token{ .type = TokenType.assign, .literal = "=" },
        Token{ .type = TokenType.plus, .literal = "+" },
        Token{ .type = TokenType.lparen, .literal = "(" },
        Token{ .type = TokenType.rparen, .literal = ")" },
        Token{ .type = TokenType.lbrace, .literal = "{" },
        Token{ .type = TokenType.rbrace, .literal = "}" },
        Token{ .type = TokenType.comma, .literal = "," },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.eof, .literal = "" },
    };

    // Create lexer
    var lexer = Lexer{
        .input = input,
    };

    try lexer.readChar();

    for (0..expected.len) |i| {
        const tok = try lexer.nextToken();

        try testType(expected[i].type, tok.type);
        try testLiteral(expected[i].literal, tok.literal);
    }

}

fn testType(expected: TokenType, got: TokenType) !void {
    std.testing.expectEqual(expected, got) catch |err| {
        std.debug.print("[Type] Expected: '{any}', Got: '{any}'\n", .{expected, got});        
        return err;
    };
}

fn testLiteral(expected: []const u8, got: []const u8) !void {
    std.testing.expectEqual(expected, got) catch |err| {
        std.debug.print("[Literal] Expected: '{s}', Got: '{s}'\n", .{expected, got});        
        return err;
    };
}

