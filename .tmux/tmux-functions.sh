#!/bin/bash
#

# TMUX helper functions 
#

function set_session_name {
    unset TMUX
    name=$1
    if tmux has-session -t $name ; then 
        tmux switch-client -t $name
    else 
        tmux new-session -d -s $name
        tmux switch-client -t $name
    fi
}

set_session_name
