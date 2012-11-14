#!/bin/bash

set -e -u

locale-gen

ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime

usermod -s /bin/zsh root
cp -aT /etc/skel/ /root/
sed -i 's/^root:x:/root:U6aMy0wojraho:/g' /etc/passwd

useradd -m -p "" -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel,vlock" -s /bin/zsh arch

chmod 750 /etc/sudoers.d
chmod 440 /etc/sudoers.d/g_wheel

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

sed 's#\(^ExecStart=-/sbin/agetty\)#\1 --autologin arch#;
     s#\(^Alias=getty.target.wants/\).\+#\1autologin@tty1.service#' \
     /usr/lib/systemd/system/getty@.service > /etc/systemd/system/autologin@.service

systemctl disable getty@tty1.service
systemctl enable multi-user.target pacman-init.service autologin@.service wicd.service
