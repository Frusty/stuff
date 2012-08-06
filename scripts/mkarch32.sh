#!/bin/bash
# Crea una chroot de 32 bits en arch.o
# Depende el paquete devtools en archlinux.
set +o posix
#set -x

[ $USER = "root" ] || { echo "requiere root"; exit 1; }
which mkarchroot linux32 mount umount || exit 1

CHROOT="/opt/arch32"
[ $1 ] && CHROOT=$1

exec 3<<__EOF__
[options]
HoldPkg      = pacman glibc
SyncFirst    = pacman
Architecture = i686

[core]
SigLevel = Never
Server   = ftp://mir1.archlinux.fr/archlinux/core/os/i686
[extra]
SigLevel = Never
Server   = ftp://mir1.archlinux.fr/archlinux/extra/os/i686
[community]
SigLevel = Never
Server   = ftp://mir1.archlinux.fr/archlinux/community/os/i686
[archlinuxfr]
SigLevel = Optional TrustAll
Server   = http://repo.archlinux.fr/i686
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

# Create if doesn't exist or update the chroot
if [ ! -d ${CHROOT} ] ; then 
    echo -e "#\n#\tCreando chroot en ${CHROOT}\n#"
    linux32 mkarchroot -C /proc/$$/fd/3 -M /proc/$$/fd/4 ${CHROOT} base base-devel
else
    echo -e "#\n#\tActualizando chroot en ${CHROOT}\n#"
    linux32 mkarchroot -u ${CHROOT} || exit 1
fi

# bindings
echo -e "#\n#\tCreando bindings hacia la chroot\n#"
mount --bind /dev ${CHROOT}/dev
mount --bind /dev/pts ${CHROOT}/dev/pts
mount --bind /dev/shm ${CHROOT}/dev/shm
mount --bind /proc ${CHROOT}/proc
mount --bind /proc/bus/usb ${CHROOT}/proc/bus/usb
mount --bind /sys ${CHROOT}/sys
mount --bind /tmp ${CHROOT}/tmp
mount --bind /home ${CHROOT}/home

# chroot
echo -e "#\n#\tEntrando en la la chroot\n#"
linux32 chroot ${CHROOT} /bin/bash

# umount bindings on exit
echo -e "#\n#\tDesmontando bindings\n#"
mount | sed -n "s@.*on \([^ ]*${CHROOT}[^ ]*\) .*@\1@p" | xargs -n1 umount -l
