-- Choose and loaf a random theme from themedir

-- Theme handling library¶
require("beautiful")

themes = {}
for file in io.popen('ls '..themedir..'*lua'):lines() do
    table.insert(themes, file)
end
math.randomseed(os.time()+table.getn(themes))
beautiful.init(themes[math.random(#themes)])

-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
