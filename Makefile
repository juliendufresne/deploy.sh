
all: compile

clean:
	[ -d compiled ] && rm --recursive --interactive=never compiled || true

compile: compiled/deploy

compiled/deploy:
	mkdir --parents compiled
	gawk -f "lib/compiler.gawk" -- --addpath "source" --shell "/usr/bin/env bash" -O -o compiled/deploy source/main.sh
	chmod +x compiled/deploy

.PHONY: clean compile
