-- Awesome widgetbar

local gears   = require("gears")
local widget  = require("wibox")
local awful   = require("awful")
local wibox   = require("wibox")
local naughty = require("naughty")

-- {{{ Log Button (imagebox)
--------------------------------------------------------------------------------
-- Permite activar/desactivar los logs de 15_logwatcher.lua
-- inotify_so se declara en rc.lua
--  imagebox
local log_ico = createIco('log.png', terminal)
-- textbox
local logwidget = wibox.widget.textbox()
--
if exists(inotify_so) then
    logwidget:set_markup(fgc('ON', theme.font_value))
    enable_logs = true
else
    logwidget:set_markup(fgc('NA', theme.font_value))
    enable_logs = false
end
-- buttons
logwidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if exists(inotify_so) then
            if enable_logs then
                logwidget.text = fgc('NO', 'red')
                enable_logs = false
                popup( fgc('Awesome Notification:'), 'Logging Disabled', 5 )
            else
                logwidget.text = fgc('ON', theme.font_value)
                enable_logs = true
                popup( fgc('Awesome Notification:'), 'Logging Enabled', 5 )
            end
        else
            popup( fgc('Awesome Notification:'), "Can't find '"..inotify_so.."'. Logging Disabled.", 5 )
        end
    end)
))
-- }}}
-- {{{ GMail (imagebox+textbox) requires wget
--------------------------------------------------------------------------------
-- Datos de gmail
local mailadd  = 'oprietop@intranet.uoc.edu'
local mailpass = escape(fread(confdir..mailadd..'.passwd'))
local mailurl  = 'https://mail.google.com/a/intranet.uoc.edu/feed/atom/unread'
-- Actualiza el estado del widget a partir de un feed de gmail bajado.
local mailcount = 0
function check_gmail()
    local feed = fread(confdir..mailadd)
    local lcount = mailcount
    if feed:match('fullcount>%d+<') then
        lcount = feed:match('fullcount>(%d+)<')
    end
    if lcount ~= mailcount then
        for title,summary,name,email in feed:gmatch('<entry>\n<title>(.-)</title>\n<summary>(.-)</summary>.-<name>(.-)</name>\n<email>(.-)</email>') do
            popup( fgc('New mail on ')..mailadd
                 , name..' ('..email..')\n'..title..'\n'..summary
                 , 20
                 , imgdir..'yellow_mail.png'
                 )
        end
        mailcount = lcount
    end
    if tonumber(lcount) > 0 then
        return fgc(bold(lcount), 'red')
    else
        return fgc('0', theme.font_value)
    end
end
-- lanza un wget en background para bajar el feed de gmail.
function getMail()
    if confdir and mailadd and mailpass and mailurl then
        os.execute('wget '..mailurl..' -qO '..confdir..mailadd..' --http-user='..mailadd..' --http-passwd="'..mailpass..'"&')
    end
end
if mailpass then
    --  imagebox
    mail_ico = createIco('mail.png', browser..' '..mailurl..'"&')
    --  textbox
    mailwidget = wibox.widget.textbox()
    -- llamada inicial a la función
    mailwidget:set_markup(check_gmail())
    --  mouse_enter
    mailwidget:connect_signal("mouse::enter", function()
        mailcount = 0
        check_gmail()
    end)
    --  mouse_leave
    mailwidget:connect_signal("mouse::leave", function() desnaug() end)
    --  buttons
    mailwidget:buttons(awful.util.table.join(
        awful.button({ }, 1, function ()
            getMail()
            os.execute(browser..' "'..mailurl..'"&')
        end)
    ))
end
-- }}}
-- {{{ Bateria (texto)
--------------------------------------------------------------------------------
function bat_info()
    local cur = fread("/sys/class/power_supply/BAT0/charge_now")
    local cap = fread("/sys/class/power_supply/BAT0/charge_full")
    local sta = fread("/sys/class/power_supply/BAT0/status")
    if not cur or not cap or not sta or tonumber(cap) <= 0 then
        return 'ERR'
    end
    battery = math.floor(cur * 100 / cap)
    if sta:match("Charging") then
        local dir = "+"
        local battery = "A/C~"..battery
        elseif sta:match("Discharging") then
        dir = "-"
        if tonumber(battery) < 10 then
            popup( fgc('Battery Warning\n')
                 , "Battery low!"..battery.."% left!"
                 , 10
                 , imgdir..'bat.png'
                 )
        end
    else
        dir = "="
        battery = "A/C~"
    end
    return battery..dir
end
battery = io.open("/sys/class/power_supply/BAT0/charge_now")
if battery then
    local bat_ico = createIco('bat.png', terminal..' -e xterm')
    local batterywidget = wibox.widget.textbox()
    -- llamada inicial a la función
    batterywidget:set_markup(bat_info())
    batterywidget:connect_signal("mouse::enter",function()
        naughty.destroy(pop)
        popup( fgc('BAT0/info\n')
             , fread("/proc/acpi/battery/BAT0/info")
             , 0
             , imgdir..'swp.png'
             )
    end)
    batterywidget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
end
-- }}}
-- {{{ Separators (img)
--------------------------------------------------------------------------------
-- Separador de tres pixels de ancho con barra vertical con el color del borde
local separator = wibox.widget.base.make_widget()
separator.fit = function(separator, width, height)
    return 3, height
end
separator.draw = function(separator, wibox, cr, width, height)
    cr:set_source_rgb(gears.color.parse_color(theme.border_normal))
    cr:rectangle(1, 1, 1, 13)
    cr:fill()
    cr:stroke()
end
-- }}}
-- {{{ MPC (imagebox+textbox) requires mpc/mp
--------------------------------------------------------------------------------
-- Devuelve estado de mpc
local oldsong
function mpc_info()
    local now = pread('mpc -f "%name%\n%artist%\n%album%\n%title%\n%track%\n%time%\n%file%"')
    if now and now ~= '' then
        local name,artist,album,title,track,total,file,state,time = now:match('^(.-)\n(.-)\n(.-)\n(.-)\n(.-)\n(.-)\n(.-)\n%[(%w+)%]%s+#%d+/%d+%s+(.-%(%d+%%%))')
        if state and state ~= '' then
            if artist and title and time then
                local currentsong = artist.." - "..title
                if string.len(currentsong) > 60 then
                    currentsong = '...'..string.sub(currentsong, -57)
                 end
            else
                loglua("(EE) mpc_info got a format error. The string was '"..now.."'.")
                return 'ZOMFG Format Error!'
            end
            if state == 'playing' then
                -- Popup con el track
                if album ~= '' and currentsong ~= oldsong then
                    popup( nil
                         , string.format("%s %s\n%s  %s\n%s  %s"
                                        , 'Artist:', fgc(bold(artist))
                                        , 'Album:' , fgc(bold(album))
                                        , 'Title:' , fgc(bold(title))
                                        )
                         , 5
                         , imgdir .. 'mpd_logo.png'
                         )
                end
                oldsong = currentsong
                return fgc('[Play]','green')..' "'..fgc(currentsong, theme.font_key)..'" '..fgc(time,theme.font_value)
            elseif state == 'paused' then
                if currentsong ~= '' and time ~= '' then
                    return fgc('[Wait] ',theme.font_value)..currentsong..' '..fgc(time,theme.font_value)
                end
            end
        else
            if now:match('^Updating%sDB') then
                return fgc('[Wait]',theme.font_value)..' Updating Database...'
            elseif now:match('^volume:') then
                return fgc('[Stop]',theme.font_value)..' ZZzzz...'
            else
                return fgc('[DEAD]', 'red')..' :_('
            end
        end
    else
        return fgc('NO MPC', 'red')..' :_('
    end
end
--  imagebox
local mpd_ico = createIco('mpd.png', terminal..' -e ncmpcpp')
--  textbox
local mpcwidget = wibox.widget.textbox()
-- llamada inicial a la función
mpcwidget:set_markup(mpc_info())
-- textbox buttons
mpcwidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        os.execute('mpc play')
        print_mpc()
    end),
    awful.button({ }, 2, function ()
        os.execute('mpc stop')
        print_mpc()
    end),
    awful.button({ }, 3, function ()
        os.execute('mpc pause')
        print_mpc()
    end),
    awful.button({ }, 4, function()
        os.execute('mpc prev')
        print_mpc()
    end),
    awful.button({ }, 5, function()
        os.execute('mpc next')
        print_mpc()
    end)
))
-- muestra el track actual
function print_mpc()
    naughty.destroy(pop)
    popup( fgc('MPC Stats\n')
         , pread("mpc; echo ; mpc stats")
         , 0
         , imgdir..'mpd_logo.png'
         , "bottom_left"
         )
