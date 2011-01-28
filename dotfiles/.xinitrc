#!/bin/sh
# I log
errorlog="$HOME/.xsession.err"
if ( cp /dev/null "$errorlog" 2> /dev/null )
then
    chmod 600 "$errorlog"
    exec > "$errorlog" 2>&1
    break
fi
# I merge
xrdb -merge -load ~/.Xdefaults
# Workaround to make xorg care of the terminus font
xset +fp /usr/share/fonts/local
xset fp rehash
# Xmodmap para apple aluminum keyboard
if ( lsusb | grep -q "Apple, Inc. Aluminum Keyboard" ) ; then
    xmodmap $HOME/.Xmodmap_alu
fi
# nasTests
[ -f `which xcompmgr`   ] && xcompmgr    &
[ -f `which autocutsel` ] && autocutsel -fork
[ -f `which urxvtd`     ] && [ "$TERMINAL" = "urxvtc" ] && urxvtd -o -q -f
[ -f `which parcellite` ] && parcellite  &
[ -f `which wicd-clien` ] && wicd-client &
[ -f `which ipt2awe.pl` ] && ipt2awe.pl
[ -f `which irexec`     ] && irexec -d
[ -f `which wmname`     ] && wmname LG3D # Java Apps Workaround
exec ck-launch-session awesome > ~/.awesome.err 2>&1
