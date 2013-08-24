-- Awesome widgetbar
local gears   = require("gears")
local widget  = require("wibox")
local awful   = require("awful")
local wibox   = require("wibox")
local naughty = require("naughty")

-- Reusable components
-- {{{ Separator (Verical Image)
--------------------------------------------------------------------------------
-- 3 pixel width separator with a vertical bar using the border color
separator = wibox.widget.base.make_widget()
separator.fit = function(separator, width, height)
    return 3, height
end
separator.draw = function(separator, wibox, cr, width, height)
    cr:set_source_rgb(gears.color.parse_color(theme.border_normal))
    cr:rectangle(1, 1, 1, 13)
    cr:fill()
    cr:stroke()
end
--  }}}
-- {{{ Icon creation wrapper
function createIco(file, click)
    if not file or not click then return nil end
    local icon = awful.widget.button({ image = imgdir..file })
    icon:set_resize(false)
    icon:buttons(awful.util.table.join(awful.button({}, 1, function() awful.util.spawn(click,false) end)))
    -- Trying to center our 13 heigh icons  # wibox.layout.margin(widget,right,left,top,bottom)
    layout = wibox.layout.margin(icon, 0, 0, 1, 1)
    return layout
end
-- }}}
-- Left-aligned Widgets
-- {{{ Volume [Icon+Textbox+Separator] requires alsa-utils
--------------------------------------------------------------------------------
-- Icon
local volume_icon = createIco('vol.png', terminal..' -e alsamixer')
-- Textbox
local volume_textbox = wibox.widget.textbox()
-- Layout with all the elements
local volume_layout = wibox.layout.fixed.horizontal()
      volume_layout:add(volume_icon)
      volume_layout:add(volume_textbox)
      volume_layout:add(separator)
-- The widget itslelf
local volume_widget = wibox.layout.margin(volume_layout)
-- Fetch our master volume device
local amixline = pread('amixer | head -1')
if amixline then
    sdev = amixline:match(".-%s%'(%w+)%',0")
    if not sdev then
        loglua("(II) [volume_widget] Could not find a master volume device.")
        volume_widget:set_widget(nil) -- hide the widget
    end
end
-- Returns the "Master" volume from alsa.
function get_vol()
    if not sdev then return nil end
    local txt = pread('amixer get '..sdev)
    if txt then
        if txt:match('%[off%]') then
            return fgc('Mute', 'red')
        else
            return fgc(txt:match('%[(%d+%%)%]'), theme.font_value)
        end
    end
end
--  Buttons
volume_textbox:buttons(awful.util.table.join(
    awful.button({ }, 4, function()
        os.execute('amixer -c 0 set '..sdev..' 3dB+');
        volume_textbox:set_markup(get_vol())
    end),
    awful.button({ }, 5, function()
        os.execute('amixer -c 0 set '..sdev..' 3dB-');
        volume_textbox:set_markup(get_vol())
    end)
))
-- Mouse_enter
volume_widget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    local text = pread('amixer get '..sdev)
    popup( 'Volume'
         , pread('amixer get '..sdev)
         , 0
         , imgdir..'vol.png'
         , 'bottom_left'
         )
end)
--  Mouse_leave
volume_widget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- }}}
-- {{{ MPC [Icon+Textbox] requires mpd/mpc
--------------------------------------------------------------------------------
-- Icon
local mpd_icon = createIco('mpd.png', terminal..' -e ncmpcpp')
-- Textbox
local mpc_textbox = wibox.widget.textbox()
-- Layout with all the elements
local mpc_layout = wibox.layout.fixed.horizontal()
      mpc_layout:add(mpd_icon)
      mpc_layout:add(mpc_textbox)
-- The widget itself
local mpc_widget = wibox.layout.margin(mpc_layout)
-- Returns the parsed output of the mpc client
local oldsong
function mpc_info()
    local currentsong
    local now = escape(pread('mpc -f "%artist%\n%album%\n%title%\n%time%"'))
    if now and now ~= '' then
        local artist,album,title,total,state,time = now:match('^(.-)\n(.-)\n(.-)\n(.-)\n%[(%w+)%]%s+#%d+/%d+%s+(.-%(%d+%%%))')
        if state and state ~= '' then
            if artist and title and time then
                currentsong = artist.." - "..title
                if string.len(currentsong) > 60 then
                    currentsong = '...'..string.sub(currentsong, -57)
                end
            else
                loglua("(EE) [mpc_widget] ]mpc_info got a format error. The string was '"..now.."'.")
                return 'ZOMFG Format Error!'
            end
            if state == 'playing' then
                -- Track popup
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
                    oldsong = currentsong
                end
                return fgc('[Play]', theme.font_value)..' "'..fgc(currentsong, theme.font_key)..'" '..fgc(time,theme.font_value)
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
                return fgc('[DEAD]', theme.font_value)..' :_('
            end
        end
    else
        loglua("(WW) [mpc_widget] ]The mpc binary failed or doesn't exist.")
        return fgc('NO MPC', theme.font_value)..' :_('
    end
end
-- 1st call
mpc_textbox:set_markup(fgc('Hi '..ucfirst(user)..'!', theme.font_value))
-- Textbox buttons
mpc_textbox:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        os.execute('mpc play<F3>')
        mpc_textbox:set_markup(mpc_info())
    end),
    awful.button({ }, 2, function ()
        os.execute('mpc stop')
        mpc_textbox:set_markup(mpc_info())
    end),
    awful.button({ }, 3, function ()
        os.execute('mpc pause')
        mpc_textbox:set_markup(mpc_info())
    end),
    awful.button({ }, 4, function()
        os.execute('mpc prev')
        mpc_textbox:set_markup(mpc_info())
    end),
    awful.button({ }, 5, function()
        os.execute('mpc next')
        mpc_textbox:set_markup(mpc_info())
    end)
))
--  Mouse_enter
mpc_widget:connect_signal("mouse::enter",function()
    naughty.destroy(pop)
    popup( 'MPC Stats'
         , pread("mpc; echo ; mpc stats")
         , 0
         , imgdir..'mpd_logo.png'
         , "bottom_left"
         )
end)
--  Mouse_leave
mpc_widget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- }}}
-- Right-aligned Widgets
-- {{{ Log Button [Separator+Icon+Textbox]
--------------------------------------------------------------------------------
-- Allows to de/activate 15_logwatcher.lua
-- Icon
local log_icon = createIco('log.png', terminal)
-- Textbox
local log_textbox = wibox.widget.textbox()
-- Layout with all the elements
local log_layout = wibox.layout.fixed.horizontal()
      log_layout:add(separator)
      log_layout:add(log_icon)
      log_layout:add(log_textbox)
-- The widget itself
local log_widget = wibox.layout.margin(log_layout)
--
if exists(inotify_so) then
    log_textbox:set_markup(fgc('ON', theme.font_value))
    enable_logs = true
else
    enable_logs = false
    log_widget:set_widget(nil) -- hide the widget
end
-- Buttons
log_textbox:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        if exists(inotify_so) then
            if enable_logs then
                log_textbox.text = fgc('NO', 'red')
                enable_logs = false
                popup( 'Awesome Notification:', 'Logging Disabled', 5 )
            else
                log_textbox.text = fgc('ON', theme.font_value)
                enable_logs = true
                popup( 'Awesome Notification:', 'Logging Enabled', 5 )
            end
        else
            popup( 'Awesome Notification:', "Can't find '"..inotify_so.."'. Logging Disabled.", 5 )
        end
    end)
))
-- }}}
-- {{{ GMail [Separator+Icon+Textbox] requires wget
--------------------------------------------------------------------------------
-- Needs a .netrc file in your homedir with the credentials (look at the -n curl flag)
-- Example of a .netrc file contents:
-- machine host.domain.com login myself password secret
mailurl = 'https://mail.google.com/mail/feed/atom/'
mail_icon = createIco('mail.png', browser..' '..mailurl..'"&')
-- Textbox
mail_textbox = wibox.widget.textbox()
-- Layout with all the elements
local mail_layout = wibox.layout.fixed.horizontal()
      mail_layout:add(separator)
      mail_layout:add(mail_icon)
      mail_layout:add(mail_textbox)
-- The widget itself
local mail_widget = wibox.layout.margin(mail_layout)
-- Hide the widget if we don't have a .netrc file
if not fread(homedir..'.netrc') then
    mail_widget:set_widget(nil) -- hide the widget
end
-- Fetch and parse a gmail feed
local mailcount = 0
function check_gmail()
    local feed = pread('curl --connect-timeout 1 -m 3 -fsn "'..mailurl..'"')
    if not feed then return fgc('?', theme.font_value) end
    local lcount = mailcount
    if feed:match('fullcount>%d+<') then
        lcount = feed:match('fullcount>(%d+)<')
    end
    if lcount ~= mailcount then
        for title,summary,name,email in feed:gmatch('<entry>\n<title>(.-)</title>\n<summary>(.-)</summary>.-<name>(.-)</name>\n<email>(.-)</email>') do
            popup( nil
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
-- Mouse_enter
mail_widget:connect_signal("mouse::enter", function()
    mailcount = 0
    mail_textbox:set_markup(check_gmail())
end)
-- Mouse_leave
mail_widget:connect_signal("mouse::leave", function() desnaug() end)
-- Buttons
mail_textbox:buttons(awful.util.table.join(
    awful.button({ }, 1, function ()
        fetch_gmail()
        os.execute(browser..' "'..mailurl..'"&')
    end)
))
-- }}}
-- {{{ Load [Separator+Icon+Textbox]
--------------------------------------------------------------------------------
-- Icon
local load_icon = createIco('load.png', terminal..' -e htop')
-- Textbox
local load_textbox = wibox.widget.textbox()
-- Layout with all the elements
local load_layout = wibox.layout.fixed.horizontal()
      load_layout:add(separator)
      load_layout:add(load_icon)
      load_layout:add(load_textbox)
-- The widget itself
local load_widget = wibox.layout.margin(load_layout)
-- Hide the widget if we don't have everything
if not fread('/proc/loadavg') then
    loglua("(WW) [load_widget] Could not read /proc/average. Hiding the widget.")
    load_widget:set_widget(nil) -- hide the widget
end
-- Returns the load average
function avg_load()
    local n = fread('/proc/loadavg')
    local pos = n:find(' ', n:find(' ', n:find(' ')+1)+1)
    return fgc(n:sub(1,pos-1), theme.font_value)
end
-- 1st call
load_textbox:set_markup(avg_load())
-- Mouse_enter
load_widget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( 'Uptime'
         , pread("uptime; echo; id; echo; who")
         , 0
         , imgdir..'load.png'
         , 'bottom_right'
         )
end)
-- Mouse_leave
load_widget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- }}}
-- {{{ Cpu [Separator+Icon+Textbox+Graph]
--------------------------------------------------------------------------------
-- Icon
local cpu_icon = createIco('cpu.png', terminal..' -e htop')
-- Textbox
local cpu_textbox = wibox.widget.textbox()
-- Graph
local cpu_graph = awful.widget.graph()
      cpu_graph:set_width(40)
      cpu_graph:set_background_color('#000000')
      cpu_graph:set_border_color('#FFFFFF')
      cpu_graph:set_color({ type  = "linear"
                         , from  = { 0,  }
                         , to    = { 0, 13 }
                         , stops = { { 0  , "#FF0000" }
                                   , { 0.4, "#FFCC00" }
                                   , { 1  , "#00FF00" }
                                   }
                         })
-- Fit the graph into a layout to add margins
local cpu_graph_layout = wibox.layout.margin(cpu_graph, 1, 1, 1, 1)
-- Layout with all the elements
local cpu_layout = wibox.layout.fixed.horizontal()
      cpu_layout:add(separator)
      cpu_layout:add(cpu_icon)
      cpu_layout:add(cpu_textbox)
      cpu_layout:add(cpu_graph_layout)
-- The widget itself
local cpu_widget = wibox.layout.margin(cpu_layout)
-- Hide the widget if we don't have everything
if not fread('/proc/stat') then
    loglua("(WW) [cpu_widget] ]Could not read /proc/stat. Hiding the widget.")
    cpu_widget:set_widget(nil) -- hide the widget
end
--  mouse_enter
cpu_widget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( 'Processes'
         , pread("ps -eo %cpu,%mem,ruser,pid,comm --sort -%cpu | head -30")
         , 0
         , imgdir..'cpu.png'
         , "bottom_right"
         )
end)
--  mouse_leave
cpu_widget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
--  Returns the usage of every CPU feeding the textbox and the graph.
--  user + nice + system + idle = 100/second
--  so diffs of: $2+$3+$4 / all-together * 100 = %
--  or: 100 - ( $5 / all-together) * 100 = %
--  or: 100 - 100 * ( $5 / all-together) = %
local cpu = {}
function cpu_info()
    local s = 0
    local info = fread("/proc/stat")
    if not info then
        return "Error reading /proc/stat"
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
        if diff > 0 then
            cpu[s].res = 100 - 100 * (idle - cpu[s].idle) / diff
        end
        cpu[s].sum  = new_sum
        cpu[s].idle = idle
        s = s + 1
    end
    -- next(cpu) returns nil if the table cpu is empty
    if not next(cpu) then
        return "There's no cpus in /proc/stat ¿?"
    end
    if cpu_graph and cpu[0].res then
        cpu_graph:add_value(cpu[0].res/100)
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
-- }}}
-- {{{ Memory [Separator+Icon+Textbox+Progressbar]
--------------------------------------------------------------------------------
-- Icon
local memory_icon = createIco('mem.png', terminal..' -e htop')
-- Textbox
local memory_textbox = wibox.widget.textbox()
-- Progressbar
local memory_progressbar = awful.widget.progressbar()
      memory_progressbar:set_width(40)
      memory_progressbar:set_background_color('#000000')
      memory_progressbar:set_border_color('#FFFFFF')
      memory_progressbar:set_color({ type  = "linear"
                                   , from  = { 40, 0 }
                                   , to    = { 0 , 0 }
                                   , stops = { { 0  , "#FF0000" }
                                             , { 0.4, "#FFCC00" }
                                             , { 1  , "#00FF00" }
                                             }
                                   })
-- Fit the progressbar into a layout to add margins
local memory_progressbar_layout = wibox.layout.margin(memory_progressbar, 1, 1, 1, 1)
-- Layout with all the elements
local memory_layout = wibox.layout.fixed.horizontal()
      memory_layout:add(separator)
      memory_layout:add(memory_icon)
      memory_layout:add(memory_textbox)
      memory_layout:add(memory_progressbar_layout)
-- The widget itself
local memory_widget = wibox.layout.margin(memory_layout)
-- Hide the widget if we don't have everything
if not fread('/proc/meminfo') then
    loglua("(WW) [memory_widget] ]Could not read /proc/meminfo. Hiding the widget.")
    memory_widget:set_widget(nil) -- hide the widget
end
-- Mouse_enter
memory_widget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( 'Free'
         , pread("free -tm")
         , 0
         , imgdir..'mem.png'
         , "bottom_right"
         )
    end)
-- Mouse_leave
memory_widget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- Returns the RAM usage while feeding the progressbar.
function activeram()
    local total,free,buffers,cached,active,used,percent
    for line in io.lines('/proc/meminfo') do
        for key, value in string.gmatch(line, "(%w+): +(%d+).+") do
            if key == "MemTotal" then
                total = tonumber(value)
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
    if memory_progressbar then
        memory_progressbar:set_value(percent/100)
    end
    return fgc(used, theme.font_key)..fgc('('..percent..'%)', theme.font_value)
end
-- }}}
-- {{{ Swap [Separator+Icon+textbox]
--------------------------------------------------------------------------------
-- Icon
swap_icon = createIco('swp.png', terminal..' -e htop')
-- Textbox
swap_textbox = wibox.widget.textbox()
-- Layout with all the elements
local swap_layout = wibox.layout.fixed.horizontal()
      swap_layout:add(separator)
      swap_layout:add(swap_icon)
      swap_layout:add(swap_textbox)
-- The widget itself
local swap_widget = wibox.layout.margin(swap_layout)
-- Hide the widget if we don't have everything
if not fread('/proc/meminfo') then
    loglua("(WW) [swap_widget] Could not read /proc/meminfo. Hiding the widget.")
    swap_widget:set_widget(nil) -- hide the widget
end
--  mouse_enter
swap_textbox:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( '/proc/meminfo'
         , fread("/proc/meminfo")
         , 0
         , imgdir..'swp.png'
         , "bottom_right"
         )
    end)
--  mouse_leave
swap_textbox:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- Returns the swap usage
local noswap = false
function activeswap()
    if noswap == true then return 'No Swap' end
    local active, total, free
    for line in io.lines('/proc/meminfo') do
        for key, value in string.gmatch(line, "(%w+): +(%d+).+") do
            if key == "SwapTotal" then
                total = tonumber(value)
                if total == 0 then
                    swap_widget:set_widget(nil) -- hide the widget
                    noswap = true
                    loglua("(WW) [swap_widget] Swap reported is 0. Hiding the widget.")
                    return fgc('No Swap', 'red')
                end
            elseif key == "SwapFree" then
                free = tonumber(value)
            end
        end
    end
    active = total - free
    return fgc(string.format("%.0fMB",(active/1024)), theme.font_key)..fgc('('..string.format("%.0f%%",(active/total)*100)..')', theme.font_value)
end
-- }}}
-- {{{ FileSystem [Separator+Icon+extbox]
--------------------------------------------------------------------------------
-- Icon
local filesystem_icon = createIco('fs.png', terminal..' -e fdisk -l')
-- Textbox
local filesystem_textbox = wibox.widget.textbox()
-- Layout with all the elements
local filesystem_layout = wibox.layout.fixed.horizontal()
      filesystem_layout:add(separator)
      filesystem_layout:add(filesystem_icon)
      filesystem_layout:add(filesystem_textbox)
-- The widget itself
local filesystem_widget = wibox.layout.margin(filesystem_layout)
-- Hide the widget if we don't have everything
if not pread('LC_ALL=C df') then
    loglua("(WW) [filesystem_widget] Could not execute df Hiding the widget.")
    filesystem_widget:set_widget(nil) -- hide the widget
end
-- Mouse_enter
filesystem_widget:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup ( 'Disk Usage'
          , pread('LC_ALL=C df -ha')
          , 0
          , imgdir..'fs.png'
          , 'bottom_right'
          )
end)
-- Mouse_leave
filesystem_widget:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- Parse and show used filesystems from the df output
function fs_info()
    local result = ''
    local df = pread('LC_ALL=C df -x squashfs -x iso9660')
    if df then
        for percent, mpoint in df:gmatch("(%d+)%%%s+(/.-)%s") do
            local value = mpoint
            if tonumber(percent) > 90 then
                result = result..fgc(value..'~', theme.font_key)..fgc(percent..'%', 'red')
            else
                if tonumber(percent) > 79 then
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
-- }}}
-- {{{ Battery [Separator+Icon+Textbox]
--------------------------------------------------------------------------------
-- Icon
local battery_icon = createIco('bat.png', terminal..' -e xterm')
-- Textbox
local battery_textbox = wibox.widget.textbox()
-- Layout with all the elements
local battery_layout = wibox.layout.fixed.horizontal()
      battery_layout:add(separator)
      battery_layout:add(battery_icon)
      battery_layout:add(battery_textbox)
-- The widget itself
local battery_widget = wibox.layout.margin(battery_layout)
-- Hide the widget if we got no battery
local battery = io.open("/sys/class/power_supply/BAT0/charge_now")
if not battery then
    battery_widget:set_widget(nil) -- hide the widget
end
-- Return the charge of the BAT0 battery
function bat_info()
    if not battery then return fgc('ERR', 'red') end
    local cur = fread("/sys/class/power_supply/BAT0/charge_now")
    local cap = fread("/sys/class/power_supply/BAT0/charge_full")
    local sta = fread("/sys/class/power_supply/BAT0/status")
    if not cur or not cap or not sta or tonumber(cap) <= 0 then
        loglua("(WW) [battery_widget] Could not get proper battery stats.")
        return 'ERR'
    end
    local dir = "="
    local battery = math.floor(cur * 100 / cap)
    if sta:match("Charging") then
        dir = "+"
        battery = "A/C~"..battery
        elseif sta:match("Discharging") then
        dir = "-"
        if tonumber(battery) < 10 then
            popup( 'Battery Warning'
                 , "Battery low!"..battery.."% left!"
                 , 10
                 , imgdir..'bat.png'
                 )
        end
    else
        battery = "A/C~"
    end
    return battery..dir
end
-- Mouse_enter
battery_textbox:connect_signal("mouse::enter",function()
    naughty.destroy(pop)
    popup( 'BAT0/info'
         , fread("/proc/acpi/battery/BAT0/info")
         , 0
         , imgdir..'bat.png'
         )
end)
-- Mouse_leave
battery_textbox:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- }}}
-- {{{ Network [Separator+Icon+Textbox+Icon+Textbox+Icon+Textbox]
--------------------------------------------------------------------------------
-- Icon iface
local network_icon = createIco('net-wired.png', terminal..' -e screen -S awesome watch -n5 "lsof -ni"')
-- Textbox iface
local network_textbox = wibox.widget.textbox()
-- Icon upload
local network_upload_icon = createIco('up.png', terminal..' -e screen -S awesome watch -n5 "lsof -ni"')
-- Textbox upload
local network_upload_textbox = wibox.widget.textbox()
-- Icon download
local network_download_icon = createIco('down.png', terminal..' -e screen -S awesome watch -n5 "lsof -ni"')
-- Textbox download
local network_download_textbox = wibox.widget.textbox()
-- Layout with all the elements
local network_layout = wibox.layout.fixed.horizontal()
      network_layout:add(separator)
      network_layout:add(network_icon)
      network_layout:add(network_textbox)
      network_layout:add(network_upload_icon)
      network_layout:add(network_upload_textbox)
      network_layout:add(network_download_icon)
      network_layout:add(network_download_textbox)
-- The widget itself
local network_widget = wibox.layout.margin(network_layout)
if not fread('/proc/net/dev') then
    loglua("(WW) [network_widget] Could not read /proc/net/dev. Hiding the widget.")
    network_widget:set_widget(nil) -- hide the widget
end
-- Mouse_enter
network_textbox:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( 'Established'
         , pread("netstat -patun 2>&1 | awk '/ESTABLISHED/{ if ($4 !~ /127.0.0.1|localhost/) print \"(\"$7\")\t\"$5}' | column -t")
         , 0
         , imgdir..'net-wired.png'
         , "bottom_right"
         )
end)
-- Mouse_leave
network_textbox:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- Mouse_enter_up
network_upload_textbox:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( 'Transfer Stats'
         , pread("cat /proc/net/dev | sed -e 's/multicast/multicast\t/g' -e 's/|bytes/bytes/g' | column -t")
         , 0
         , imgdir..'net-wired.png'
         , "bottom_right"
         )
end)
-- Mouse_leave_up
network_upload_textbox:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- Mouse_enter_down
network_download_textbox:connect_signal("mouse::enter", function()
    naughty.destroy(pop)
    popup( 'Transfer Stats'
         , pread("cat /proc/net/dev | sed -e 's/multicast/multicast\t/g' -e 's/|bytes/bytes/g' | column -t")
         , 0
         , imgdir..'net-wired.png'
         , "bottom_right"
         )
end)
-- Mouse_leave_down
network_download_textbox:connect_signal("mouse::leave", function() naughty.destroy(pop) end)
-- Returns the default GW traffic feeding the three textboxes.
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
    --we get cur_rx y cur_tx de /proc/net/dev
    file = fread("/proc/net/dev")
    if file then
       cur_rx,cur_tx = file:match(iface..':%s*(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)%s+')
    else
        return "Err: /proc/net/dev"
    end
    cur_time = os.time()
    interval = cur_time - old_time
    if tonumber(interval) > 0 then -- let's be cautious
        rx,rxu = bytestoh( ( cur_rx - old_rx ) / interval )
        tx,txu = bytestoh( ( cur_tx - old_tx ) / interval )
        old_rx,old_tx,old_time = cur_rx,cur_tx,cur_time
    else
        rx,tx,rxu,txu = "0","0","B","B"
    end
    network_textbox:set_markup(fgc(iface, theme.font_value))
    network_upload_textbox:set_markup(fgc(string.format("%04d%2s",tx,txu), theme.font_value))
    network_download_textbox:set_markup(fgc(string.format("%04d%2s",rx,rxu), theme.font_value))
end
-- }}}
-- Hooks and Wibox
-- {{{ Hooks with the widget refresh times.
--------------------------------------------------------------------------------
-- Hook called every 2 secs
local timer2 = timer { timeout = 2 }
timer2:connect_signal("timeout", function()
    cpu_textbox:set_markup(cpu_info())
    net_info()
end)
timer2:start()
-- Hook called every 5 secs
local timer5 = timer { timeout = 5 }
timer5:connect_signal("timeout", function()
    load_textbox:set_markup(avg_load())
    memory_textbox:set_markup(activeram())
    activeswap()
    volume_textbox:set_markup(get_vol())
    mpc_textbox:set_markup(mpc_info())
    filesystem_textbox.text = fs_info()
    battery_textbox:set_markup(bat_info())
end)
timer5:start()
-- Hook called every 307 secs
local timer307 = timer { timeout = 307 }
timer307:connect_signal("timeout", function()
    mail_textbox:set_markup(check_gmail())
end)
timer307:start()
-- }}}
-- {{{ The widgetbar itself (Wibox)
--------------------------------------------------------------------------------
for s = 1, 1 do -- for s = 1, screen.count() do
    -- Define the wibox
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
    left_layout:add(volume_widget)
    left_layout:add(mpc_widget)
    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(log_widget)
    right_layout:add(mail_widget)
    right_layout:add(load_widget)
    right_layout:add(cpu_widget)
    right_layout:add(memory_widget)
    right_layout:add(swap_widget)
    right_layout:add(battery_widget)
    right_layout:add(filesystem_widget)
    right_layout:add(network_widget)
    -- Now bring it all together (no set_right ATM)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_right(right_layout)
    -- Embed the widgets to the statusbar
    statusbar[s]:set_widget(layout)
end
-- }}}

-- vim: set filetype=lua fdm=marker tabstop=4 shiftwidth=4 nu:
