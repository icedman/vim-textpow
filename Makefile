all: prebuild build install

.PHONY: prebuild build install

prebuild:
	git pull
	git submodule update --init

build:
	echo '...'

install:
	mkdir -p ~/.vim/ruby/vim-textpow
	cp -R ./*  ~/.vim/ruby/vim-textpow

uninstall:
	rm -R ~/.vim/ruby/vim-textpow

clean:
	echo '...'

