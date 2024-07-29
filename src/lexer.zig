const std = @import("std");
const token_lib = @import("./token.zig");
const Token = token_lib.Token;
const TokenType = token_lib.TokenType;

pub const Lexer = struct {
    input: []const u8,
    position: usize = 0,
    read_pos: usize = 0,
    ch: u8 = undefined,
    allocator: std.mem.Allocator,

    pub fn readChar(self: *Lexer) void {
        if (self.read_pos >= self.input.len) self.ch = 0 else self.ch = self.input[self.read_pos];
        self.position = self.read_pos;
        self.read_pos += 1;
    }

    pub fn nextToken(self: *Lexer) !Token {
        var token: Token = .{};

        self.skipWhitespace();

        switch(self.ch) {
            '=' => {
                if (self.peekChar() != '=') token.init(TokenType.assign, getConstantLiteral(self.ch))
                else {
                    self.readChar();
                    token.init(TokenType.eq, "==");
                }
            },
            ';' => token.init(TokenType.semicolon, getConstantLiteral(self.ch)),
            '(' => token.init(TokenType.lparen, getConstantLiteral(self.ch)),
            ')' => token.init(TokenType.rparen, getConstantLiteral(self.ch)),
            ',' => token.init(TokenType.comma, getConstantLiteral(self.ch)),
            '+' => token.init(TokenType.plus, getConstantLiteral(self.ch)),
            '{' => token.init(TokenType.lbrace, getConstantLiteral(self.ch)),
            '}' => token.init(TokenType.rbrace, getConstantLiteral(self.ch)),
            '-' => token.init(TokenType.minus, getConstantLiteral(self.ch)),
            '*' => token.init(TokenType.asterisk, getConstantLiteral(self.ch)),
            '/' => token.init(TokenType.slash, getConstantLiteral(self.ch)),
            '!' => {
                if (self.peekChar() != '=') token.init(TokenType.bang, getConstantLiteral(self.ch))
                else {
                    self.readChar();
                    token.init(TokenType.not_eq, "!=");
                }
            },
            '>' => token.init(TokenType.gt, getConstantLiteral(self.ch)),
            '<' => token.init(TokenType.lt, getConstantLiteral(self.ch)),
            0 => token.init(TokenType.eof, getConstantLiteral(0)),
            else => {
                if (std.ascii.isAlphabetic(self.ch) or self.ch == '_') {
                    const ident = self.readIdentifier();
                    const t = try token.lookupIdent(ident);
                    token.init(t, ident);
                } else if (std.ascii.isDigit(self.ch)) {
                    token.init(TokenType.int, self.readNumber());
                }
            },
        }

        self.readChar();

        return token;
    }

    fn readIdentifier(self: *Lexer) []const u8 {
        const pos: usize = self.position;
        while(std.ascii.isAlphanumeric(self.ch) or self.ch == '_') {
            self.readChar();
        }
        // Adjust position. If not adjusted it skips semicolons. 
        self.position -= 1;
        self.read_pos -= 1;
        return self.input[pos..self.position + 1];
    }

    fn readNumber(self: *Lexer) []const u8 {
        const pos: usize = self.position;
        while(std.ascii.isDigit(self.ch)) {
            self.readChar();
        }
        self.position -= 1;
        self.read_pos -= 1;
        return self.input[pos..self.position + 1];
    }

    fn skipWhitespace(self: *Lexer) void {
        while(self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r') {
            self.readChar();
        }
    }

    fn peekChar(self: *Lexer) u8 {
        if (self.read_pos >= self.input.len) return 0 else return self.input[self.read_pos];
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
            '-' => return "-",
            '*' => return "*",
            '/' => return "/",
            '!' => return "!",
            '<' => return "<",
            '>' => return ">",
            else => return "",
        }
    }
};



