#!/bin/bash
# Wrapper sobre ncsvc.
set +o posix

ok() { echo -ne "\e[32m#\n#\t$1\n#\e[m\n"; }
nk() { echo -ne "\e[31m#\n#\t$1\n#\e[m\n"; exit 1; }

USER=""
HOST=""
REALM=""
[ $HOST ] && [ $REALM ] || nk "Falta especificar HOST y/o REALM en el script."

PATH=$PATH:$(dirname $0)
ok "Verificando binarios wvdial pppd y grep:"
which ncsvc pgrep openssl kill || nk "Faltan binarios!"
[ $(uname -m) = "x86_64" ] && ok ": Se necesita comp. 32 bits. Arch: pacman -S lib32-glibc lib32-gcc-libs lib32-zlib"

pgrep ncsvc > /dev/null && {
    ok "Procesos ncscv corriendo, los mato..."
    ncsvc -K || for i in $(pgrep ncsvc); do kill -9 $i; done
    ok "OK!"
} || {
    [ $USER ] || { ok "Usuario: "; read -r USER; }
    [ $USER ] || nk "El usuario no puede ser nulo!"
    ok "Conectando..."
    ncsvc -u $USER -h $HOST -r $REALM -f <(openssl x509 -in <(openssl s_client -connect $HOST:443 </dev/null 2>/dev/null | sed -n '1h;1!H;${;g;s/.*\(-----BE.*TE-----\).*/\1/p;}') -outform der)
    reset
}
