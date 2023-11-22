bindkey -e

# DEFAULT VARIABLES
export ZDOTDIR=$HOME/.config/zsh
export ZPLUGDIR=$ZDOTDIR/zsh-plugins
export HISTFILE=~/.local/share/zsh/.histfile
export HISTSIZE=10000
export SAVEHIST=10000

setopt appendhistory
setopt SHARE_HISTORY

set -o pipefail


# COMMAND TIME TAKEN
cmd_time_begin=""
cmd_time_taken=""

unix_time_ms() {
    seconds="$(date +%s.%N)"
    (( milliseconds = $seconds * 1000 ))
    echo $milliseconds
}

time_measure_begin() {
    cmd_time_begin=$(unix_time_ms)
}

time_measure_end() {
    [ "$cmd_time_begin" = "" ] && return

    cmd_time_taken=$(($(unix_time_ms) - $cmd_time_begin))
    cmd_time_begin=""

    # The time is rounded to the nearest second. The measurement itself may take a long time (tens of ms, perhaps hundreds on slower machines),
    # so being more precise is kinda pointless.
    (( $cmd_time_taken < 1000.0 )) && 
        cmd_time_taken=" <1s" &&
        return

    integer seconds=$(($cmd_time_taken / 1000.0 + 0.5))

    integer hours=$(($seconds / 3600))
    integer seconds=$(($seconds % 3600))

    integer minutes=$(($seconds / 60))
    integer seconds=$(($seconds % 60))

    [ $hours -ne 0 ] && 
        cmd_time_taken=" ~$hours"h" $minutes"m" $seconds"s ||
    [ $minutes -ne 0 ] && 
        cmd_time_taken=" ~$minutes"m" $seconds"s ||
        cmd_time_taken=" ~$seconds"s
}

preexec_functions+=(time_measure_begin)
precmd_functions+=(time_measure_end)



# VCS INFO
setopt PROMPT_SUBST
autoload -Uz vcs_info # enable vcs_info
precmd () { vcs_info } # always load before displaying the prompt
zstyle ':vcs_info:*' formats ' %F{245}%s:%f%F{250}%b%f' # git:master



# TAB COMPLETION:
autoload -Uz compinit
zstyle ':completion:*' menu select
compinit
_comp_options+=(globdots) # Include hidden files.



# PROMPT:
PROMPT='%F{4}%n@%m%f: %F{2}%~%f$ '
RPROMPT='$vcs_info_msg_0_ %F{245}r%f:%F{250}%?%f%F{4}$cmd_time_taken%f'



# SOURCE PLUGINS:
source_file_if_exists() {
    [ -e $1 ] && source $1
}

source_git_plugin() { 
    ( which git > /dev/null ) || return

    [ -z $2 ] && 
        plugin_name=$(echo $1 | awk -F'/' '{ print $NF }') || 
        plugin_name=$2

    [ ! -d "$ZPLUGDIR/$plugin_name" ] && git clone "$1" "$ZPLUGDIR/$plugin_name"

    source_file_if_exists "$ZPLUGDIR/$plugin_name/$plugin_name.plugin.zsh" || \
    source_file_if_exists "$ZPLUGDIR/$plugin_name/$plugin_name.zsh"
}

source_git_plugin "https://github.com/zsh-users/zsh-autosuggestions"
source_git_plugin "https://github.com/zsh-users/zsh-syntax-highlighting"

# BAT:
if ( which bat > /dev/null )
then 
    alias cat="bat --pager=never"
fi



# VI MODE:
set -o vi

KEYTIMEOUT=5 # Remove mode switching delay.

function _set_beam_cursor() {
    echo -ne '\e[6 q'
}

function _set_block_cursor() {
    echo -ne '\e[1 q'
}

function zle-keymap-select {
    if   [[ ${KEYMAP} == vicmd ]] ||
         [[ $1 = 'block' ]]; then
        _set_block_cursor
    elif [[ ${KEYMAP} == main ]] ||
         [[ ${KEYMAP} == viins ]] ||
         [[ ${KEYMAP} = '' ]] ||
         [[ $1 = 'beam' ]]; then
        _set_beam_cursor
    fi
}
zle -N zle-keymap-select

