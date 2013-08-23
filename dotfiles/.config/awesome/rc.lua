-- https://github.com/cycojesus/awesome/raw/master/rc.lua

-- {{{ Base Variables
user       = os.getenv("USER")
browser    = os.getenv("BROWSER")  or "chromium"
terminal   = os.getenv("TERMINAL") or "xterm"
editor     = os.getenv("EDITOR")   or "vim"
homedir    = os.getenv("HOME")..'/'
logfile    = homedir..'.awesome.err'
confdir    = homedir..'.config/awesome/'
luadir     = confdir..'lua/'
themedir   = confdir..'themes/'
imgdir     = confdir..'imgs/'
tiledir    = confdir..'tiles/'
walldir    = confdir..'walls/'
editor_cmd = terminal.." -e "..editor
setrndwall = "awsetbg -u feh -r "..walldir
setrndtile = "awsetbg -u feh -t -r "..tiledir
-- }}}
-- {{{ Base Functions
function loglua(msg)
    if not msg then cmd = "No message was specified to loglua." end
    local f = io.open(logfile, "a")
    f:write("["..os.date("%Y/%m/%d %H:%M:%S").."] - "..msg.."\n")
    f:close()
end
function exists(fname)
    if not fname then return nil end
    local f = io.open(fname, "r")
    if (f and f:read()) then
        return true
    else
        loglua("(WW) Couldn't open '"..fname.."'")
        return nil
    end
end
-- loadfile/dofile Wrapper
-- Evaluate and load a file or fallback to another
function loadlua(file, backup)
    if exists(file) then
        local rc, err = loadfile(file)
        if rc then
            rc, err = pcall(rc)
            if rc then
                return true
            end
        end
        loglua("(EE) loadlua couldn't load '"..file.."'. The error was: "..err)
        if exists(backup) then
            loglua("(II) loadlua is reverting to '"..backup.."'.")
            loadlua(backup)
        end
    end
end
-- }}}
loglua("(II) AWESOME STARTUP")
-- {{{ Evaluate and load config files
for file in io.popen('ls '..luadir..'*lua'):lines() do
    loglua("(II) Loading config files: "..file)
    local result = loadlua(file, "/etc/xdg/awesome/rc.lua")
    if not result then break end
end
-- }}}
-- {{{ Programs to execute on startup
loglua("(II) Launching external aplications.")
os.execute("wmname LG3D&") -- https://awesome.naquadah.org/wiki/Problems_with_Java
-- }}}
loglua("(II) STARTUP FINISHED")

-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
