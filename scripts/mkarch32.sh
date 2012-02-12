#!/bin/bash
# Crea una chroot de 32 bits en arch.o
# Depende el paquete devtools en archlinux.
set +o posix
#set -x

[ $USER = "root" ] || { echo "requiere root"; exit 1; }
which mkarchroot linux32 mount umount || exit 1

CHROOT="/opt/arch32"
[ $1 ] && CHROOT=$1
echo -e "#\n#\tCreando/actualizando chroot en ${CHROOT}\n#"

exec 3<<__EOF__
[options]
HoldPkg      = pacman glibc
SyncFirst    = pacman
Architecture = i686
SigLevel     = Never

[core]
Server = http://sunsite.rediris.es/mirror/archlinux/core/os/i686
[extra]
Server = http://sunsite.rediris.es/mirror/archlinux/extra/os/i686
[community]
Server = http://sunsite.rediris.es/mirror/archlinux/community/os/i686
[archlinuxfr]
Server = http://repo.archlinux.fr/i686
__EOF__

exec 4<<__EOF__
DLAGENTS=('ftp::/usr/bin/wget -c --passive-ftp -t 3 --waitretry=3 -O %o %u'
          'http::/usr/bin/wget -c -t 3 --waitretry=3 -O %o %u'
          'https::/usr/bin/wget -c -t 3 --waitretry=3 --no-check-certificate -O %o %u'
          'rsync::/usr/bin/rsync -z %u %o'
          'scp::/usr/bin/scp -C %u %o')
CARCH="i686"
CHOST="i686-unknown-linux-gnu"
CFLAGS="-march=i686 -mtune=generic -O2 -pipe"
CXXFLAGS="-march=i686 -mtune=generic -O2 -pipe"
LDFLAGS="-Wl,--hash-style=gnu -Wl,--as-needed"
BUILDENV=(fakeroot !distcc color !ccache)
OPTIONS=(strip docs libtool emptydirs zipman purge)
INTEGRITY_CHECK=(md5)
MAN_DIRS=({usr{,/local}{,/share},opt/*}/{man,info})
DOC_DIRS=(usr/{,local/}{,share/}{doc,gtk-doc} opt/*/{doc,gtk-doc})
STRIP_DIRS=(bin lib sbin usr/{bin,lib,sbin,local/{bin,lib,sbin}} opt/*/{bin,lib,sbin})
PURGE_TARGETS=(usr/{,share}/info/dir .packlist *.pod)
PKGEXT='.pkg.tar.xz'
SRCEXT='.src.tar.gz'
__EOF__

# create if doesn't exist
[ -d ${CHROOT} ] || linux32 mkarchroot -C /proc/$$/fd/3 -M /proc/$$/fd/4 ${CHROOT} base base-devel

# update
linux32 mkarchroot -u ${CHROOT} || exit 1

# bindings
echo "bindings"
mount --bind /dev ${CHROOT}/dev
#mount --bind /dev/pts ${CHROOT}/dev/pts
#mount --bind /dev/shm ${CHROOT}/dev/shm
mount --bind /proc ${CHROOT}/proc
#mount --bind /proc/bus/usb ${CHROOT}/proc/bus/usb
mount --bind /sys ${CHROOT}/sys
mount --bind /tmp ${CHROOT}/tmp
mount --bind /home ${CHROOT}/home

# chroot
linux32 chroot ${CHROOT} /bin/bash

# umount bindings on exit
mount | sed -n "s@.*on \([^ ]*${CHROOT}[^ ]*\) .*@\1@p" | xargs -n1 umount
mount | sed -n "s@.*on \([^ ]*${CHROOT}[^ ]*\) .*@\1@p" | xargs -n1 umount
