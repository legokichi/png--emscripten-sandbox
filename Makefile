INCLUDE := -I./include $(shell pkg-config libpng --cflags) $(shell pkg-config libpng --libs) $(shell pkg-config zlib --cflags) $(shell pkg-config zlib --libs)
CFLAGS := -Wall -O0
CC := gcc -std=c++14
LD := gcc
LDFLAGS =
ODIR := ./obj
SDIR := ./src
DIST := ./bin
SRCS := $(wildcard ./src/*.cpp)
OBJS := $(SRCS:./src/%.cpp=./obj/%.o)
TARGET := $(DIST)/a
SUFFIX := .out

.PHONY: all clean wasm asmjs emconf

all: asmjs

wasm: CFLAGS := -Wall -Demscripten=true -Dstandalone=true
wasm: LDFLAGS += -s BINARYEN=1 -s "BINARYEN_METHOD='interpret-binary'"# -s "BINARYEN_SCRIPTS='spidermonkify.py'"
wasm: LDFLAGS += -s EXPORTED_FUNCTIONS="['png_sig_cmp', 'png_create_read_struct', 'png_create_info_struct', 'png_destroy_read_struct', 'png_jmpbuf', 'png_init_io', 'png_set_sig_bytes', 'png_read_info', 'png_get_IHDR', 'png_get_rowbytes', 'png_read_image', 'png_read_end', 'png_destroy_read_struct']"
wasm: SUFFIX := .wasm
wasm: emconf

asmjs: CFLAGS := -Wall -Demscripten=true
asmjs: LDFLAGS += -s EXPORTED_FUNCTIONS="['_main']"
#asmjs: LDFLAGS += --pre-js ./src/em-pre.js --post-js ./src/em-post.js
asmjs: SUFFIX := .js
asmjs: emconf

emconf: CC := emcc -std=c++14
#emconf: CFLAGS += -O1 --llvm-opts 0
emconf: INCLUDE := -I./include -I./zlib-1.2.8 -I./libpng-1.2.56 -I./png++-0.2.9
emconf: LD := emcc
#emconf: LDFLAGS += -O1 --llvm-lto 0
emconf: LDFLAGS += -s EXCEPTION_DEBUG=1 -s ASSERTIONS=1
#emconf: LDFLAGS += -shared --memory-init-file 0 -s ALLOW_MEMORY_GROWTH=1 -O3 -g3 --js-opts 1 --closure 2
emconf: LDFLAGS += ./zlib-1.2.8/libz.bc ./libpng-1.2.56/.libs/libpng.3.bc
emconf: $(TARGET)

$(TARGET): $(OBJS)
	if [ ! -d $(DIST) ]; then mkdir $(DIST); fi
	$(LD) -o $@$(SUFFIX) $(INCLUDE) $(LDFLAGS) $^

$(ODIR)/%.o: $(SDIR)/%.cpp
	if [ ! -d $(ODIR) ]; then mkdir $(ODIR); fi
	$(CC) -o $@ $(CFLAGS) $(INCLUDE) -c $<

clean:
	rm -rf $(ODIR)/* $(DIST)/*
