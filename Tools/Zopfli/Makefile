CC = gcc
CXX = g++

CFLAGS = -W -Wall -Wextra -ansi -pedantic -lm -O2 -Wno-unused-function 
CXXFLAGS = -W -Wall -Wextra -ansi -pedantic -O2

ZOPFLILIB_SRC = src/zopfli/blocksplitter.c src/zopfli/cache.c\
                src/zopfli/deflate.c src/zopfli/gzip_container.c\
                src/zopfli/hash.c src/zopfli/katajainen.c\
                src/zopfli/lz77.c src/zopfli/squeeze.c\
                src/zopfli/tree.c src/zopfli/util.c\
                src/zopfli/zlib_container.c
ZOPFLILIB_OBJ := $(patsubst src/zopfli/%.c,%.o,$(ZOPFLILIB_SRC))
ZOPFLIBIN_SRC := src/zopfli/zopfli_bin.c
LODEPNG_SRC := src/zopflipng/lodepng/lodepng.cpp src/zopflipng/lodepng/lodepng_util.cpp
ZOPFLIPNGLIB_SRC := src/zopflipng/zopflipng_lib.cc
ZOPFLIPNGBIN_SRC := src/zopflipng/zopflipng_bin.cc

ifeq ($(shell uname -m), x86_64)
  OUTPUTDIR = static/gcc64
else
  OUTPUTDIR = static/gcc32
endif

.PHONY: zopfli zopflipng

# Zopfli shared library
libzopfli:
	@cd $(OUTPUTDIR); $(CC) $(patsubst %,../../%,$(ZOPFLILIB_SRC)) $(CFLAGS) -fPIC -c -Walloc-size-larger-than=17179869180
#	$(CC) $(ZOPFLILIB_OBJ) $(CFLAGS) -shared -Wl,-soname,libzopfli.so.1 -o libzopfli.so.1.0.2 

# Zopfli binary
zopfli:
	$(CC) $(ZOPFLILIB_SRC) $(ZOPFLIBIN_SRC) $(CFLAGS) -o zopfli

# ZopfliPNG binary
zopflipng:
	$(CC) $(ZOPFLILIB_SRC) $(CFLAGS) -c
	$(CXX) $(ZOPFLILIB_OBJ) $(LODEPNG_SRC) $(ZOPFLIPNGLIB_SRC) $(ZOPFLIPNGBIN_SRC) $(CFLAGS) -o zopflipng

# ZopfliPNG shared library
libzopflipng:
	$(CC) $(ZOPFLILIB_SRC) $(CFLAGS) -fPIC -c
	$(CXX) $(ZOPFLILIB_OBJ) $(LODEPNG_SRC) $(ZOPFLIPNGLIB_SRC) $(CFLAGS) -fPIC --shared -Wl,-soname,libzopflipng.so.1 -o libzopflipng.so.1.0.2

# Remove all libraries and binaries
clean:
	rm -f zopflipng zopfli $(ZOPFLILIB_OBJ) libzopfli*
