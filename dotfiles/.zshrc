# .zshrc
#
# {{{ Init
# -------------------------------------------------------------------------------
autoload -U compinit promptinit
compinit
promptinit
unsetopt beep
bindkey -e # emacs keybindings
# }}}
# {{{ Exports
# -------------------------------------------------------------------------------
export HISTFILE=~/.histfile
export HISTSIZE=1000
export SAVEHIST=1000
export PATH=$PATH:/usr/local/bin:/usr/local/sbin
export EDITOR=vim
export TERMINAL=urxvtc
export BROWSER=chromium
# }}}
# {{{ Prompt
# -------------------------------------------------------------------------------
export PROMPT=$'%{$fg[yellow]%}┌┤%{$fg_bold[yellow]%}%n%{$reset_color%}%{$fg[green]%}@%{$fg[red]%}%m%{$fg[yellow]%}(%{$fg[cyan]%}%l%{$fg[yellow]%})%{$fg_bold[blue]%}%~%{$fg[yellow]%}│%{$reset_color%}%*\n%{$fg[yellow]%}└%{$fg_bold[blue]%}%?%{$reset_color%}%{$fg[yellow]%}┐%{$reset_color%}%# '
# }}}
# {{{ Aliases
# -------------------------------------------------------------------------------
alias ls='ls --color=auto'
alias vi='vim'
alias grep='egrep --color'
alias ssh='ssh -Y -4'
alias wget='wget --header="Accept-Charset: utf8" -U "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.10) Gecko/2009042810 GranParadiso/3.0.10" --execute robots=off'
alias walk='snmpwalk -c uocpublic -v 1'
alias rdesktop='rdesktop -0 -z -g95% -uAdministrador -kes -a16'
alias pwgen='perl -le "print map { (a..z,A..Z,0..9)[rand 62] } 1..pop"'
alias dicks='perl -le "for (1..pop){print \"8\".\"=\"x((rand 10)+1).\"D\"}"'
alias hex2char='perl -le "print pack(\"H*\", pop)"'
alias char2hex='perl -le "print unpack(\"H*\", pop)"'
alias htpasswd='perl -le "print crypt(pop, int(rand(10**10)))"'
alias rsync_size='rsync -aivh --size-only --progress'
alias mtr='mtr -n4 --curses'
alias nmapag='nmap -v -AT4' # Agressive scan
alias nmaprp='nmap -sP -PE --reason -n' # Real ping scan
alias nmappr='nmap -sV -sS -O -f -n' # Proper scan
alias stracefn='strace -dCvrttTs65535'
alias nmonf='NMON=lmdDntu nmon'
alias beeep='echo -en "\007"'
alias qemucd='qemu-system-i386 -m 256 -boot d -cdrom'
alias chroxy='chromium --no-first-run --user-data-dir=/tmp/$(date +%F_%H:%M:%S:%N) --proxy-server="localhost:8080"'
alias chromium_tmp='chromium --no-first-run --user-data-dir=/tmp/$(date +%F_%H:%M:%S:%N)'
alias webcam='mplayer -tv driver=v4l2 tv://'
# }}}
# {{{ Keybindings
# -------------------------------------------------------------------------------
bindkey "\e[1~"  beginning-of-line    # Home
bindkey "\e[4~"  end-of-line          # End
bindkey "\e[5~"  beginning-of-history # PageUp
bindkey "\e[6~"  end-of-history       # PageDown
bindkey "\e[2~"  quoted-insert        # Ins
bindkey "\e[3~"  delete-char          # Del
bindkey "\e[5C"  forward-word
bindkey "\eOc"   emacs-forward-word
bindkey "\e[5D"  backward-word
bindkey "\eOd"   emacs-backward-word
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word
bindkey "\e[Z"   reverse-menu-complete # Shift+Tab
# for rxvt
bindkey "\e[7~"  beginning-of-line     # Home
bindkey "\e[8~"  end-of-line           # End
# for non RH/Debian xterm, can't hurt for RH/Debian xterm
bindkey "\eOH"   beginning-of-line
bindkey "\eOF"   end-of-line
# for freebsd console
bindkey "\e[H"   beginning-of-line
bindkey "\e[F"   end-of-line
# }}}
# {{{ Functions
# -------------------------------------------------------------------------------
sshmount(){ [ -d "/tmp/${1}" ] && { echo "# /tmp/${1} Existe\!"; }|| { mkdir /tmp/${1} && sshfs -o umask=333 root@${1}:/ /tmp/$1 && echo "# Ok -> /tmp/${1}" || rmdir /tmp/${1}; }; }
findlf(){ find $PWD -xdev -ls | awk {'print $7"\t"$11'} | sort -rn | head -n 10; }
cprxvt256trm(){ ping -qc1 "$1" >/dev/null &&  scp /usr/share/terminfo/r/rxvt-256color root@${1}:/usr/share/terminfo/r/rxvt-256color; }
dualscreen(){ ARRAY=( $(xrandr | sed -n 's/^\(.*\) connected.*$/\1/p' | xargs) ) && xrandr --output ${ARRAY[1]} --right-of ${ARRAY[2]}; }
samescreen(){ ARRAY=( $(xrandr | sed -n 's/^\(.*\) connected.*$/\1/p' | xargs) ) && xrandr --output ${ARRAY[1]} --same-as ${ARRAY[2]}; }
# }}}
# {{{ Autostart
# -------------------------------------------------------------------------------
which keychain >/dev/null 2>&1 && [ -f ~/.ssh/keys/id_rsa_ubuntest1 ] && eval $(keychain --eval --nogui -Q -q keys/id_rsa_ubuntest1)
# }}}
