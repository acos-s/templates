-- Filter expression parser for test filtering
-- Supports: term, not, and, or, parentheses
-- Precedence: NOT > AND > OR

local log = require("./log")

local filter = {}

export type FilterExpr =
    { type: "term", value: string }
    | { type: "not", expr: FilterExpr }
    | { type: "and", left: FilterExpr, right: FilterExpr }
    | { type: "or", left: FilterExpr, right: FilterExpr }

local function tokenize(input: string): { string }
    local tokens = {}
    local i = 1
    local len = #input

    while i <= len do
        local char = string.sub(input, i, i)

        if char == " " or char == "\t" then
            i += 1
        elseif char == "(" or char == ")" then
            table.insert(tokens, char)
            i += 1
        else
            local word = ""
            while i <= len do
                local c = string.sub(input, i, i)
                if c == " " or c == "\t" or c == "(" or c == ")" then
                    break
                end
                word = word .. c
                i += 1
            end
            if #word > 0 then
                table.insert(tokens, word)
            end
        end
    end

    return tokens
end

local function peek(tokens: { string }, index: number): string?
    return tokens[index]
end

local function consume(tokens: { string }, index: number): (string, number)
    return tokens[index], index + 1
end

local parse_expression: ( { string }, number) -> (FilterExpr, number)
local parse_or: ( { string }, number) -> (FilterExpr, number)
local parse_and: ( { string }, number) -> (FilterExpr, number)
local parse_unary: ( { string }, number) -> (FilterExpr, number)
local parse_primary: ( { string }, number) -> (FilterExpr, number)

function parse_expression(tokens: { string }, index: number): (FilterExpr, number)
    return parse_or(tokens, index)
end

function parse_or(tokens: { string }, index: number): (FilterExpr, number)
    local left, new_index = parse_and(tokens, index)

    while true do
        local tok = peek(tokens, new_index)
        if tok == nil or tok:lower() ~= "or" then
            break
        end
        local _, consumed = consume(tokens, new_index)
        local right
        right, new_index = parse_and(tokens, consumed)
        left = { type = "or", left = left, right = right }
    end

    return left, new_index
end

function parse_and(tokens: { string }, index: number): (FilterExpr, number)
    local left, new_index = parse_unary(tokens, index)

    while true do
        local tok = peek(tokens, new_index)
        if tok == nil or tok:lower() ~= "and" then
            break
        end
        local _, consumed = consume(tokens, new_index)
        local right
        right, new_index = parse_unary(tokens, consumed)
        left = { type = "and", left = left, right = right }
    end

    return left, new_index
end

function parse_unary(tokens: { string }, index: number): (FilterExpr, number)
    local tok = peek(tokens, index)

    if tok and tok:lower() == "not" then
        local _, consumed = consume(tokens, index)
        local expr
        expr, consumed = parse_unary(tokens, consumed)
        return { type = "not", expr = expr }, consumed
    end

    return parse_primary(tokens, index)
end

function parse_primary(tokens: { string }, index: number): (FilterExpr, number)
    local tok = peek(tokens, index)

    if tok == nil then
        log.fatal("Unexpected end of filter expression")
    end

    if tok == "(" then
        local _, consumed = consume(tokens, index)
        local expr
        expr, consumed = parse_expression(tokens, consumed)
        local next_tok = peek(tokens, consumed)
        if next_tok ~= ")" then
            log.fatal("Expected ')' in filter expression")
        end
        local _, after_paren = consume(tokens, consumed)
        return expr, after_paren
    end

    if tok == "(" or tok == ")" or tok:lower() == "and" or tok:lower() == "or" or tok:lower() == "not" then
        log.fatal(`Unexpected token '{tok}' in filter expression`)
    end

    local _, consumed = consume(tokens, index)
    return { type = "term", value = tok }, consumed
end

function filter.parse(input: string): FilterExpr
    if #input == 0 then
        return { type = "term", value = "" }
    end

    local tokens = tokenize(input)
    if #tokens == 0 then
        return { type = "term", value = "" }
    end

    local expr, index = parse_expression(tokens, 1)
    if peek(tokens, index) ~= nil then
        log.fatal(`Unexpected token '{peek(tokens, index)}' at position {index}`)
    end

    return expr
end

local function matches_term(term: string, test_name: string, suite_name: string): boolean
    local lower_term = string.lower(term)
    local lower_test = string.lower(test_name)
    local lower_suite = string.lower(suite_name)
    return string.find(lower_test, lower_term, 1, true) ~= nil
        or string.find(lower_suite, lower_term, 1, true) ~= nil
end

function filter.matches(expr: FilterExpr, test_name: string, suite_name: string): boolean
    if expr.type == "term" then
        if #expr.value == 0 then
            return true
        end
        return matches_term(expr.value, test_name, suite_name)
    elseif expr.type == "not" then
        return not filter.matches(expr.expr, test_name, suite_name)
    elseif expr.type == "and" then
        return filter.matches(expr.left, test_name, suite_name)
            and filter.matches(expr.right, test_name, suite_name)
    elseif expr.type == "or" then
        return filter.matches(expr.left, test_name, suite_name)
            or filter.matches(expr.right, test_name, suite_name)
    end
    return false
end

return filter