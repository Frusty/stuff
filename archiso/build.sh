#!/bin/bash
set -e -u

iso_name=archlinux
iso_label="ARCH_$(date +%Y%m)"
iso_version=$(date +%Y.%m.%d)
install_dir=arch
arch=$(uname -m)
work_dir=work
out_dir=out
#verbose="-v"
verbose=""
script_path=$(readlink -f ${0%/*})
pacman_conf="/proc/$$/fd/3"

# Write pacman.conf on a file descriptor
make_pacman_conf() {
exec 3<<__EOF__
[options]
HoldPkg      = pacman glibc
SyncFirst    = pacman
#CacheDir    = /var/cache/pacman/pkg/
Architecture = i686
[core]
SigLevel = PackageRequired
Include  = /etc/pacman.d/mirrorlist
[extra]
SigLevel = PackageRequired
Include  = /etc/pacman.d/mirrorlist
[community]
SigLevel = PackageRequired
Include  = /etc/pacman.d/mirrorlist
[custompkgs]
SigLevel = Optional TrustAll
Server = file://${script_path}/custompkgs
__EOF__
}

setup_workdir() {
    cache_dirs=($(pacman -v 2>&1 | grep '^Cache Dirs:' | sed 's/Cache Dirs:\s*//g'))
    mkdir -p "${work_dir}"
    sed -r "s|^#?\\s*CacheDir.+|CacheDir = $(echo -n ${cache_dirs[@]})|g" \
        "${pacman_conf}" > "${pacman_conf}"
}

# Base installation (root-image)
make_basefs() {
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" init
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" -p "memtest86+ mkinitcpio-nfs-utils nbd" install
}

# Additional packages (root-image)
make_packages() {
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" -p "$(grep -v ^# ${script_path}/packages.${arch})" install
}

make_custom_repo() {
    for i in custompkgs/*xz; do repo-add ${script_path}/custompkgs/custompkgs.db.tar.gz $i; done
    custom_packages=$(find ${script_path}/custompkgs/ -name '*.pkg.tar.xz' | sed -n 's/.*\/\([-0-z]\+\)-.*/\1 /p' | xargs)
}

make_custom_packages() {
    mkarchiso ${verbose} -C "${pacman_conf}" -w "${work_dir}" -D "${install_dir}" -p "$custom_packages" install
}

# Copy mkinitcpio archiso hooks (root-image)
make_setup_mkinitcpio() {
   if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _hook
        for _hook in archiso archiso_shutdown archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_loop_mnt; do
            cp /usr/lib/initcpio/hooks/${_hook} ${work_dir}/root-image/usr/lib/initcpio/hooks
            cp /usr/lib/initcpio/install/${_hook} ${work_dir}/root-image/usr/lib/initcpio/install
        done
        cp /usr/lib/initcpio/install/archiso_kms ${work_dir}/root-image/usr/lib/initcpio/install
        cp /usr/lib/initcpio/archiso_shutdown ${work_dir}/root-image/usr/lib/initcpio
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
        mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" \
            -r 'mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img' \
            run
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
        cat ${work_dir}/root-image/usr/share/hwdata/pci.ids | gzip -9 > ${_dst_syslinux}/hdt/pciids.gz
        cat ${work_dir}/root-image/usr/lib/modules/*-ARCH/modules.alias | gzip -9 > ${_dst_syslinux}/hdt/modalias.gz
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
make_customize_root_image() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        cp -af ${script_path}/root-image ${work_dir}

        patch ${work_dir}/root-image/usr/bin/pacman-key < ${script_path}/pacman-key-4.0.3_unattended-keyring-init.patch
        wget -O ${work_dir}/root-image/etc/pacman.d/mirrorlist 'https://www.archlinux.org/mirrorlist/?country=all&protocol=http&use_mirror_status=on'

        lynx -dump -nolist 'https://wiki.archlinux.org/index.php/Installation_Guide?action=render' >> ${work_dir}/root-image/root/install.txt

        mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" -r '/usr/local/sbin/customize_root_image.sh' run
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Custom customizations!
make_customize_root_image_2() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        find ${script_path}/root-image -type f -exec chmod 644 {} \;
        find ${script_path}/root-image -type d -exec chmod 755 {} \;
        find ${script_path}/root-image -regextype posix-awk -regex "(.*bin/.*|.*rc.d/.*|.*sh.*)" -type f -exec chmod +x "{}" \;
        mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" \
            -r 'chown -R mpd /var/lib/mpd' \
            run
        chroot ${work_dir}/root-image /usr/bin/find /home/arch -type d -exec /bin/chmod 700 {} \;
        chroot ${work_dir}/root-image /usr/bin/find /home/arch -type f -exec /bin/chmod 600 {} \;
        chroot ${work_dir}/root-image /bin/chown -R arch:users /home/arch
        tar -cjvf ${work_dir}/root-image/archiso.bz2 --exclude={archiso.bz2,*.iso,${PWD}/work} ${script_path}
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Split out /usr/lib/modules from root-image (makes more "dual-iso" friendly)
make_usr_lib_modules() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mv ${work_dir}/root-image/usr/lib/modules ${work_dir}/usr-lib-modules
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
make_aitab() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        sed "s|%ARCH%|${arch}|g" ${script_path}/aitab > ${work_dir}/iso/${install_dir}/aitab
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Build all filesystem images specified in aitab (.fs .fs.sfs .sfs)
make_prepare() {
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" pkglist
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" prepare
}

# Build ISO
make_iso() {
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" checksum
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" -L "${iso_label}" -o "${out_dir}" iso "${iso_name}-${iso_version}-${arch}.iso"
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
    setup_workdir
    make_pacman_conf
    make_custom_repo
    make_basefs
    make_packages
    make_custom_packages
    make_setup_mkinitcpio
    make_boot
    make_syslinux
    make_isolinux
    make_customize_root_image
    make_customize_root_image_2
    make_usr_lib_modules
    make_usr_share
    make_aitab
    make_prepare
    make_iso
}

if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root."
    _usage 1
fi

work_dir=${work_dir}/${arch}

#clean_single
purge_single
make_common_single core
