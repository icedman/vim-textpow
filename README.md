# vim-textpow

A textmate-based syntax highlighter for vim, compatible with VScode grammars.

# requires

Ruby enabled vim, version > 1.9

# install

```sh
git clone http://github.com/icedman/vim-textpow
cd vim-textpow
make
```

# install via vim-plug

```sh
Plug 'icedman/vim-textpow'
```

*.vimrc*

```sh
rubyfile ~/.vim/ruby/vim-textpow/vim-textpow.lua
```

or, as the case may be:

```sh
rubyfile ~/.vim/plugged/vim-textpow/vim-textpow.lua
```

# grammars

Copy grammar packages from vscode to the following directories:

```sh
~/.vim/ruby/vim-textpow/extensions/
~/.vim/plugged/vim-textpow/extensions/
```

# warning

* This plugin is just a proof of concept - from a novice Riby coder, and much worse - from a novice vim user
