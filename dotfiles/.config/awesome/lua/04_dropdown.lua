-- Create, show and hide floating clients
-- http://awesome.naquadah.org/wiki/Drop-down_terminal

local awful = require("awful")
local capi  = { mouse  = mouse
              , client = client
              , screen = screen
              }
local dropdown = {}

-- Create a new window for the drop-down application when it doesn't
-- exist, or toggle between hidden and visible states when it does.
function toggle(prog,height,sticky,screen)
    local height = height or 0.3 -- 30%
    local sticky = sticky or false
    local screen = screen or capi.mouse.screen
    if not dropdown[prog] then
        dropdown[prog] = {}
        -- Add unmanage signal for teardrop programs
        capi.client.connect_signal("unmanage", function (c)
            for scr, cl in pairs(dropdown[prog]) do
                if cl == c then
                    dropdown[prog][scr] = nil
                end
            end
        end)
    end
    if not dropdown[prog][screen] then
        spawnw = function (c)
            dropdown[prog][screen] = c
            -- Teardrop clients are floaters
            awful.client.floating.set(c, true)
            -- Client geometry
            local screengeom = capi.screen[screen].workarea
            if height < 1 then
                height = screengeom.height * height
            else
                height = screengeom.height
            end
            -- Client properties
            c:geometry({ x = screengeom.x/2, y = 0, width = screengeom.width, height = height })
            c.ontop = true
            c.above = true
            c.skip_taskbar = true
            if sticky then c.sticky = true end
            if c.titlebar then awful.titlebar.remove(c) end
            c:raise()
            capi.client.focus = c
            capi.client.disconnect_signal("manage", spawnw)
        end
        -- Add manage signal and spawn the program
        capi.client.connect_signal("manage", spawnw)
        awful.util.spawn(prog, false)
    else
        -- Get a running client
        c = dropdown[prog][screen]
        -- Switch the client to the current workspace
        if c:isvisible() == false then c.hidden = true;
            awful.client.movetotag(awful.tag.selected(screen), c)
        end
        -- Focus and raise if hidden
        if c.hidden then
            c.hidden = false
            c:raise()
            capi.client.focus = c
        else -- Hide and detach tags if not
            c.hidden = true
            local ctags = c:tags()
            for i, v in pairs(ctags) do
                ctags[i] = nil
            end
            c:tags(ctags)
        end
    end
end

-- Merge some keybinding to the globalkeys table
globalkeys = awful.util.table.join(globalkeys
                                  , awful.key({ modkey,           }, "#49", function () toggle(terminal) end) -- tecla º Quake Style
                                  , awful.key({ modkey, "Control" }, "#49", function () toggle(browser) end)   -- Plus CTRL
                                  )
-- Actually apply the keybindings
root.keys(globalkeys)

-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
