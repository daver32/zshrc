bindkey -e

if [ -z "$ZDOTDIR" ]
then
    export ZDOTDIR=$HOME
fi

if [ -z "$ZPLUGDIR" ]
then
    export ZPLUGDIR=$ZDOTDIR/zsh-plugins
fi

# TAB COMPLETION:
autoload -Uz compinit
zstyle ':completion:*' menu select
compinit
_comp_options+=(globdots) # Include hidden files.



# PROMPT:
PROMPT="%F{39}%n%f%F{39}@%f%F{39}%m%f:%~$ "
RPROMPT="%h:%?"



# HISTORY:
HISTFILE=~/.local/share/zsh/.histfile
HISTSIZE=10000
SAVEHIST=10000



# SOURCE PLUGINS:
source-file-if-exists () {
    [ -e $1 ] && source $1
}

source-github-plugin () { 
    ( which git > /dev/null ) || return

    plugin_name=$(echo $1 | cut -d "/" -f 2)
    if [ ! -d "$ZPLUGDIR/$plugin_name" ]
    then 
        git clone "https://github.com/$1.git" "$ZPLUGDIR/$plugin_name"
    fi

    source-file-if-exists "$ZPLUGDIR/$plugin_name/$plugin_name.plugin.zsh" || \
    source-file-if-exists "$ZPLUGDIR/$plugin_name/$plugin_name.zsh"
}

source-github-plugin "zsh-users/zsh-autosuggestions"
source-github-plugin "zsh-users/zsh-syntax-highlighting"

# COLORFUL MANPAGES:
if ( which bat > /dev/null )
then 
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi



# BASIC NAV KEY BINDINGS:
bindkey "^[[1;5D" backward-word     # ctrl+left
bindkey "^[[1;5C" forward-word      # ctrl+right
bindkey "^[[H" beginning-of-line    # home
bindkey "^[[F" end-of-line          # end
bindkey "^[[3~" delete-char         # del
bindkey "^[[3;5~" delete-word       # ctrl+del
bindkey "\x7f" backward-delete-word # ctrl+backspace


# ALIASES:
alias ls="ls --color=auto" \
      ll="ls -alhs" \
      mv="mv -iv" \
      cp="cp -iv" \
      mkdir="mkdir -pv" \
      rm="rm -vI" \
      grep="grep --color=auto" \
      diff="diff --color=auto" 



# RANGER NAVIGATION:
# TODO make this more generic?
if ( which lf > /dev/null )
then
    lfcd () {
        tmp="$(mktemp)"
        trap 'rm -f $tmp >/dev/null 2>&1' HUP INT QUIT TERM PWR EXIT >/dev/null 2>&1
        lf -last-dir-path="$tmp"
        dir="$(cat "$tmp")"
        command rm -f $tmp
        [ -d $dir ] && [ "$dir" != "$(pwd)" ] && cd $dir
    }
    bindkey -s "^o" "lfcd\n" # ctrl+o
elif ( which ranger > /dev/null )
then
    rangercd () {
        tmp="$(mktemp)"
        trap 'rm -f $tmp >/dev/null 2>&1' HUP INT QUIT TERM PWR EXIT >/dev/null 2>&1
        ranger --choosedir="$tmp"
        dir="$(cat "$tmp")"
        command rm -f $tmp
        [ -d $dir ] && [ "$dir" != "$(pwd)" ] && cd $dir
    }
    bindkey -s "^o" "rangercd\n" # ctrl+o
fi


# DOLPHIN BIND:
if ( which dolphin > /dev/null )
then
    open-dolphin () {
        dolphin "$(pwd)" >/dev/null 2>&1 &
    }
    bindkey -s "^e" "open-dolphin\n" # ctrl+e
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