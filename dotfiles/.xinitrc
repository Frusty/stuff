#!/bin/sh
# I log
errorlog="$HOME/.xsession.err"
if (cp /dev/null "$errorlog" 2> /dev/null)
then
    chmod 600 "$errorlog"
    exec > "$errorlog" 2>&1
    break
fi
# Workaround to make xorg care of the terminus font
xset +fp /usr/share/fonts/local
xset fp rehash
# Xmodmap para apple aluminum keyboard
if ( lsusb | grep -q "Apple, Inc. Aluminum Keyboard" ) ; then
    xmodmap $HOME/.Xmodmap_alu
fi
# nasTests
[ -f "$(which xcompmgr)"    ] && xcompmgr -c -n&
[ -f "$(which urxvtd)"      ] && [ "$TERMINAL" = "urxvtc" ] && urxvtd -o -q -f
[ -f "$(which parcellite)"  ] && parcellite &
[ -f "$(which wicd-client)" ] && wicd-gtk --tray &
[ -f "$(which irexec)"      ] && [ "$(pgrep -f irexec | wc -l)" -eq "0" ] && irexec -d
# Exec WM
exec awesome > ~/.awesome.err 2>&1
