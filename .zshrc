bindkey -e

[ -z "$ZDOTDIR" ] && export ZDOTDIR=$HOME
[ -z "$ZPLUGDIR" ] && export ZPLUGDIR=$ZDOTDIR/zsh-plugins
[ -z "$HISTFILE" ] && export HISTFILE=~/.local/share/zsh/.histfile
[ -z "$HISTSIZE" ] && export HISTSIZE=10000
[ -z "$SAVEHIST" ] && export SAVEHIST=10000

# COMMAND TIME TAKEN

cmd_time_begin=""
cmd_time_taken=""

unix_time_ms() 
{
    seconds="$(date +%s.%N)"
    (( milliseconds = $seconds * 1000 ))
    echo $milliseconds
}

time_measure_begin() 
{
    cmd_time_begin=$(unix_time_ms)
}

time_measure_end()
{
    if [ "$cmd_time_begin" = "" ]
    then
        return
    fi

    (( cmd_time_taken = $(unix_time_ms) - $cmd_time_begin))

    # The time is rounded to the nearest second. The measurement itself may take a long time (tens of ms, perhaps hundreds on slower machines),
    # so being more precise is kinda pointless.
    if (( $cmd_time_taken < 1000.0 ))
    then
        cmd_time_taken=" <1s"
    else
        integer seconds=$(($cmd_time_taken / 1000.0 + 0.5))

        integer hours=$(($seconds / 3600))
        integer seconds=$(($seconds % 3600))

        integer minutes=$(($seconds / 60))
        integer seconds=$(($seconds % 60))

        if [ $hours -ne 0 ]
        then
            cmd_time_taken=" ~$hours"h" $minutes"m" $seconds"s
        elif [ $minutes -ne 0 ]
        then
            cmd_time_taken=" ~$minutes"m" $seconds"s
        else
            cmd_time_taken=" ~$seconds"s
        fi
    fi


    cmd_time_begin=""
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
source_file_if_exists()
{
    [ -e $1 ] && source $1
}

source_git_plugin()
{ 
    ( which git > /dev/null ) || return

    plugin_name=$(echo $1 | cut -d "/" -f 2)
    if [ ! -d "$ZPLUGDIR/$plugin_name" ]
    then 
        git clone "$1" "$ZPLUGDIR/$plugin_name"
    fi

    source_file_if_exists "$ZPLUGDIR/$plugin_name/$plugin_name.plugin.zsh" || \
    source_file_if_exists "$ZPLUGDIR/$plugin_name/$plugin_name.zsh"
}

source_git_plugin "https://github.com/zsh-users/zsh-autosuggestions"
source_git_plugin "https://github.com/zsh-users/zsh-syntax-highlighting"

# BAT:
if ( which bat > /dev/null )
then 
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    alias cat="bat --pager=never"
fi



# BASIC NAV KEY BINDINGS:
bindkey "^[[1;5D" backward-word     # ctrl+left
bindkey "^[[1;5C" forward-word      # ctrl+right
bindkey "^[[H" beginning-of-line    # home
bindkey "^[[F" end-of-line          # end
bindkey "^[[3~" delete-char         # del
bindkey "^[[3;5~" delete-word       # ctrl+del
bindkey "^H" backward-delete-word   # ctrl+backspace


# ALIASES:
alias ls="ls --color=auto" \
      mv="mv -iv" \
      cp="cp -iv" \
      mkdir="mkdir -pv" \
      rm="rm -vI" \
      grep="grep --color=auto" \
      diff="diff --color=auto" 

if ( which exa > /dev/null ) 
then
    alias ll="exa -alhg --git --group-directories-first"
else
    alias ll="ls -alhs --group-directories-first"
fi



# RANGER/LF NAVIGATION:
if ( which lf > /dev/null )
then
    intcd()
    {
        tmp="$(mktemp)"
        trap 'rm -f $tmp >/dev/null 2>&1' HUP INT QUIT TERM PWR EXIT >/dev/null 2>&1
        lf -last-dir-path="$tmp"
        dir="$(cat "$tmp")"
        command rm -f $tmp
        [ -d $dir ] && [ "$dir" != "$(pwd)" ] && cd $dir
    }
elif ( which ranger > /dev/null )
then
    intcd()
    {
        tmp="$(mktemp)" 
        trap 'rm -f $tmp >/dev/null 2>&1' HUP INT QUIT TERM PWR EXIT >/dev/null 2>&1
        ranger --choosedir="$tmp"
        dir="$(cat "$tmp")"
        command rm -f $tmp
        [ -d $dir ] && [ "$dir" != "$(pwd)" ] && cd $dir
    }
fi

$( typeset -f intcd > /dev/null ) && bindkey -s "^o" "intcd\n" # ctrl+o


# DOLPHIN BIND:
if ( which dolphin > /dev/null )
then
    open_dolphin()
    {
        dolphin "$(pwd)" >/dev/null 2>&1 &
    }
    bindkey -s "^e" "open_dolphin\n" # ctrl+e
fi



# RARE RAINBOW NEOFETCH
if ( which neofetch > /dev/null ) && \
   ( which lolcat > /dev/null ) && \
   [ "$(($RANDOM%100))" -eq "1" ]
then
    alias neofetch="neofetch | lolcat"
fi


# OPTIONAL STARTUP SCRIPT
ext_script="$ZDOTDIR/.zshrc-ext"
if [ -e "$ext_script" ]
then
    $ext_script
fi