precmd_functions+=(_set_beam_cursor)

_last_escape_key_pressed=""
_last_escape_key_press_time=""

function _record_escape_key() {
    local key="$1"
    LBUFFER+="$key"
    _last_escape_key_pressed="$key"
    _last_escape_key_press_time=$(unix_time_ms)
}

function _try_escape() {
    local key_1="$1"
    local key_2="$2"

    if [[ "$_last_escape_key_pressed" != "$key_1" ]]; then
        _record_escape_key "$key_2"
        return
    fi

    local time_taken=$(($(unix_time_ms) - $_last_escape_key_press_time))
    if [[ $time_taken -lt 150 ]]; then
        zle vi-backward-delete-char # delete the last character
        zle vi-cmd-mode  # switch to normal mode
        return
    fi

    _record_escape_key "$key_2"
}

function _escape_j() {
    _try_escape "k" "j"
}

function _escape_k () {
    _try_escape "j" "k"
}

zle -N _escape_j
zle -N _escape_k
bindkey -M viins "j" _escape_j
bindkey -M viins "k" _escape_k

# ALIASES:
alias ls="ls --color=auto" \
      mv="mv -iv" \
      cp="cp -iv" \
      mkdir="mkdir -pv" \
      rm="rm -vI" \
      grep="grep --color=auto" \
      diff="diff --color=auto" \
      u="cd .." \
      uu="cd ../.." \
      uuu="cd ../../.." \
      uuuu="cd ../../../.." \
      uuuuu="cd ../../../../.." 

_ll_exa_args="-alghu --git --group-directories-first"

if ( which eza > /dev/null )
then
    _alias_ll="eza $_ll_exa_args"
elif ( which exa > /dev/null )
then
    _alias_ll="exa $_ll_exa_args"
else
    _alias_ll="ls -alhs --group-directories-first"
fi

alias ll="$_alias_ll"
alias la="$_alias_ll"

# RANGER/LF NAVIGATION:
intcd() {
    tmp="$(mktemp)"
    trap 'rm -f $tmp >/dev/null 2>&1' HUP INT QUIT TERM PWR EXIT >/dev/null 2>&1
    runintcd "$tmp" # run the interactive directory browser
    dir="$(cat "$tmp")"
    command rm -f $tmp
    [ -d $dir ] && [ "$dir" != "$(pwd)" ] && cd $dir
}

if ( which lf > /dev/null )
then
    runintcd() {
        ranger --choosedir="$1"
    }
elif ( which ranger > /dev/null )
then
    runintcd() {
        lf -last-dir-path="$1"
    }
fi

$( typeset -f runintcd > /dev/null ) && bindkey -s "^o" "intcd\n" # ctrl+o

# FZF HISTORY

if ( which fzf > /dev/null )
then
    _fzf_history() {
        # tac:
        # - reverse the order (display last command first)
        # sed:
        # - remove ZSH-generated leading info (separated by ";")
        # - trim whitespace
        # awk:
        # - remove duplicate lines
        local result="$(tac "$HISTFILE" | sed 's/^[^;]*;//' | sed 's/\s*//' | sed 's/\s*$//' | awk '!seen[$0]++' | fzf)"

        if [ -n "$result" ]; then
            LBUFFER+="$result"
        fi
    }

    local keymap="^r"
    zle -N _fzf_history
    bindkey -M vicmd "$keymap" _fzf_history
    bindkey -M viins "$keymap" _fzf_history
fi

# FIND GIT REPOS
if ( which fzf > /dev/null )
then
    fzfgit() {
        local dir="$1"
        if [ -z "$dir" ]; then
            dir="$PWD"
        fi
            
        local result="$(find "$dir" -name ".git" -type d -prune -exec dirname {} \; 2>/dev/null | fzf)"
        if [ -n "$result" ]; then
            cd "$result"
        fi
    }
fi

# OPTIONAL STARTUP SCRIPT
ext_script="$ZDOTDIR/.zshrc-ext"
[ -e "$ext_script" ] && source $ext_script
