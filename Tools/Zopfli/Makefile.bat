@ECHO OFF

ECHO ---------- Compile BCC ----------------------------------------------------

SET BCC_ZOPFLI_LIB_SRC=^
  src/zopfli/blocksplitter.c ^
  src/zopfli/cache.c ^
  src/zopfli/deflate.c ^
  src/zopfli/gzip_container.c ^
  src/zopfli/hash.c ^
  src/zopfli/katajainen.c ^
  src/zopfli/lz77.c ^
  src/zopfli/squeeze.c ^
  src/zopfli/tree.c ^
  src/zopfli/util.c ^
  src/zopfli/zlib_container.c

ECHO ---------- Compile BCC 32 -------------------------------------------------

SET BCC32=bcc32.exe
SET BCC32_OUTDIR=static\bcc32

REM  -w      Display all warnings
REM  -6      Generate Pentium Pro instructions
REM  -O2     Generate fastest possible code
REM  -d      Merge duplicate strings
REM  -mm     Ignore system header files while generating dependency info
REM  -c      Compile to object file only, do not link
REM  -n      Set output directory for object files

SET BCC32_FLAGS=-w -6 -O2 -d -mm -u -c -n%BCC32_OUTDIR%

"%BCC32%" %BCC32_FLAGS% %BCC_ZOPFLI_LIB_SRC%
REM Remove dependency info files *.d
DEL /F /Q %BCC32_OUTDIR%\*.d

ECHO ---------- Compile BCC 64 ----------------------------------------

SET BCC64=bcc64.exe
SET BCC64_OUTDIR=static\bcc64

REM  -mm     Ignore system header files while generating dependency info
REM          (add this option is you are using old non-LLVM compiler)

REM  -w      Display all warnings
REM  -O2     Generate fastest possible code
REM  -d      Merge duplicate strings
REM  -mm     Ignore system header files while generating dependency info
REM  -c      Compile to object file only, do not link
REM  -output-dir <directory> Write object files to <directory>

SET BCC64_FLAGS=-w -O2 -d -c -u- -output-dir %BCC64_OUTDIR%

"%BCC64%" %BCC64_FLAGS% %BCC_ZOPFLI_LIB_SRC%