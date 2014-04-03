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

alias tmuxA='TERM=screen-256color-bce ; tmux attach'

[ -f /etc/bash_completion.d/git ] && source /etc/bash_completion.d/git
[ -f /etc/bash_completion.d/subversion ] && source /etc/bash_completion.d/subversion
[ -f /etc/bash_completion.d/yum.bash ] && source /etc/bash_completion.d/yum.bash
[ -f /usr/share/doc/tmux-1.6/examples/bash_completion_tmux.sh ] && source /usr/share/doc/tmux-1.6/examples/bash_completion_tmux.sh


# Make a small function to make rst debugging easier

rst2man () {
    /usr/bin/rst2man $1 | nroff -c -mandoc | less
}

# Init other scripts
# #################################3333

# Init SSH agent
source $raghon/init-ssh
