-- Awesome extra keybindings

-- I'll upgrade the keybindins merging the current "globalkeys" table with my own
-- Keycodes can be seen using the 'xev' command

local awful = require("awful")

globalkeys = awful.util.table.join( globalkeys
                                    , awful.key({ modkey,           }, "Print",      function () toggle('scrot -e geeqie') end) -- Print Screen
                                    , awful.key({ modkey,           }, "BackSpace",  function () awful.util.spawn('urxvt -pe tabbed') end)
                                    , awful.key({ modkey, "Control" }, "w",          function () randwall(walldir) end)
                                    , awful.key({ modkey, "Control" }, "e",          function () randtile(tiledir) end)
                                    , awful.key({ modkey, "Control" }, "d",          function () rndtheme() end)
                                    , awful.key({ modkey, "Control" }, "q",          function () awful.util.spawn(setwall) end)
                                    , awful.key({ modkey, "Control" }, "t",          function () awful.util.spawn('pcmanfm') end)
                                    , awful.key({ modkey, "Control" }, "p",          function () awful.util.spawn('pidgin') end)
                                    , awful.key({ modkey, "Control" }, "c",          function () awful.util.spawn(terminal..' -e mc') end)
                                    , awful.key({ modkey, "Control" }, "f",          function () awful.util.spawn(browser) end)
                                    , awful.key({ modkey, "Control" }, "g",          function () awful.util.spawn('gvim') end)
                                    , awful.key({ modkey, "Control" }, "x",          function () awful.util.spawn('vlock -an') end)
                                    , awful.key({ modkey, "Control" }, "v",          function () awful.util.spawn(terminal..' -e ncmpcpp') end)
                                    , awful.key({ modkey, "Control" }, "0",          function () awful.util.spawn('xrandr -o left') end)
                                    , awful.key({ modkey, "Control" }, "'",          function () awful.util.spawn('xrandr -o normal') end)
                                    , awful.key({ modkey, "Control" }, "exclamdown", function () awful.util.spawn('xrandr --output VGA1 --mode 1280x1024') end)
                                    , awful.key({ modkey, "Control" }, "b",          function () awful.util.spawn('mpc play') end)
                                    , awful.key({ modkey, "Control" }, "n",          function () awful.util.spawn('mpc pause') end)
                                    , awful.key({ modkey, "Control" }, "m",          function () awful.util.spawn('mpc prev') end)
                                    , awful.key({ modkey, "Control" }, ",",          function () awful.util.spawn('mpc next') end)
                                    , awful.key({ modkey, "Control" }, ".",          function () awful.util.spawn('amixer -c 0 set '..sdev..' 3dB-'); get_vol() end)
                                    , awful.key({ modkey, "Control" }, "-",          function () awful.util.spawn('amixer -c 0 set '..sdev..' 3dB+'); get_vol() end)
                                    , awful.key({ modkey, "Control" }, "Down",       function () awful.client.swap.byidx(1) end)
                                    , awful.key({ modkey, "Control" }, "Up",         function () awful.client.swap.byidx(-1) end)
                                    , awful.key({ modkey, "Control" }, "Left",       function () awful.tag.incnmaster(1) end)
                                    , awful.key({ modkey, "Control" }, "Right",      function () awful.tag.incnmaster(-1) end)
                                    , awful.key({ modkey }           , "Down",       function () awful.client.focus.byidx(1); if client.focus then client.focus:raise() end end)
                                    , awful.key({ modkey }           , "Up",         function () awful.client.focus.byidx(-1); if client.focus then client.focus:raise() end end)
                                    )
-- Actually apply the keybindings
root.keys(globalkeys)

-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