end
--  mouse_enter
mpcwidget:connect_signal("mouse::enter",function()
    print_mpc()
end)
--  mouse_leave
mpcwidget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- }}}
-- {{{ Memory (imagebox+textbox+progressbar)
--------------------------------------------------------------------------------
--  imagebox
local mem_ico = createIco('mem.png', terminal..' -e htop')
--  textbox
local memwidget = wibox.widget.textbox()
--  progressbar-
local membarwidget = awful.widget.progressbar()
membarwidget:set_width(40)
membarwidget:set_background_color('#000000')
membarwidget:set_border_color('#FFFFFF')
membarwidget:set_color({ type  = "linear"
                      , from  = { 40, 0 }
                      , to    = { 0 , 0 }
                      , stops = { { 0  , "#FF0000" }
                                , { 0.4, "#FFCC00" }
                                , { 1  , "#00FF00" }
                                }
                      })
local membarlayout = wibox.layout.margin(membarwidget, 1, 1, 1, 1)
--  mouse_enter
memwidget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( fgc('Free\n')
         , pread("free -tm")
         , 0
         , imgdir..'mem.png'
         , "bottom_right"
         )
    end)
--  mouse_leave
memwidget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- Devuelve la ram usada en MB(%). Tb actualiza la progressbar
function activeram()
    local total,free,buffers,cached,active,used,percent
    for line in io.lines('/proc/meminfo') do
        for key, value in string.gmatch(line, "(%w+): +(%d+).+") do
            if key == "MemTotal" then
                total = tonumber(value)
                if total <= 0 then --wtf
                    return ''
                end
            elseif key == "MemFree" then
                free = tonumber(value)
            elseif key == "Buffers" then
                buffers = tonumber(value)
            elseif key == "Cached" then
                cached = tonumber(value)
            end
        end
    end
    active = total-(free+buffers+cached)
    used = string.format("%.0fMB",(active/1024))
    percent = string.format("%.0f",(active/total)*100)
    if membarwidget then
        membarwidget:set_value(percent/100)
    end
    return fgc(used, theme.font_key)..fgc('('..percent..'%)', theme.font_value)
end
--  Llamada inicial a la función
memwidget:set_markup(activeram())
-- }}}
-- {{{ Swap (imagebox+textbox)
--------------------------------------------------------------------------------
-- Devuelve la swap usada en MB(%)
function activeswap()
    local active, total, free
    for line in io.lines('/proc/meminfo') do
        for key, value in string.gmatch(line, "(%w+): +(%d+).+") do
            if key == "SwapTotal" then
                total = tonumber(value)
                if total == 0 then
                    swp_ico.visible = false
                    swpwidget.text = '' -- No hay Swap!
                    return nil
                end
            elseif key == "SwapFree" then
                free = tonumber(value)
            end
        end
    end
    active = total - free
    if active then
        swp_ico.visible = true
        swpwidget:set_markup(fgc(string.format("%.0fMB",(active/1024)), theme.font_key)..fgc('('..string.format("%.0f%%",(active/total)*100)..')', theme.font_value))
    end
end
--  imagebox
swp_ico = createIco('swp.png', terminal..' -e htop')
--  textbox
swpwidget = wibox.widget.textbox()
--  llamada inicial a la función
activeswap()
--  mouse_enter
swpwidget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( fgc('/proc/meminfo\n')
         , fread("/proc/meminfo")
         , 0
         , imgdir..'swp.png'
         , "bottom_right"
         )
    end)
--  mouse_leave
swpwidget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- }}}
-- {{{ Cpu (imagebox+textbox+graph)
--------------------------------------------------------------------------------
--  imagebox
local cpu_ico = createIco('cpu.png', terminal..' -e htop')
--  textbox
local cpuwidget = wibox.widget.textbox()
--  graph
local cpugraphwidget = awful.widget.graph()
cpugraphwidget:set_width(40)
cpugraphwidget:set_background_color('#000000')
cpugraphwidget:set_border_color('#FFFFFF')
cpugraphwidget:set_color({ type  = "linear"
                         , from  = { 0,  }
                         , to    = { 0, 13 }
                         , stops = { { 0  , "#FF0000" }
                                   , { 0.4, "#FFCC00" }
                                   , { 1  , "#00FF00" }
                                   }
                         })
local cpugraphlayout = wibox.layout.margin(cpugraphwidget, 1, 1, 1, 1)
--  mouse_enter
cpuwidget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( fgc('Processes\n')
         , pread("ps -eo %cpu,%mem,ruser,pid,comm --sort -%cpu | head -30")
         , 0
         , imgdir..'cpu.png'
         , "bottom_right"
         )
end)
--  mouse_leave
cpuwidget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
--
--  Devuelve el % de uso de cada CPU y actualiza la gráfica con la media.
--  user + nice + system + idle = 100/second
--  so diffs of: $2+$3+$4 / all-together * 100 = %
--  or: 100 - ( $5 / all-together) * 100 = %
--  or: 100 - 100 * ( $5 / all-together)= %
local cpu = {}
function cpu_info()
    local s = 0
    local info = fread("/proc/stat")
    if not info then
        return "Error leyendo /proc/stat"
    end
    for user,nice,system,idle in info:gmatch("cpu.-%s(%d+)%s+(%d+)%s+(%d+)%s+(%d+)") do
        if not cpu[s] then
            cpu[s]={}
            cpu[s].sum  = 0
            cpu[s].res  = 0
            cpu[s].idle = 0
        end
        local new_sum   = user + nice + system + idle
        local diff      = new_sum - cpu[s].sum
        cpu[s].res  = 100
        if diff > 0 then -- siempre devería cumplirse, excepto cargas elevadas.
            cpu[s].res = 100 - 100 * (idle - cpu[s].idle) / diff
        end
        cpu[s].sum  = new_sum
        cpu[s].idle = idle
        s = s + 1
    end
    -- next(cpu) devuelve nil si la tabla cpu está vacía
    if not next(cpu) then
        return "No hay cpus en /proc/stat"
    end
    if cpugraphwidget and cpu[0].res then
        cpugraphwidget:add_value(cpu[0].res/100)
    end
    info = ''
    for s = 0, #cpu do
        if cpu[s].res > 99 then
            info = info..fgc('C'..s..':', theme.font_key)..fgc('LOL', 'red')
        else
            info = info..fgc('C'..s..':', theme.font_key)..fgc(string.format("%02d",cpu[s].res)..'%', theme.font_value)
        end
        if s ~= #cpu then
            info = info..' '
        end
    end
    return info
end
--  primera llamada a la función
cpuwidget:set_markup(cpu_info())
-- }}}
-- {{{    FileSystem (imagebox+textbox)
--------------------------------------------------------------------------------
-- Busca puntos de pontaje concreto en 'df' y lista el espacio usado.
-- la llamada statfs de fs tarda la tira en leer mis discos FAT32 (7 segundos a veces)
-- por primera vez y hace que awesome se demore ese tanto.
-- De momento he puesto un df >/dev/null&1 en rc.local supercutre para evitarlo.
function fs_info()
    local result = ''
    local df = pread("df -x squashfs -x iso9660")
    if df then
        for percent, mpoint in df:gmatch("(%d+)%%%s+(/.-)%s") do
            local value = mpoint
            if tonumber(percent) > 90 then
                result = result..fgc(value..'~', theme.font_key)..fgc(percent..'%', 'red')
            else
                if tonumber(percent) > 49 then
                    result = result..fgc(value..'~', theme.font_key)..fgc(percent..'%', theme.font_value)
                end
            end
        end
    end
    if result == '' then
        result = fgc('OK', theme.font_value)
    end
    return result
end
--  imagebox
local fs_ico = createIco('fs.png', terminal..' -e fdisk -l')
--  textbox
local fswidget = wibox.widget.textbox()
--  primera llamada a la función
fswidget:set_markup(fs_info())
--  mouse_enter
fswidget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup ( fgc('Disk Usage\n')
          , pread("df -ha")
          , 0
          , imgdir..'fs.png'
          , 'bottom_right'
          )
end)
--  mouse_leave
fswidget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- }}}
-- {{{ Net (imagebox+textbox)
--------------------------------------------------------------------------------
--  imagebox iface
local net_ico = createIco('net-wired.png', terminal..' -e screen -S awesome watch -n5 "lsof -ni"')
--  imagebox up
local up_ico = createIco('up.png', terminal..' -e screen -S awesome watch -n5 "lsof -ni"')
--  imagebox down
local down_ico = createIco('down.png', terminal..' -e screen -S awesome watch -n5 "lsof -ni"')
--  textbox iface
local netwidget = wibox.widget.textbox()
--  imagebox up
local netwidget_up = wibox.widget.textbox()
--  imagebox down
local netwidget_down = wibox.widget.textbox()
--  mouse_enter
netwidget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( fgc('Established\n')
         , pread("netstat -patun 2>&1 | awk '/ESTABLISHED/{ if ($4 !~ /127.0.0.1|localhost/) print \"(\"$7\")\t\"$5}' | column -t")
         , 0
         , imgdir..'net-wired.png'
         , "bottom_right"
         )
end)
--  mouse_enter_up
netwidget_up:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( fgc('Transfer Stats\n')
         , pread("cat /proc/net/dev | sed -e 's/multicast/multicast\t/g' -e 's/|bytes/bytes/g' | column -t")
         , 0
         , imgdir..'net-wired.png'
         , "bottom_right"
         )
end)
--  mouse_enter_up
netwidget_down:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( fgc('Transfer Stats\n')
         , pread("cat /proc/net/dev | sed -e 's/multicast/multicast\t/g' -e 's/|bytes/bytes/g' | column -t")
         , 0
         , imgdir..'net-wired.png'
         , "bottom_right"
         )
end)
-- mouse_leave
netwidget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- mouse_leave_up
netwidget_up:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- mouse_leave_down
netwidget_down:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- Devuelve el tráfico de la interface de red usada como default GW.
function net_info()
    if not old_rx or not old_tx or not old_time then
        old_rx,old_tx,old_time = 0,0,1
    end
    local iface,cur_rx,cur_tx,rx,rxu,tx,txu
    local file = fread("/proc/net/route")
    if file then
        iface = file:match('(%S+)%s+00000000%s+%w+%s+0003%s+')
        if not iface or iface == '' then
            return '' --fgc('No Def GW', 'red')
        end
    else
        return "Err: /proc/net/route."
    end
    --Sacamos cur_rx y cur_tx de /proc/net/dev
    file = fread("/proc/net/dev")
    if file then
       cur_rx,cur_tx = file:match(iface..':%s*(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)%s+')
    else
        return "Err: /proc/net/dev"
    end
    cur_time = os.time()
    interval = cur_time - old_time -- diferencia entre mediciones
