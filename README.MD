**ZSHRC**  
My simple zshrc with a github plugin downloader and other custom stuff. 

**Important variables**  

`ZDOTDIR` - where the `.zshrc` and the optional `.zshrc-ext` are located. Defaults to `$HOME`.  
`ZPLUGDIR` - where the plugins cloned from github will be located. Defaults to `$ZDOTDIR/zsh-plugins`.

Variables can be defined in `.zprofile` in the home directory. Example:
```sh
export ZDOTDIR=$HOME/.config/zsh
export ZPLUGDIR=$ZDOTDIR/plugins
```

**Optional startup script**  
In the end, `$ZDOTDIR/.zshrc-ext` will be ran if it exists.
