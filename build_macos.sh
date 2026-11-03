mkdir -p build

clang src/*.m -fobjc-arc -framework Foundation -lasound -lm -o build/rrzs