
# using png++ with emscripten

```
$ emcc --version
emcc (Emscripten gcc/clang-like replacement) 1.36.1 (commit 21f554eacbd56a631078e3d8fa897f3ae93726d1)
Copyright (C) 2014 the Emscripten authors (see AUTHORS.txt)
This is free and open source software under the MIT license.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

```
$ clang --version
clang version 3.9.0 (https://github.com/kripken/emscripten-fastcomp-clang/ f0f1c872f23de144e76b666e83906c9f377426bd) (https://github.com/kripken/emscripten-fastcomp/ 52c59312c1715ad0c0accc2db0205e0b2d459609) (emscripten 1.36.1 : 1.36.1)
Target: x86_64-apple-darwin15.4.0
Thread model: posix
InstalledDir: /Users/***/emsdk_portable/clang/fastcomp/build_incoming_64/bin
```

## zlib

```
wget http://zlib.net/zlib-1.2.8.tar.gz
tar zxvf zlib-1.2.8.tar.gz
cd zlib-1.2.8
emconfigure ./configure
sed -i -e "s/^AR=.*$/AR=emcc/" Makefile
sed -i -e "s/libz\.a/libz.bc/" Makefile
emmake make
ls -l|grep libz.bc
```

emcc は `.a` 拡張子で llvm bitcode を出力するのを許さないので `.bc` に変更する

`libtool` では llvm bitcode をリンクできないので `emcc` に書き換える

これで `libz.bc` ができた

## libpng

```
wget http://downloads.sourceforge.net/project/libpng/libpng12/1.2.56/libpng-1.2.56.tar.gz
tar zxvf libpng-1.2.56.tar.gz
cd libpng-1.2.56
sed -i -e "s/ac_cv_lib_z_zlibVersion=no/ac_cv_lib_z_zlibVersion=yes/" ./configure
sed -i -e 's/LIBS=\"\-lz \$LIBS\"/LIBS="-I..\/zlib-1.2.8 $LIBS"/' ./configure
emconfigure ./configure
sed -i -e 's/^DEFAULT_INCLUDES = -I.$/DEFAULT_INCLUDES = -I. -I..\/zlib-1.2.8/' Makefile
emmake make
emcc -static -fno-common -DPIC  .libs/libpng_la-png.o .libs/libpng_la-pngset.o .libs/libpng_la-pngget.o .libs/libpng_la-pngrutil.o .libs/libpng_la-pngtrans.o .libs/libpng_la-pngwutil.o .libs/libpng_la-pngread.o .libs/libpng_la-pngrio.o .libs/libpng_la-pngwio.o .libs/libpng_la-pngwrite.o .libs/libpng_la-pngrtran.o .libs/libpng_la-pngwtran.o .libs/libpng_la-pngmem.o .libs/libpng_la-pngerror.o .libs/libpng_la-pngpread.o -L../zlib-1.2.8/  -lc    -Wl,-soname -Wl,libpng.3.bc -o .libs/libpng.3.bc
```

`configure` と `Makefile` を書き換えて zlib の場所を指定する

`emmake make` では共有ライブラリしか作れないので、改めてスタティックライブラリを作る

これで `.libs/libpng.3.bc` ができる

## png++

```
wget http://download.savannah.gnu.org/releases/pngpp/png++-0.2.9.tar.gz
tar zxvf png++-0.2.9.tar.gz
cd png++-0.2.9
sed -i -e "1s/^/#define __GLIBC__ 1/" ./config.hpp
sed -i -e "1s/^/#define __STDC_LIB_EXT1__ 1/" ./error.hpp
sed -i -e "s/strerror_s(buf, ERRBUF_SIZE, errnum);/strerror_r(errnum, buf, ERRBUF_SIZE);/" ./error.hpp
```

png++ の実態はヘッダファイルの集まりなのでコンパイルはしない

emcc 環境ではなんか `error.hpp` が

```
In file included from ./png++-0.2.9/png.hpp:36:
./png++-0.2.9/config.hpp:63:2: error: Byte-order could not be detected.
#error Byte-order could not be detected.
 ^
In file included from src/main.cpp:35:
In file included from ./png++-0.2.9/png.hpp:38:
./png++-0.2.9/error.hpp:108:20: error: no matching conversion for
      functional-style cast from 'int' to 'std::string' (aka
      'basic_string<char, char_traits<char>, allocator<char> >')
            return std::string(strerror_r(errnum, buf, ERRBUF_SIZE));
```

みたいなエラーを吐くので、
動くようになるまで sed する

## usage

png++ の `example/pixel_generator.cpp` を動かしてみる

```
cp png++-0.2.9/example/pixel_generator.cpp src/main.cpp
```

compile & link

```
emcc -std=c++14 -o obj/main.o -I./zlib-1.2.8 -I./libpng-1.2.56 -I./png++-0.2.9 -c src/main.cpp
emcc -o bin/a.js -I./zlib-1.2.8 -I./libpng-1.2.56 -I./png++-0.2.9  ./zlib-1.2.8/libz.bc ./libpng-1.2.56/.libs/libpng.3.bc obj/main.o
open index.html
```
