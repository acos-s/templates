local stdio = require("@lune/stdio")
local process = require("@lune/process")

local c = stdio.color
local s = stdio.style

local log; log = {
    color = c,
    style = s,
    reset = c("reset") .. s("reset"),
    error = function(message: string, ending: string?)
        ending = ending or "\n"
        stdio.ewrite(`{c("red")}{s("bold") .. "error" .. s("reset")} ∙ {message}{log.reset}{ending}`)
    end,
    fatal = function(message: string, ending: string?)
        log.error(message, ending)
        process.exit(1)
    end,
    info = function(message: string, ending: string?)
        ending = ending or "\n"
        stdio.write(`{c("blue")}{s("bold") .. "info" .. s("reset")} ∙ {message}{log.reset}{ending}`)
    end,
    warn = function(message: string, ending: string?)
        ending = ending or "\n"
        stdio.write(`{c("yellow")}{s("bold") .. "warn" .. s("reset")} ∙ {message}{log.reset}{ending}`)
    end,
    debug = function(message: string, ending: string?)
        ending = ending or "\n"
        stdio.write(`{s("bold") .. "debug" .. s("reset")} ∙ {message}{log.reset}{ending}`)
    end
}

return log