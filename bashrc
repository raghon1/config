# RagHon standard Profile
#
# Defining a VI environemnt

EDITOR=vim
VISUAL=vim

export EDITOR VISUAL
case $- in
    *i*)    # interactive shell
            alias ls > /dev/null 2>&1 
	    [ $? -eq 0 ] && unalias ls
            set -o vi ;;
    *)      # non-interactive shell ;;
esac

# Fix TERMINAL for tmux


case "$TERM" in
    xterm)
        read -d '' terminal terminal_args < /proc/$PPID/cmdline
        case "${terminal##*/}" in
            gnome-terminal*|xterm*) TERM="$TERM-256color";;
        esac
        unset terminal terminal_args
        ;;
esac

alias tmuxA='TERM=screen-256color-bce ; tmux attach'

[ -f /etc/bash_completion.d/git ] && source /etc/bash_completion.d/git
[ -f /etc/bash_completion.d/subversion ] && source /etc/bash_completion.d/subversion
[ -f /etc/bash_completion.d/yum.bash ] && source /etc/bash_completion.d/yum.bash
[ -f /usr/share/doc/tmux-1.6/examples/bash_completion_tmux.sh ] && source /usr/share/doc/tmux-1.6/examples/bash_completion_tmux.sh


# Make a small function to make rst debugging easier

rst2man () {
    /usr/bin/rst2man $1 | nroff -c -mandoc | less
}


uio () {
    case $1 in
        on)
            ssh -fN uio-init
            sudo networksetup  -setsocksfirewallproxy Wi-Fi localhost 20000
            sudo networksetup  -setsocksfirewallproxystate Wi-Fi on
            ;;
        off)
            sudo networksetup  -setsocksfirewallproxystate Wi-Fi off
            ps -ef | awk '/ssh -fN uio-init/ && !/awk/ {print $2}' | xargs kill
            ;;
   esac
}

telenor() {
	[ -f "$HOME/.ssh/id_rsa_telenor" ] && key = "$HOME/.ssh/id_rsa_telenor" || key="$HOME/.ssh/id_rsa"
	ssh -i "$key" -fN telenor
	ssh -fN -D 30000 opsmgt01
	ssh -fN init-ports
	ssh -fN -D 24000 sun-mgt01
}

export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
