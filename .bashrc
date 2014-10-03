# Denne filen blir utf|rt ved oppstart av alle nye shell (bash), 
# ogs} de som ikke er interaktive.

# Utf|r f|rst den globale bashrc-filen.  IKKE kopier inn den filen, da er
# du n{rmest garantert at ting vil slutte } virke n}r det er n|dvendig }
# gj|re endringer.  Du kan gj|re egne ting etter at den globale bashrc er
# utf|rt.

export PATH=$PATH:~/.local/bin

#[ -f ~/.local/lib/python2.7/site-packages/powerline/bindings/bash/powerline.sh ] && source ~/.local/lib/python2.7/site-packages/powerline/bindings/bash/powerline.sh


# Her kan du definere egne alias'er og sette bash-spesifikke variable.


alias psqltest="psql -d virt_selfservice -h dbpg-chaos2.uio.no -U virt_selfservice_user"
alias psqlprod="psql -d virt_selfservice -h dbpg-meridien.uio.no -U virt_selfservice_user"

alias cdprod="cd /GIT/PROD/perl-UiO/lib/SELF-UI/"
alias cdbeta="cd /GIT/BETA/perl-UiO/lib/SELF-UI/"
alias cdtest="cd /GIT/TEST/perl-UiO/lib/SELF-UI/"

#alias windows="rdesktop -d uio.no -u ragnahon -p - -k no -g 2500x1350 esx-ts"
alias windows="xfreerdp -d uio.no -u ragnahon -k no -g 1920x1080 esx-ts"

alias rssh='ssh -t father sudo ssh'
alias tmuxA='TERM=screen-256color-bce ; tmux attach'

[ -f /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion 
[ -f /usr/share/bash-completion/completion/find ] && source /usr/share/bash-completion/completion/find 

[ -f /etc/bash_completion.d/git ] && source /etc/bash_completion.d/git 
[ -f /etc/bash_completion.d/subversion ] && source /etc/bash_completion.d/subversion
[ -f /etc/bash_completion.d/yum.bash ] && source /etc/bash_completion.d/yum.bash
[ -f /etc/bash_completion.d/bash_completion_tmux.sh ] && source /etc/bash_completion.d/bash_completion_tmux.sh

# Make a small function to make rst debugging easier

rst2man () {
    /usr/bin/rst2man $1 | nroff -c -mandoc | less
}

tmux () {
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
    /usr/local/bin/tmux $*
    #/usr//bin/tmux $*
}

raghon=$HOME/.raghon-cfg/config
source $raghon/bashrc
