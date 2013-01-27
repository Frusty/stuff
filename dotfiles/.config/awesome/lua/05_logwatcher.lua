-- http://awesome.naquadah.org/wiki/Naughty_log_watcher
-- http://www3.telus.net/taj_khattra/luainotify.html
-- Compile inotify.so and copy it into into /usr/lib/lua/5.2

-- That variable is already defined on 03_widgetbar.lua
enable_logs = false
local config = {}
config.logs  = { IPTABLES = { file = "/var/log/iptables.log" }
               , AUTH     = { file = "/var/log/auth.log" }
               , ERRORS   = { file = "/var/log/errors.log" }
               , XORG     = { file = "/var/log/Xorg.0.log" }
               , DAEMON   = { file = "/var/log/daemon.log" }
               , KERNEL   = { file = "/var/log/kernel.log"
                            , ignore = { "DROP" }
                            }
               , AWESOME  = { file = logfile
                            , ignore = { "^Simple mixer" -- amixer output
                                       , "pcmanfm" -- pcmanfm is really noisy
                                       , "^volume: " -- mpc output
                                       , "draw_text_context_init:108:" -- A MUST
                                       , "unable to open slave" -- Youtube arguing
                                       }
                            }
               }

function log_watch()
    if not enable_logs then return; end
    local events, nread, errno, errstr = inot:nbread()
    if events then
        for i, event in ipairs(events) do
            for logname, log in pairs(config.logs) do
                if event.wd == log.wd then log_changed(logname) end
            end
        end
    end
end

function log_changed(logname)
    if not enable_logs then return; end
    local log = config.logs[logname]
    -- read log file
    local f, err = io.open(log.file, 'r')
    if err then
        loglua('(WW) log_changed can\'t open "'..log.file..'" - '..err)
        return
    end
    local l = f:read("*a")
    f:close()
    -- first read just set length
    if not log.len then log.len = #l
    -- if updated
    else
        local diff = l:sub(log.len +1, #l-1)
        -- check if ignored
        local ignored = false
        for i, phr in ipairs(log.ignore or {}) do
            if diff:find(phr) then ignored = true; break end
        end
        -- display log updates
        if diff and diff ~= '' and not ignored then
            naughty.notify{ title = '<span color="white">' .. logname .. ":</span> "..log.file
                          , text = awful.util.escape(diff)
                          , icon = imgdir..'bomb.png'
                          , timeout = 10
                          , run = function (n)
--                                awful.util.spawn(terminal..' -e '..editor..' '..log.file)
                                n.die()
                            end
                          }
        end
        -- set last length
        log.len = #l
    end
end

--if exists(inotify_so) and enable_logs then
if enable_logs then
    require("inotify")
    local errno, errstr
    inot, errno, errstr = inotify.init(true)
    for logname, log in pairs(config.logs) do
        log_changed(logname)
        log.wd, errno, errstr = inot:add_watch(log.file, {"IN_MODIFY"})
    end
    timerlog = timer { timeout = 1 }
    timerlog:connect_signal("timeout", log_watch)
    timerlog:start()
end

-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
