#!/bin/bash
set -e -u
set +o posix

ok() { echo -ne "\e[32m#\t$1\n\e[m"; }
nk() { echo -ne "\e[31m#\t$1\n\e[m"; exit 1; }

name=archlinux
iso_label="ARCH_$(date +%Y%m)"
version=$(date +%Y.%m.%d)
install_dir=arch
arch=$(uname -m)
work_dir=work
verbose="y"

# This function can be called after make_basefs()
get_linux_ver() {
    local ALL_kver
    eval $(grep ^ALL_kver ${work_dir}/root-image/etc/mkinitcpio.d/kernel26.kver)
    echo ${ALL_kver}
}

# Base installation (root-image)
make_basefs() {
    mkarchiso ${verbose} -D "${install_dir}" -p "base base-devel" create "${work_dir}"
    mkarchiso ${verbose} -D "${install_dir}" -p "memtest86+ syslinux mkinitcpio-nfs-utils nbd" create "${work_dir}"
}

# Additional packages (root-image)
make_packages() {
    ok "Update local custom repository"
    for i in custompkgs/*xz; do repo-add custompkgs/custompkgs.db.tar.gz $i; done
    arch_packages=$(grep -v ^# packages.i686 | xargs)
    custom_packages=$(find custompkgs/ -name '*.pkg.tar.xz' | sed -n 's/.*\/\([0-z]\+\)-.*/\1 /p' | xargs)
    mkarchiso ${verbose} -C /proc/$$/fd/3 -D "${install_dir}" -p "$arch_packages $custom_packages" create "${work_dir}"
}

# Customize installation (root-image)
make_root_image() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        cp -af root-image ${work_dir}
        chmod 750 ${work_dir}/root-image/etc/sudoers.d
        chmod 440 ${work_dir}/root-image/etc/sudoers.d/g_wheel
        mkdir -p ${work_dir}/root-image/etc/pacman.d
        wget -O ${work_dir}/root-image/etc/pacman.d/mirrorlist http://www.archlinux.org/mirrorlist/all/
        sed -i "s/#Server/Server/g" ${work_dir}/root-image/etc/pacman.d/mirrorlist
        chroot ${work_dir}/root-image /usr/sbin/locale-gen
        ok "Making the default user arch"
        chroot ${work_dir}/root-image /usr/sbin/useradd -p "" -u 2000 -g users -G "audio,disk,optical,wheel,log" arch
        ok "Chown/chmod the arch folder"
        chroot ${work_dir}/root-image /bin/chown -R arch:users /home/arch
        chroot ${work_dir}/root-image /bin/chmod -R 700 /home/arch
        ok "Making the default user crypt"
        chroot ${work_dir}/root-image /usr/sbin/useradd -p "" -u 1000 -g users -G "audio,disk,optical,wheel,log" crypt
        ok "Backup our archiso structure"
    tar -cjvf ${work_dir}/root-image/archiso.bz2 --exclude={archiso.bz2,*.iso,${PWD}/work} "$PWD"
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Copy mkinitcpio archiso hooks (root-image)
make_setup_mkinitcpio() {
   if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _hook
        for _hook in archiso archiso_pxe_nbd archiso_loop_mnt; do
            cp /lib/initcpio/hooks/${_hook} ${work_dir}/root-image/lib/initcpio/hooks
            cp /lib/initcpio/install/${_hook} ${work_dir}/root-image/lib/initcpio/install
        done
        : > ${work_dir}/build.${FUNCNAME}
   fi
}

# Prepare ${install_dir}/boot/
make_boot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _src=${work_dir}/root-image
        local _dst_boot=${work_dir}/iso/${install_dir}/boot
        mkdir -p ${_dst_boot}/${arch}
        mkinitcpio -c ./mkinitcpio.conf -b ${_src} -k /boot/vmlinuz26 -g ${_dst_boot}/${arch}/archiso.img
        mv ${_src}/boot/vmlinuz26 ${_dst_boot}/${arch}
        cp ${_src}/boot/memtest86+/memtest.bin ${_dst_boot}/memtest
        cp ${_src}/usr/share/licenses/common/GPL2/license.txt ${_dst_boot}/memtest.COPYING
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _src_syslinux=${work_dir}/root-image/usr/lib/syslinux
        local _dst_syslinux=${work_dir}/iso/${install_dir}/boot/syslinux
        mkdir -p ${_dst_syslinux}
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g;
             s|%ARCH%|${arch}|g" syslinux/syslinux.cfg > ${_dst_syslinux}/syslinux.cfg
        cp syslinux/splash.png ${_dst_syslinux}
        cp ${_src_syslinux}/{*.c32,*.com,*.0,memdisk} ${_dst_syslinux}
        mkdir -p ${_dst_syslinux}/hdt
        wget -O - http://pciids.sourceforge.net/v2.2/pci.ids | gzip -9 > ${_dst_syslinux}/hdt/pciids.gz
        cat ${work_dir}/root-image/lib/modules/*-ARCH/modules.alias | gzip -9 > ${_dst_syslinux}/hdt/modalias.gz
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Prepare /isolinux
make_isolinux() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mkdir -p ${work_dir}/iso/isolinux
        sed "s|%INSTALL_DIR%|${install_dir}|g" isolinux/isolinux.cfg > ${work_dir}/iso/isolinux/isolinux.cfg
        cp ${work_dir}/root-image/usr/lib/syslinux/isolinux.bin ${work_dir}/iso/isolinux/
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Process aitab
make_aitab() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        sed "s|%ARCH%|${arch}|g" aitab > ${work_dir}/iso/${install_dir}/aitab
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Build all filesystem images specified in aitab (.fs .fs.sfs .sfs)
make_prepare() {
    mkarchiso ${verbose} -D "${install_dir}" prepare "${work_dir}"
}

# Build ISO
make_iso() {
    mkarchiso ${verbose} -D "${install_dir}" -L "${iso_label}" iso "${work_dir}" "${name}-${version}-${arch}.iso"
}

# Write pacman.conf on a file descriptor
make_pacman_conf() {
exec 3<<__EOF__
[options]
HoldPkg      = pacman glibc
SyncFirst    = pacman
Architecture = i686
[core]
Server = ftp://ftp.rediris.es/mirror/archlinux/core/os/i686
[extra]
Server = ftp://ftp.rediris.es/mirror/archlinux/extra/os/i686
[community]
Server = ftp://ftp.rediris.es/mirror/archlinux/community/os/i686
[archlinuxfr]
Server = http://repo.archlinux.fr/i686
[custompkgs]
Server = file://${PWD}/custompkgs
__EOF__
}

if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root."
fi

if [[ $verbose == "y" ]]; then
    verbose="-v"
else
    verbose=""
fi

if [[ $# -gt 0 ]]; then
    ok "Deleting ${work_dir}"
    rm -rf ${work_dir}
    ok "Deleting iso files"
    rm -f *-${arch}.iso
fi

ok make_pacman_conf      && make_pacman_conf
ok make_basefs           && make_basefs
ok make_packages         && make_packages
ok make_root_image       && make_root_image
ok make_setup_mkinitcpio && make_setup_mkinitcpio
ok make_boot             && make_boot
ok make_syslinux         && make_syslinux
ok make_isolinux         && make_isolinux
ok make_aitab            && make_aitab
ok make_prepare          && make_prepare
ok make_iso              && make_iso
