mkdir -p build

clang src/*.m $(gnustep-config --objc-flags) -I /usr/lib/gcc/x86_64-linux-gnu/14/include/ $(gnustep-config --base-libs) -lasound -lm -o build/rrzs