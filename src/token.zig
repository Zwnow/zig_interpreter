const std = @import("std");

pub const TokenType = enum {
    illegal,
    eof,

    // Identifiers + literals
    ident,
    int,

    // Operators
    assign,
    plus,
    minus,
    bang,
    asterisk,
    slash,

    lt, //less than
    gt, //greater than
    eq,
    not_eq,

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
    true,
    false,
    _if,
    _else,
    _return,
};

pub const Token = struct {
    type: TokenType = TokenType.illegal,
    literal: []const u8 = undefined,

    pub fn init(self: *Token, t: TokenType, literal: []const u8) void {
        self.type = t;
        self.literal = literal;
    }

    // TODO, find out how to create global hash map, so it doesn't have
    // to init one on every token
    pub fn lookupIdent(self: *Token, literal: []const u8) !TokenType {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        var Keywords = std.hash_map.StringHashMap(TokenType).init(allocator);
        defer Keywords.deinit();
        try Keywords.put("fn", TokenType.function);
        try Keywords.put("let", TokenType.let);
        try Keywords.put("true", TokenType.true);
        try Keywords.put("false", TokenType.false);
        try Keywords.put("if", TokenType._if);
        try Keywords.put("else", TokenType._else);
        try Keywords.put("return", TokenType._return);

        _ = self;
        if (Keywords.get(literal)) |val| {
            return val;
        }
        return TokenType.ident;
    }
};