--    rx = ( cur_rx - old_rx ) / 1024 / interval -- resultado en kb
--    tx = ( cur_tx - old_tx ) / 1024 / interval
    if tonumber(interval) > 0 then -- porsia
        rx,rxu = bytestoh( ( cur_rx - old_rx ) / interval )
        tx,txu = bytestoh( ( cur_tx - old_tx ) / interval )
        old_rx,old_tx,old_time = cur_rx,cur_tx,cur_time
    else
        rx,tx,rxu,txu = "0","0","B","B"
    end
    netwidget:set_markup(fgc(iface, theme.font_value))
    netwidget_up:set_markup(fgc(string.format("%04d%2s",tx,txu), theme.font_value))
    netwidget_down:set_markup(fgc(string.format("%04d%2s",rx,rxu), theme.font_value))
end
--  primera llamada a la función
net_info()
-- }}}
-- {{{ Load (magebox+textbox)
--------------------------------------------------------------------------------
-- Devuelve el load average
function avg_load()
    local n = fread('/proc/loadavg')
    local pos = n:find(' ', n:find(' ', n:find(' ')+1)+1)
    return fgc(n:sub(1,pos-1), theme.font_value)
end
--  imagebox
local load_ico = createIco('load.png', terminal..' -e htop')
--  textbox
local loadwidget = wibox.widget.textbox()
-- llamada inicial a la función
loadwidget:set_markup(avg_load())
--  mouse_enter
loadwidget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( fgc('Uptime\n')
         , pread("uptime; echo; id; echo; who")
         , 0
         , imgdir..'load.png'
         , 'bottom_right'
         )
end)
-- mouse_leave
loadwidget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- }}}
-- {{{ Volume (Custom) requires alsa-utils
--------------------------------------------------------------------------------
-- Returns the "Master" volume from alsa.
local amixline = pread('amixer | head -1')
if amixline then
    sdev = amixline:match(".-%s%'(%w+)%',0")
end
function get_vol()
    if not sdev then
        return ''
    end
    local txt = pread('amixer get '..sdev)
    if txt then
        if txt:match('%[off%]') then
            return fgc('Mute', 'red')
        else
            return fgc(txt:match('%[(%d+%%)%]'), theme.font_value)
        end
    else
        return ''
    end
end
--  imagebox
local vol_ico = createIco('vol.png', terminal..' -e alsamixer')
--  textbox
local volwidget = wibox.widget.textbox()
--  primera llamada a la función
volwidget:set_markup(get_vol())
--  buttons
volwidget:buttons(awful.util.table.join(
    awful.button({ }, 4, function()
        os.execute('amixer -c 0 set '..sdev..' 3dB+');
        volwidget.text = get_vol()
    end),
    awful.button({ }, 5, function()
        os.execute('amixer -c 0 set '..sdev..' 3dB-');
        volwidget.text = get_vol()
    end)
))
-- mouse_enter
volwidget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    local text = pread('amixer get '..sdev)
    popup( fgc('Volume\n')
         , pread('amixer get '..sdev)
         , 0
         , imgdir..'vol.png'
         , 'bottom_left'
         )
end)
--  mouse_leave
volwidget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- }}}
-- {{{ Timers
--------------------------------------------------------------------------------
-- Hook every sec
local timer1 = timer { timeout = 1 }
timer1:connect_signal("timeout", function()
    cpuwidget:set_markup(cpu_info())
    loadwidget:set_markup(avg_load())
    net_info()
end)
timer1:start()
-- Hook called every 5 secs
local timer5 = timer { timeout = 5 }
timer5:connect_signal("timeout", function()
    if mailpass then mailwidget.text = check_gmail() end
    volwidget:set_markup(get_vol())
    memwidget:set_markup(activeram())
    activeswap()
    mpcwidget:set_markup(mpc_info())
end)
timer5:start()
--  Hook every 30 secs
local timer30 = timer { timeout = 30 }
timer30:connect_signal("timeout", function()
    if batterywidget then batterywidget:set_markup(bat_info()) end
end)
timer30:start()
-- Hook called every minute
local timer60 = timer { timeout = 60 }
timer60:connect_signal("timeout", function()
    if mailpass then getMail() end
    fswidget.text = fs_info()
end)
timer60:start()
-- }}}
-- {{{ Wibox
--------------------------------------------------------------------------------
for s = 1, screen.count() do

    -- Create the wibox
    local statusbar = {}
    statusbar[s] = awful.wibox({ position = "bottom"
                               , screen = s
                               , fg = beautiful.fg_normal
                               , bg = beautiful.bg_normal
                               , border_color = beautiful.border_normal
                               , height = 15 -- We ned that height to match our fonts/icons
                               , border_width = 1
                               })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(vol_ico)
    left_layout:add(volwidget)
    left_layout:add(separator)
    left_layout:add(mpd_ico)

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(separator)
    right_layout:add(log_ico)
    right_layout:add(logwidget)
    right_layout:add(separator)
    right_layout:add(mail_ico)
    right_layout:add(mailwidget)
    right_layout:add(separator)
    right_layout:add(load_ico)
    right_layout:add(loadwidget)
    right_layout:add(separator)
    right_layout:add(cpu_ico)
    right_layout:add(cpuwidget)
    right_layout:add(cpugraphlayout)
    right_layout:add(separator)
    right_layout:add(mem_ico)
    right_layout:add(memwidget)
    right_layout:add(membarlayout)
    right_layout:add(separator)
    right_layout:add(swp_ico)
    right_layout:add(swpwidget)
    right_layout:add(separator)
    right_layout:add(fs_ico)
    right_layout:add(fswidget)
    right_layout:add(separator)
    right_layout:add(net_ico)
    right_layout:add(netwidget)
    right_layout:add(up_ico)
    right_layout:add(netwidget_up)
    right_layout:add(down_ico)
    right_layout:add(netwidget_down)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mpcwidget)
    layout:set_right(right_layout)

    statusbar[s]:set_widget(layout)
end
-- }}}

-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