test "lexing" {
    const allocator = std.testing.allocator;

    const input = 
        \\let five= 5;
        \\let ten = 10;
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\if (5 < 10) {
        \\  return true;
        \\} else {
        \\  return false;
        \\}
        \\10 == 10;
        \\10 != 9;
    ;

    const expected = [_]Token{
        Token{ .type = TokenType.let, .literal = "let" },
        Token{ .type = TokenType.ident, .literal = "five" },
        Token{ .type = TokenType.assign, .literal = "=" },
        Token{ .type = TokenType.int, .literal = "5" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.let, .literal = "let" },
        Token{ .type = TokenType.ident, .literal = "ten" },
        Token{ .type = TokenType.assign, .literal = "=" },
        Token{ .type = TokenType.int, .literal = "10" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.let, .literal = "let" },
        Token{ .type = TokenType.ident, .literal = "add" },
        Token{ .type = TokenType.assign, .literal = "=" },
        Token{ .type = TokenType.function, .literal = "fn" },
        Token{ .type = TokenType.lparen, .literal = "(" },
        Token{ .type = TokenType.ident, .literal = "x" },
        Token{ .type = TokenType.comma, .literal = "," },
        Token{ .type = TokenType.ident, .literal = "y" },
        Token{ .type = TokenType.rparen, .literal = ")" },
        Token{ .type = TokenType.lbrace, .literal = "{" },
        Token{ .type = TokenType.ident, .literal = "x" },
        Token{ .type = TokenType.plus, .literal = "+" },
        Token{ .type = TokenType.ident, .literal = "y" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.rbrace, .literal = "}" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.let, .literal = "let" },
        Token{ .type = TokenType.ident, .literal = "result" },
        Token{ .type = TokenType.assign, .literal = "=" },
        Token{ .type = TokenType.ident, .literal = "add" },
        Token{ .type = TokenType.lparen, .literal = "(" },
        Token{ .type = TokenType.ident, .literal = "five" },
        Token{ .type = TokenType.comma, .literal = "," },
        Token{ .type = TokenType.ident, .literal = "ten" },
        Token{ .type = TokenType.rparen, .literal = ")" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.bang, .literal = "!" },
        Token{ .type = TokenType.minus, .literal = "-" },
        Token{ .type = TokenType.slash, .literal = "/" },
        Token{ .type = TokenType.asterisk, .literal = "*" },
        Token{ .type = TokenType.int, .literal = "5" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.int, .literal = "5" },
        Token{ .type = TokenType.lt, .literal = "<" },
        Token{ .type = TokenType.int, .literal = "10" },
        Token{ .type = TokenType.gt, .literal = ">" },
        Token{ .type = TokenType.int, .literal = "5" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType._if, .literal = "if" },
        Token{ .type = TokenType.lparen, .literal = "(" },
        Token{ .type = TokenType.int, .literal = "5" },
        Token{ .type = TokenType.lt, .literal = "<" },
        Token{ .type = TokenType.int, .literal = "10" },
        Token{ .type = TokenType.rparen, .literal = ")" },
        Token{ .type = TokenType.lbrace, .literal = "{" },
        Token{ .type = TokenType._return, .literal = "return" },
        Token{ .type = TokenType.true, .literal = "true" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.rbrace, .literal = "}" },
        Token{ .type = TokenType._else, .literal = "else" },
        Token{ .type = TokenType.lbrace, .literal = "{" },
        Token{ .type = TokenType._return, .literal = "return" },
        Token{ .type = TokenType.false, .literal = "false" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.rbrace, .literal = "}" },
        Token{ .type = TokenType.int, .literal = "10" },
        Token{ .type = TokenType.eq, .literal = "==" },
        Token{ .type = TokenType.int, .literal = "10" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.int, .literal = "10" },
        Token{ .type = TokenType.not_eq, .literal = "!=" },
        Token{ .type = TokenType.int, .literal = "9" },
        Token{ .type = TokenType.semicolon, .literal = ";" },
        Token{ .type = TokenType.eof, .literal = "" },
    };

    // Create lexer
    var lexer = Lexer{
        .input = input,
        .allocator = allocator,
    };

    lexer.readChar();

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
    std.testing.expectEqualStrings(expected, got) catch |err| {
        std.debug.print("[Literal] Expected: '{s}', Got: '{s}'\n", .{expected, got});        
        return err;
    };
}

