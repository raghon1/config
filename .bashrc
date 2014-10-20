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
  if [ -f /usr/local/bin/tmux ] ; then
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
    /usr/local/bin/tmux $*
    #/usr//bin/tmux $*
  else 
    /usr/bin/tmux $*
  fi
}

old_irssi () {
#    sessions=$(tmux list-sessions -F '#{session_attached}:#{session_name}')
    if [ $sessions -eq 1 ] ; then
        # print tmux not started
        tmux -d new-session -s Saruman -n CHAT irssi
        exit 0
    fi
    #for s in $sessions ; do
        #IFS=:
        #set -A muxes $s
        #case ${muxes[0]} in 

    #done
}


irssi() {
    sessions=$(tmux list-sessions -F '#{session_attached}:#{session_name}')
    if tmux has-session -t Saruman >/dev/null 2>&1  ; then
        # Check if irssi window exist
        irssi_exist=0
        for window in $(tmux list-windows -t Saruman -F '#{window_name}') ; do
            if [ "$window" = "CHAT" ] ; then
                irssi_exist=1
                echo $windowd
            fi
        done
        echo "vi har chat windu $irssi_exist"
        if test $irssi_exist -eq 0 ; then
            tmux new-window -t Saruman: -n CHAT irssi
            tmux move-window -s Saruman:0 -t Saruman:+
            tmux move-window -s Saruman:CHAT -t Saruman:0
        fi
        attached=0
        for s in $sessions ; do
            echo $s
            case $s in
                1:*) attached=1;;
            esac
        done
        echo "ATTACHED = $attached"
        if [ $attached -eq 1 ] ; then
            tmux switch-client -t Saruman:CHAT
            #tmux select-window -t CHAT
        else
            echo "ATTACHED"
            tmux attach-session -t Saruman:CHAT
        fi
    else
        tmux new-session -s Saruman -n CHAT irssi
        return 0
    fi
}


raghon=$HOME/.raghon-cfg/config
source $raghon/bashrc
