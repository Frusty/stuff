#!/bin/bash

set -e -u

iso_name=archlinux
iso_label="ARCH_$(date +%Y%m)"
iso_version=$(date +%Y.%m.%d)
install_dir=arch
arch=$(uname -m)
work_dir=work
out_dir=out
verbose="-v"
script_path=$(readlink -f ${0%/*})

# Write pacman.conf on a file descriptor
make_pacman_conf() {
exec 3<<__EOF__
[options]
HoldPkg      = pacman glibc
SyncFirst    = pacman
Architecture = i686
SigLevel     = Never
[core]
Server = http://mir1.archlinux.fr/archlinux/core/os/i686
[extra]
Server = http://mir1.archlinux.fr/archlinux/extra/os/i686
[community]
Server = http://mir1.archlinux.fr/archlinux/community/os/i686
[archlinuxfr]
Server = http://repo.archlinux.fr/i686
[custompkgs]
Server = file://${script_path}/custompkgs
__EOF__
}

# Base installation (root-image)
make_basefs() {
    mkarchiso ${verbose} -C /proc/$$/fd/3 -w "${work_dir}" -D "${install_dir}" -p "base" create
    mkarchiso ${verbose} -C /proc/$$/fd/3 -w "${work_dir}" -D "${install_dir}" -p "memtest86+ syslinux mkinitcpio-nfs-utils nbd curl" create
}

# Additional packages (root-image)
make_packages() {
    mkarchiso ${verbose} -C /proc/$$/fd/3 -w "${work_dir}" -D "${install_dir}" -p "$(grep -v ^# ${script_path}/packages.${arch})" create
}

make_custom_packages() {
    for i in custompkgs/*xz; do repo-add ${script_path}/custompkgs/custompkgs.db.tar.gz $i; done
    custom_packages=$(find ${script_path}/custompkgs/ -name '*.pkg.tar.xz' | sed -n 's/.*\/\([0-z]\+\)-.*/\1 /p' | xargs)
    mkarchiso ${verbose} -C /proc/$$/fd/3 -w "${work_dir}" -D "${install_dir}" -p "$custom_packages" create
}

# Copy mkinitcpio archiso hooks (root-image)
make_setup_mkinitcpio() {
   if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _hook
        for _hook in archiso archiso_shutdown archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_loop_mnt; do
            cp /lib/initcpio/hooks/${_hook} ${work_dir}/root-image/lib/initcpio/hooks
            cp /lib/initcpio/install/${_hook} ${work_dir}/root-image/lib/initcpio/install
        done
        cp /lib/initcpio/install/archiso_kms ${work_dir}/root-image/lib/initcpio/install
        cp /lib/initcpio/archiso_shutdown ${work_dir}/root-image/lib/initcpio
        cp /lib/initcpio/archiso_pxe_nbd ${work_dir}/root-image/lib/initcpio
        cp ${script_path}/mkinitcpio.conf ${work_dir}/root-image/etc/mkinitcpio-archiso.conf
        : > ${work_dir}/build.${FUNCNAME}
   fi
}

# Prepare ${install_dir}/boot/
make_boot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _src=${work_dir}/root-image
        local _dst_boot=${work_dir}/iso/${install_dir}/boot
        mkdir -p ${_dst_boot}/${arch}
        mkarchroot -n -r "mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img" ${_src}
        mv ${_src}/boot/archiso.img ${_dst_boot}/${arch}/archiso.img
        mv ${_src}/boot/vmlinuz-linux ${_dst_boot}/${arch}/vmlinuz
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
        for _cfg in ${script_path}/syslinux/*.cfg; do
            sed "s|%ARCHISO_LABEL%|${iso_label}|g;
                 s|%INSTALL_DIR%|${install_dir}|g;
                 s|%ARCH%|${arch}|g" ${_cfg} > ${_dst_syslinux}/${_cfg##*/}
        done
        cp ${script_path}/syslinux/splash.png ${_dst_syslinux}
        cp ${_src_syslinux}/*.c32 ${_dst_syslinux}
        cp ${_src_syslinux}/*.com ${_dst_syslinux}
        cp ${_src_syslinux}/*.0 ${_dst_syslinux}
        cp ${_src_syslinux}/memdisk ${_dst_syslinux}
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
        sed "s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/isolinux/isolinux.cfg > ${work_dir}/iso/isolinux/isolinux.cfg
        cp ${work_dir}/root-image/usr/lib/syslinux/isolinux.bin ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/isohdpfx.bin ${work_dir}/iso/isolinux/
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Customize installation (root-image)
# NOTE: mkarchroot should not be executed after this function is executed, otherwise will overwrites some custom files.
make_customize_root_image() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        cp -af ${script_path}/root-image ${work_dir}
        chmod 750 ${work_dir}/root-image/etc/sudoers.d
        chmod 440 ${work_dir}/root-image/etc/sudoers.d/g_wheel
        mkdir -p ${work_dir}/root-image/etc/pacman.d
        wget -O ${work_dir}/root-image/etc/pacman.d/mirrorlist http://www.archlinux.org/mirrorlist/all/
        sed -i "s/#Server/Server/g" ${work_dir}/root-image/etc/pacman.d/mirrorlist
        chroot ${work_dir}/root-image /usr/sbin/locale-gen
        chroot ${work_dir}/root-image /usr/sbin/useradd -m -p "" -g users -G "audio,disk,optical,wheel" arch
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Custom customizations!
make_customize_root_image_2() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        find ${script_path}/root-image -type f -exec chmod 644 {} \;
        find ${script_path}/root-image -type d -exec chmod 755 {} \;
        find ${script_path}/root-image -name '*bin' -type d | xargs -n1 -I@ find @ -type f -exec chmod +x "{}" \;
        chown -R root:root ${script_path}/root-image
        chroot ${work_dir}/root-image /usr/bin/find /home/arch -type d -exec /bin/chmod 700 {} \;
        chroot ${work_dir}/root-image /usr/bin/find /home/arch -type f -exec /bin/chmod 600 {} \;
        chroot ${work_dir}/root-image /bin/chown -R arch:users /home/arch
#        chroot ${work_dir}/root-image /usr/sbin/useradd -m -p "" -u 1000 -g users -G "audio,disk,optical,wheel,log" crypt
        tar -cjvf ${work_dir}/root-image/archiso.bz2 --exclude={archiso.bz2,*.iso,${PWD}/work} ${script_path}
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Copy mkinitcpio archiso hooks (root-image)
make_setup_mkinitcpio() {
   if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _hook
        for _hook in archiso archiso_shutdown archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_loop_mnt; do
            cp /lib/initcpio/hooks/${_hook} ${work_dir}/root-image/lib/initcpio/hooks
            cp /lib/initcpio/install/${_hook} ${work_dir}/root-image/lib/initcpio/install
        done
        cp /lib/initcpio/install/archiso_kms ${work_dir}/root-image/lib/initcpio/install
        cp /lib/initcpio/archiso_shutdown ${work_dir}/root-image/lib/initcpio
        cp /lib/initcpio/archiso_pxe_nbd ${work_dir}/root-image/lib/initcpio
        cp ${script_path}/mkinitcpio.conf ${work_dir}/root-image/etc/mkinitcpio-archiso.conf
        : > ${work_dir}/build.${FUNCNAME}
   fi
}

# Prepare ${install_dir}/boot/
make_boot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _src=${work_dir}/root-image
        local _dst_boot=${work_dir}/iso/${install_dir}/boot
        mkdir -p ${_dst_boot}/${arch}
        mkarchroot -n -r "mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img" ${_src}
        mv ${_src}/boot/archiso.img ${_dst_boot}/${arch}/archiso.img
        mv ${_src}/boot/vmlinuz-linux ${_dst_boot}/${arch}/vmlinuz
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
        for _cfg in ${script_path}/syslinux/*.cfg; do
            sed "s|%ARCHISO_LABEL%|${iso_label}|g;
                 s|%INSTALL_DIR%|${install_dir}|g;
                 s|%ARCH%|${arch}|g" ${_cfg} > ${_dst_syslinux}/${_cfg##*/}
        done
        cp ${script_path}/syslinux/splash.png ${_dst_syslinux}
        cp ${_src_syslinux}/*.c32 ${_dst_syslinux}
        cp ${_src_syslinux}/*.com ${_dst_syslinux}
        cp ${_src_syslinux}/*.0 ${_dst_syslinux}
        cp ${_src_syslinux}/memdisk ${_dst_syslinux}
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
        sed "s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/isolinux/isolinux.cfg > ${work_dir}/iso/isolinux/isolinux.cfg
        cp ${work_dir}/root-image/usr/lib/syslinux/isolinux.bin ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/isohdpfx.bin ${work_dir}/iso/isolinux/
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Split out /lib/modules from root-image (makes more "dual-iso" friendly)
make_lib_modules() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mv ${work_dir}/root-image/lib/modules ${work_dir}/lib-modules
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Split out /usr/share from root-image (makes more "dual-iso" friendly)
make_usr_share() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mv ${work_dir}/root-image/usr/share ${work_dir}/usr-share
        : > ${work_dir}/build.${FUNCNAME}
    fi
}


# Process aitab
# args: $1 (core | netinstall)
make_aitab() {
    local _iso_type=${1}
    if [[ ! -e ${work_dir}/build.${FUNCNAME}_${_iso_type} ]]; then
        sed "s|%ARCH%|${arch}|g" ${script_path}/aitab.${_iso_type} > ${work_dir}/iso/${install_dir}/aitab
        : > ${work_dir}/build.${FUNCNAME}_${_iso_type}
    fi
}

# Build all filesystem images specified in aitab (.fs .fs.sfs .sfs)
make_prepare() {
    mkarchiso ${verbose} -C /proc/$$/fd/3 -w "${work_dir}" -D "${install_dir}" prepare
}

# Build ISO
# args: $1 (core | netinstall)
make_iso() {
    local _iso_type=${1}
    mkarchiso ${verbose} -C /proc/$$/fd/3 -w "${work_dir}" -D "${install_dir}" checksum
    mkarchiso ${verbose} -C /proc/$$/fd/3 -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -o "${out_dir}" iso "${iso_name}-${iso_version}-${_iso_type}-${arch}.iso"
}

purge_single ()
{
    if [[ -d ${work_dir} ]]; then
        find ${work_dir} -mindepth 1 -maxdepth 1 \
            ! -path ${work_dir}/iso -prune \
            | xargs rm -rf
    fi
}

clean_single ()
{
    rm -rf ${work_dir}
    rm -f ${out_dir}/${iso_name}-${iso_version}-*-${arch}.iso
}

make_common_single() {
    make_pacman_conf
    make_basefs
    make_packages
    make_custom_packages
    make_setup_mkinitcpio
    make_boot
    make_syslinux
    make_isolinux
    make_customize_root_image
    make_customize_root_image_2
    make_lib_modules
    make_usr_share
    make_aitab $1
    make_prepare $1
    make_iso $1
}

if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root."
    _usage 1
fi

work_dir=${work_dir}/${arch}

#clean_single
purge_single
make_common_single core
