#!/bin/bash
ok() { echo -ne "\e[32m#\n#\t$1\n#\e[m\n"; }
nk() { echo -ne "\e[31m#\n#\t$1\n#\e[m\n"; exit 1; }
PIN=XXX

[ -c /dev/ttyUSB0 ] && [ -c /dev/ttyUSB2 ] && {
    USB1=/dev/ttyUSB0 # Sierra USB dongle
    USB2=/dev/ttyUSB2
} || [ -c /dev/ttyACM0 ] && {
    USB1=/dev/ttyACM0 # Nokia E52
    USB2=$USB1
} || nk "No se ha detectado el módem!"

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
Modem = $USB1
Baud  = 57600
Init1 = ATZ+CPIN=$PIN
Init2 = ATZ
Init3 = AT+CGDCONT=1,"IP","movistar.es","0.0.0.0",0,0;
__EOF__
wvdial -C /proc/$$/fd/3

ok "Conexión PPP en $USB2"
exec 4<<__EOF__
[Dialer Defaults]
Modem         = $USB2
Stupid Mode   = 1
Phone         = *99***1#
Username      = MOVISTAR
Password      = MOVISTAR
__EOF__
wvdial -C /proc/$$/fd/4

ok "Out!"
