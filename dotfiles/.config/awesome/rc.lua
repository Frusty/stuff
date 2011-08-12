-- https://github.com/cycojesus/awesome/raw/master/rc.lua
--
logfile = os.getenv("HOME") .."/.awesome.err"
confdir = os.getenv("HOME").."/.config/awesome/"
-- {{{ logerr function
function logerr(msg)
    if not msg then cmd = "No error message was specified." end
    local f = io.open(logfile, "w+")
    f:write("["..os.date("%Y/%m/%d %H:%M:%S").."] - "..msg.."\n")
    f:close()
end
-- }}}
-- {{{ try function
function try(file, backup, logfile)
   -- if it breaks do not die in shame, just squeak gracefully
   local rc, err = loadfile(file)
   if rc then
       rc, err = pcall(rc)
      if rc then return; end
   end
   if backup then dofile(backup) end
   logerr("AWESOME CRASH DURING STARTUP - "..err)
end
-- }}}
-- {{{ Main config
-- Programas a lanzar al final.
try( confdir.."awesome.lua"
   , "/etc/xdg/awesome/rc.lua"
   , logfile
   )
-- }}}
-- {{{ Widget Bar
try( confdir.."extra.lua"
   , "/etc/xdg/awesome/rc.lua"
   , logfile
   )
-- }}}
-- {{{ Autostart
--  Programas a lanzar al final.
awful.util.spawn_with_shell("wmname LG3D") -- https://awesome.naquadah.org/wiki/Problems_with_Java
-- }}}
--
-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
