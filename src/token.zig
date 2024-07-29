pub const TokenType = enum {
    illegal,
    eof,

    // Identifiers + literals
    ident,
    int,

    // Operators
    assign,
    plus,

    // Delimiters
    comma,
    semicolon,

    lparen,
    rparen,
    lbrace,
    rbrace,

    // Keywords
    function,
    let,
};

pub const Token = struct {
    type: TokenType = TokenType.illegal,
    literal: []const u8 = undefined,

    pub fn init(self: *Token, t: TokenType, literal: []const u8) void {
        self.type = t;
        self.literal = literal;
    }
};
