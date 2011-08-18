-- https://github.com/cycojesus/awesome/raw/master/rc.lua
-- {{{ Base Variables
homedir    = os.getenv("HOME")..'/'
logfile    = homedir..'.awesome.err'
confdir    = homedir..'.config/awesome/'
luadir     = confdir..'lua/'
themedir   = confdir..'themes/'
imgdir     = confdir..'imgs/'
tiledir    = confdir..'tiles/'
walldir    = confdir..'walls/'
browser    = os.getenv("BROWSER") or "chromium"
terminal   = os.getenv("TERMINAL") or "xterm"
editor     = os.getenv("EDITOR") or "vim"
editor_cmd = terminal.." -e "..editor

setrndwall = "awsetbg -u feh -r "..walldir
setrndtile = "awsetbg -u feh -t -r "..tiledir
-- }}}
-- {{{ Base Functions
function loglua(msg)
    if not msg then cmd = "No error message was specified." end
    local f = io.open(logfile, "a")
    f:write("["..os.date("%Y/%m/%d %H:%M:%S").."] - "..msg.."\n")
    f:close()
end
function exists(fname)
    local f = io.open(fname, "r")
    if (f and f:read()) then
        return true
    else
        loglua("(WW) Couldn't open '"..fname.."'")
    end
end
function try(file, backup, logfile)
--    if exists(file) and exists(logfile) then
        -- if it breaks do not die in shame, just squeak gracefully
        local rc, err = loadfile(file)
        if rc then
            rc, err = pcall(rc)
           if rc then return; end
        end
        if backup then dofile(backup) end
        loglua("(EE) Couldn't load '"..file.."', reverting to '"..backup.."'. The error was: "..err)
--    end
end
-- }}}
loglua("(II) AWESOME STARTING")
-- {{{ Evaluate and load config files
for file in io.popen('ls '..luadir..'*lua'):lines() do
    loglua("(II) Loading config files: "..file)
    try( file
       , "/etc/xdg/awesome/rc.lua"
       , logfile
       )
end
-- }}}
-- {{{ Programs to execute on startup
loglua("(II) Launching external aplications.")
os.execute("wmname LG3D&") -- https://awesome.naquadah.org/wiki/Problems_with_Java
-- }}}
loglua("(II) STARTUP FINISHED")
-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
