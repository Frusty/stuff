#!/bin/bash
# Wrapper sobre wvdial para módems 3G con Movistar.
set +o posix
ok() { echo -ne "\e[32m#\n#\t$1\n#\e[m\n"; }
nk() { echo -ne "\e[31m#\n#\t$1\n#\e[m\n"; exit 1; }

[ -c /dev/ttyUSB0 ] && [ -c /dev/ttyUSB2 ] && {
    USB=/dev/ttyUSB0 # Sierra USB dongle
    PIN=???
}
[ -c /dev/ttyACM0 ] && {
    USB=/dev/ttyACM0 # Nokia E52
    PIN=???
}
[ $USB ] || nk "No se ha detectado el módem!"

ok "Verificando binarios wvdial pppd y grep:"
which wvdial pppd grep || nk "Faltan binarios!"

[ ${#PIN} -ne 4 ] && {
    ok "Introducir PIN:"
    stty -echo # Evitamos ver el PIN por pantalla
    read -r PIN
    stty echo
}
[ ${#PIN} -ne 4 ] && nk "PIN tiene que tener 4 caracteres"

ok "Introduciendo PIN en $USB1"
exec 3<<__EOF__
[Dialer Defaults]
Modem = $USB
Baud  = 57600
Init1 = ATZ+CPIN=$PIN
Init2 = ATZ
Init3 = AT+CGDCONT=1,"IP","movistar.es","0.0.0.0",0,0;
__EOF__
wvdial -C /proc/$$/fd/3

ok "Conexión PPP en $USB2"
exec 4<<__EOF__
[Dialer Defaults]
Modem         = $USB
Stupid Mode   = 1
#Auto DNS      = 0
Phone         = *99***1#
Username      = MOVISTAR
Password      = MOVISTAR
__EOF__
wvdial -C /proc/$$/fd/4

ok "Out!"
