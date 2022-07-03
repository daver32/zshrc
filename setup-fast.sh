#!/bin/sh

help () {
	echo "Quick auto installer:"
    echo "  Puts a symlink to .zshrc in \"~/.config/.zshrc.\""
    echo "  Creates a \"~/.zshenv\" with appropriate variables."
    echo "  Creates the history file in the default location."
    echo "Example usage:"
    echo "  setup-fast.sh /path/to/cloned/repo"
	exit 0
}

[ "$#" -lt 1 ] && help

warn_if_not_found() {
    ( which $1 > /dev/null 2>&1 ) || echo "WARNING: $1 not found"
}

warn_if_not_found "zsh"
warn_if_not_found "git"

echoerr () { 
    printf "%s\n" "$*" >&2;
}

exit_err () {
    echoerr $1
    exit 1
}

full_path () {
  case "$1" in
    /*) printf '%s\n' "$1";;
    *) printf '%s\n' "$PWD/$1";;
  esac
}

repo_dir=$1
[ -z $repo_dir ] && exit_err "ERROR: First argument should be the repository directory"
repo_dir="$(full_path $1)" # full path needed for symlink

zshrc="$repo_dir/.zshrc"
[ -e "$zshrc" ] || exit_err "ERROR: $zshrc does not exist"

zdotdir="$HOME/.config/zsh"
[ -e $zdotdir ] && exit_err "ERROR: $zdotdir already exists"

zshenv="$HOME/.zshenv"
[ -e $zshenv ] && exit_err "ERROR: $zshenv already exists"

mkdir -p "$zdotdir"
ln -s "$zshrc" "$zdotdir/.zshrc" || exit 1
echo "export ZDOTDIR=\"$HOME/.config/zsh\"" >> $zshenv || exit 1
echo "export ZPLUGDIR=\"$zdotdir/plugins\"" >> $zshenv || exit 1
mkdir -p "$HOME/.local/share/zsh/" || exit 1
touch "$HOME/.local/share/zsh/.histfile" || exit 1

echo "Setup performed succesfully"


