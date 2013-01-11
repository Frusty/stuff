-- Awesome random theme function

-- Theme handling library¶
local beautiful = require("beautiful")

-- Choose and load a random theme from themedir
function rndtheme()
    local themes = {}
    for file in io.popen('ls '..themedir..'*lua'):lines() do
        table.insert(themes, file)
    end
    math.randomseed(os.time()+#themes)
    beautiful.init(themes[math.random(#themes)])
end

--  1st call
rndtheme();

-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
