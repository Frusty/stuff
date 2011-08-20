-- Global utility functions

-- Notification library¶
require("naughty")

-- {{{ Escape string
function escape(text)
    if text then
        return awful.util.escape(text or 'UNKNOWN')
    end
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
-- {{{ Process read (io.popen wrapper)
function pread(cmd)
    if cmd and cmd ~= '' then
        local f, err = io.popen(cmd, 'r')
        if f then
            local s = f:read('*all')
            f:close()
            return s
        else
            loglua(err)
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
            loglua(err)
        end
    end
end
-- }}}
-- {{{ Apply a random theme from themedir
function rndtheme()
    local themes = {}
    for file in io.popen('ls '..themedir..'*lua'):lines() do
        table.insert(themes, file)
    end
    math.randomseed(os.time()+table.getn(themes))
    beautiful.init(themes[math.random(#themes)])
end
-- }}}
-- {{{ Icon creation wrapper
function createIco(widget,file,click)
    if not widget or not file or not click then return nil end
    widget.image = image(imgdir..'/'..file)
    widget.resize = false
    awful.widget.layout.margins[widget] = { top = 1, bottom = 1, left = 1, right = 1 }
    widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function ()
            awful.util.spawn(click,false)
        end)
    ))
end
-- }}}
-- {{{ popup, a naughty wrapper
function popup(title,text,timeout,icon,position,fg,gb)
    pop = naughty.notify({ title     = title
                         , text      = text     or "All your base are belong to us."
                         , timeout   = timeout  or 0
                         , icon      = icon     or imgdir..'awesome.png'
                         , icon_size = 39 -- 3 times our standard icon size
                         , position  = position or nil
                         , fg        = fg       or beautiful.fg_focus
                         , bg        = bg       or beautiful.bg_focus
                         })
end
-- }}}
-- {{{ Destroy all naughty notifications
function desnaug()
    for p,pos in pairs(naughty.notifications[mouse.screen]) do
        for i,notification in pairs(naughty.notifications[mouse.screen][p]) do
            naughty.destroy(notification)
            desnaug()
        end
    end
end
-- }}}
-- {{{ Converts bytes to human-readable units, returns value (number) and unit (string)
function bytestoh(bytes)
    local tUnits={"K","M","G","T","P"} -- MUST be enough. :D
    local v,u
    for k=table.getn(tUnits),1,-1 do
        if math.fmod(bytes,1024^k) ~= bytes then v=bytes/(1024^k); u=tUnits[k] break end
    end
    return v or bytes,u or "B"
end
-- }}}
-- {{{ Returns all variables for debugging purposes
function dbg(vars)
    local text = ""
    for i=1, #vars do text = text .. vars[i] .. " | " end
    naughty.notify({ text = text, timeout = 0 })
end
-- }}}

-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
