rm -rf build
mkdir build

odin run src -out:build/aoc -debug -- $1