-- Awesome Functions

local gears     = require("gears")
local wibox     = require("wibox")
local naughty   = require("naughty")

-- {{{ Escape string
function escape(text)
    local xml_entities = {
        ["\""] = "&quot;",
        ["&"]  = "&amp;",
        ["'"]  = "&apos;",
        ["<"]  = "&lt;",
        [">"]  = "&gt;"
    }

    return text and text:gsub("[\"&'<>]", xml_entities)
end
-- }}}
-- {{{ Bold
function bold(text)
    return '<b>' .. text .. '</b>'
end
-- }}}
-- {{{ Italic
function italic(text)
    return '<i>' .. text .. '</i>'
end
-- }}}
-- {{{ Foreground color
function fgc(text,color)
    if not color then color = 'white' end
    if not text  then text  = 'NULL'  end
    return '<span color="'..color..'">'..text..'</span>'
end
-- }}}
-- {{{ Uppercase first letter of string
function ucfirst(str)
    return (str:gsub("^%l", string.upper))
end
-- }}}
-- {{{ Process read (io.popen wrapper)
function pread(cmd)
    if cmd and cmd ~= '' then
        local f, err = io.popen(cmd, 'r')
        if f then
            local s = f:read('*all')
            f:close()
            return s
        else
            loglua("(EE) pread failed reading '"..cmd.."', the error was '"..err.."'.")
        end
    end
end
-- }}}
-- {{{ File read (io.open wrapper)
function fread(cmd)
    if cmd and cmd ~= '' then
        local f, err = io.open(cmd, 'r')
        if f then
            local s = f:read('*all')
            f:close()
            return s
        else
            loglua("(EE) fread failed reading '"..cmd.."', the error was '"..err.."'.")
        end
    end
end
-- }}}
-- {{{ popup, a naughty wrapper
function popup(title,text,timeout,icon,position,fg,gb)
    -- pop must be global so we can find it and kill it anywhere
    pop = naughty.notify({ title     = title
                         , text      = text     or "All your base are belong to us."
                         , timeout   = timeout  or 0
                         , icon      = icon     or imgdir..'awesome-icon.png'
                         , icon_size = 39 -- 3 times our standard icon size
                         , position  = position or nil
                         , fg        = fg       or beautiful.fg_normal
                         , bg        = bg       or beautiful.bg_normal
                         })
end
-- }}}
-- {{{ Destroy all naughty notifications
function desnaug()
    for p,pos in pairs(naughty.notifications[mouse.screen]) do
        for i,notification in pairs(naughty.notifications[mouse.screen][p]) do
            naughty.destroy(notification)
            desnaug() -- call itself recursively until the total annihilation
        end
    end
end
-- }}}
-- {{{ Sets a random maximized wallpaper
function randwall(dir)
    local walls = {}
    for file in io.popen('ls '..dir):lines() do
        table.insert(walls, dir..file)
    end
    math.randomseed(os.time()+#walls)
    for s = 1, screen.count() do
        gears.wallpaper.maximized(walls[math.random(#walls)], s, true)
    end
end
-- }}}
-- {{{ Sets a random tiled wallpaper
function randtile(dir)
    local walls = {}
    for file in io.popen('ls '..dir):lines() do
        table.insert(walls, dir..file)
    end
    math.randomseed(os.time()+#walls)
    for s = 1, screen.count() do
        gears.wallpaper.tiled(walls[math.random(#walls)], s)
    end
end
-- }}}
-- {{{ Converts bytes to human-readable units, returns value (number) and unit (string)
function bytestoh(bytes)
    local tUnits={"K","M","G","T","P"} -- MUST be enough. :D
    local v,u
    for k = #tUnits,1,-1 do
        if math.fmod(bytes,1024^k) ~= bytes then v=bytes/(1024^k); u=tUnits[k] break end
    end
    return v or bytes,u or "B"
end
-- }}}
-- {{{ Returns all variables for debugging purposes
function dbg(vars)
    local text = ""
    for i=1, #vars do text = text..vars[i].." | " end
    naughty.notify({ text = text, timeout = 0 })
end
-- }}}

-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
