alias ls='ls --color=auto'
alias vi='vim'
alias grep='egrep --color'
alias ssh='ssh -X -4'
alias wget='wget -U "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.10) Gecko/2009042810 GranParadiso/3.0.10" --execute robots=off'
alias walk='snmpwalk -c uocpublic -v 1'
alias rdesktop='rdesktop -0 -z -g95% -uAdministrador -kes -a16'
alias pwgen='perl -le "print map { (a..z,A..Z,0..9)[rand 62] } 1..pop"'
alias dicks='perl -le "for (1..pop){print \"8\".\"=\"x((rand 10)+1).\"D\"}"'
alias rsync_size='rsync -aivh --size-only --progress'
alias mtr='mtr -n4 --curses'
alias nmapag='nmap -v -AT4' # Agressive scan
alias nmaprp='nmap -n -sP -PE --reason' # Real ping scan
alias stracefn='strace -dCvrttTs65535'
alias nmonf='NMON=lmdDntu nmon'
alias beeep='echo -en "\007"'
alias qemucd='qemu -m 512 -boot d -cdrom'
alias chroxy='chromium --no-first-run --user-data-dir=sss --proxy-server="localhost:8080"'
sshmount(){ [ -d "/tmp/${1}" ] && { echo "# /tmp/${1} Existe\!"; }|| { mkdir /tmp/${1} && sshfs -o umask=333 root@${1}:/ /tmp/$1 && echo "# Ok -> /tmp/${1}" || rmdir /tmp/${1}; }; }
findlf(){ find $PWD -xdev -ls | awk {'print $7"\t"$11'} | sort -rn | head -n 10; }
cprxvt256trm(){ ping -qc1 "$1" >/dev/null &&  scp /usr/share/terminfo/r/rxvt-256color root@${1}:/usr/share/terminfo/r/rxvt-256color; }
export PATH=$PATH:/usr/local/bin:/usr/local/sbin
export EDITOR=vim
export TERMINAL=urxvtc
export BROWSER=chromium
export PS1='\[\033[0;33m\]┌┤\[\033[0m\033[1;33m\]\u\[\033[0;32m\]@\[\033[0;31m\]\h\[\033[0m\033[0;36m\]:\w\[\033[0m\033[0;33m\]│\[\033[0m\]\t\n\[\033[0;33m\]└\[\033[0m\033[1;34m\]`echo $?`\[\033[0;33m\]┐\[\033[0m\]$ '
which keychain >/dev/null 2>&1 && [ -f ~/.ssh/keys/id_rsa_ubuntest1 ] && eval $(keychain --eval --nogui -Q -q keys/id_rsa_ubuntest1)
