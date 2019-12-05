/// Wrapper over Zopfli compression
// Zopfli Compression Algorithm is a compression library programmed in C to
// perform very good, but slow, deflate or zlib compression:
//
// https://github.com/google/zopfli
//
// This library can only compress, not decompress. Existing zlib or deflate
// libraries can decompress the data.
unit Zopfli;

(*
  This file is a path of integration project between HTML5 Boilerplate and
  Synopse mORMot Framework.

    https://synopse.info
    https://html5boilerplate.com

  Boilerplate HTTP Server
  (c) 2016-Present Yevgeny Iliyn

  License: MIT

  https://github.com/eugeneilyin/mORMotBP

  Version 1.9
  - first release, associated with the MormotBP project
*)

interface

uses
  SysUtils;

type
  {$IFDEF FPC}
    {$IFDEF FPC_HAS_CPSTRING}
      // see http://wiki.freepascal.org/FPC_Unicode_support
      {$DEFINE HASCODEPAGE} // UNICODE means {$mode delphiunicode}
    {$ENDIF}
  {$ELSE FPC}
    {$IFDEF UNICODE}
      {$DEFINE HASCODEPAGE}
    {$ENDIF}
  {$ENDIF FPC}
  EncodedString = {$IFDEF HASCODEPAGE}RawByteString{$ELSE}AnsiString{$ENDIF};

  /// Zopfli output data format:
  //   zfGZip
  //     creates a valid deflate stream in memory, see:
  //     http://www.ietf.org/rfc/rfc1951.txt
  //   zfZLib
  //     creates a valid zlib stream in memory, see:
  //     http://www.ietf.org/rfc/rfc1950.txt
  //   zfDeflate
  //     creates a valid gzip stream in memory, see:
  //     http://www.ietf.org/rfc/rfc1952.txt
  TZopfliFormat = (zfGZip, zfZLib, zfDeflate);

  /// Exception raised internaly in case of Zopfli errors
  EZopfliException = class(Exception);

/// Compress Data using the Zopfli algorithm
// - Data
//     Data to compress
// - Encoded
//     Compressed data
// - DstFormat
//     Output data format. See TZopfliFormat
// - NumIterations
//     Maximum amount of times to rerun forward and backward pass to optimize
//     LZ77 compression cost. Good values: 10, 15 for small files, 5 for files
//     over severa l MB in size or it will be too slow.
// - BlockSplittingMax
//     Maximum amount of blocks to split into (0 for unlimited, but this can
//     give extreme results that hurt compression on some files).
//     Default value: 15.
// - Returns TRUE on successful compression, or FALSE otherwise
function ZopfliCompress(const Data: EncodedString; out Encoded: EncodedString;
  const Format: TZopfliFormat = zfGZip; const NumIterations: Integer = 15;
  const BlockSplittingMax: Integer = 15): Boolean;

implementation

{$IFDEF MSWINDOWS}
  {$IFDEF CPU386}
    {$DEFINE WITH_UNDERSCORE}
    {$L static\bcc32\blocksplitter.obj}
    {$L static\bcc32\cache.obj}
    {$L static\bcc32\deflate.obj}
    {$L static\bcc32\gzip_container.obj}
    {$L static\bcc32\hash.obj}
    {$L static\bcc32\katajainen.obj}
    {$L static\bcc32\lz77.obj}
    {$L static\bcc32\squeeze.obj}
    {$L static\bcc32\tree.obj}
    {$L static\bcc32\util.obj}
    {$L static\bcc32\zlib_container.obj}
  {$ELSE CPU386}
    {$L static\bcc64\blocksplitter.o}
    {$L static\bcc64\cache.o}
    {$L static\bcc64\deflate.o}
    {$L static\bcc64\gzip_container.o}
    {$L static\bcc64\hash.o}
    {$L static\bcc64\katajainen.o}
    {$L static\bcc64\lz77.o}
    {$L static\bcc64\squeeze.o}
    {$L static\bcc64\tree.o}
    {$L static\bcc64\util.o}
    {$L static\bcc64\zlib_container.o}
  {$ENDIF CPU386}
{$ENDIF MSWINDOWS}  
{$IFDEF LINUX}
  {$IFDEF CPU386}
    {$L static/gcc32/blocksplitter.o}
    {$L static/gcc32/cache.o}
    {$L static/gcc32/deflate.o}
    {$L static/gcc32/gzip_container.o}
    {$L static/gcc32/hash.o}
    {$L static/gcc32/katajainen.o}
    {$L static/gcc32/lz77.o}
    {$L static/gcc32/squeeze.o}
    {$L static/gcc32/tree.o}
    {$L static/gcc32/util.o}
    {$L static/gcc32/zlib_container.o}
  {$ELSE CPU386}
    {$L static/gcc64/blocksplitter.o}
    {$L static/gcc64/cache.o}
    {$L static/gcc64/deflate.o}
    {$L static/gcc64/gzip_container.o}
    {$L static/gcc64/hash.o}
    {$L static/gcc64/katajainen.o}
    {$L static/gcc64/lz77.o}
    {$L static/gcc64/squeeze.o}
    {$L static/gcc64/tree.o}
    {$L static/gcc64/util.o}
    {$L static/gcc64/zlib_container.o}
  {$ENDIF CPU386}
{$ENDIF LINUX}

type
  TZopfliSize = {$IFDEF CPU386} Integer {$ELSE} Int64 {$ENDIF};

  EZopfliExitException = class(EZopfliException)
    Status: Integer;
  end;

  TZopfliOptions = record
    /// Whether to print output
    Verbose: Integer;

    /// Whether to print more detailed output
    VerboseMore: Integer;

    /// Maximum amount of times to rerun forward and backward pass to optimize
    // LZ77 compression cost. Good values: 10, 15 for small files, 5 for files
    // over several MB in size or it will be too slow.
    NumIterations: Integer;

    /// If true, splits the data in multiple deflate blocks with optimal choice
    // for the block boundaries. Block splitting gives better compression.
    // Default: true (1).
    BlockSplitting: Integer;

    /// No longer used, left for compatibility.
    BlockSplittingLast: Integer;

    /// Maximum amount of blocks to split into (0 for unlimited, but this can
    // give extreme results that hurt compression on some files).
    // Default value: 15.
    BlockSplittingMax: Integer;
  end;
  PZopfliOptions = ^TZopfliOptions;

{$IFDEF WITH_UNDERSCORE}
procedure _ZopfliInitOptions(out Options: TZopfliOptions); cdecl; external;
procedure _ZopfliGzipCompress(const Options: PZopfliOptions;
  const InData: Pointer; const InSize: TZopfliSize; out OutData: Pointer;
  out OutSize: TZopfliSize); cdecl; external;
procedure _ZopfliZlibCompress(const Options: PZopfliOptions;
  const InData: Pointer; const InSize: TZopfliSize; out OutData: Pointer;
  out OutSize: TZopfliSize); cdecl; external;
procedure _ZopfliDeflate(const Options: PZopfliOptions; const BType: Integer;
  const Final: Integer; const InData: Pointer; const InSize: TZopfliSize;
  const Bp: PAnsiChar; out OutData: Pointer; out OutSize: TZopfliSize);
    cdecl; external;
procedure _ZopfliBlockSplit; cdecl; external;
procedure _ZopfliBlockSplitLZ77; cdecl; external;
procedure _ZopfliInitCache; cdecl; external;
procedure _ZopfliCleanCache; cdecl; external;
procedure _ZopfliMaxCachedSublen; cdecl; external;
procedure _ZopfliCacheToSublen; cdecl; external;
procedure _ZopfliSublenToCache; cdecl; external;
procedure _ZopfliResetHash; cdecl; external;
procedure _ZopfliWarmupHash; cdecl; external;
procedure _ZopfliUpdateHash; cdecl; external;
procedure _ZopfliFindLongestMatch; cdecl; external;
procedure _ZopfliVerifyLenDist; cdecl; external;
procedure _ZopfliStoreLitLenDist; cdecl; external;
procedure _ZopfliCalculateBlockSize; cdecl; external;
procedure _ZopfliCopyLZ77Store; cdecl; external;
procedure _ZopfliLengthLimitedCodeLengths; cdecl; external;
{$ELSE}
procedure ZopfliInitOptions(out Options: TZopfliOptions); cdecl; external;
procedure ZopfliGzipCompress(const Options: PZopfliOptions;
  const InData: Pointer; const InSize: TZopfliSize; out OutData: Pointer;
  out OutSize: TZopfliSize); cdecl; external;
procedure ZopfliZlibCompress(const Options: PZopfliOptions;
  const InData: Pointer; const InSize: TZopfliSize; out OutData: Pointer;
  out OutSize: TZopfliSize); cdecl; external;
procedure ZopfliDeflate(const Options: PZopfliOptions; const BType: Integer;
  const Final: Integer; const InData: Pointer; const InSize: TZopfliSize;
  const Bp: PAnsiChar; out OutData: Pointer; out OutSize: TZopfliSize);
    cdecl; external;
procedure ZopfliBlockSplit; cdecl; external;
procedure ZopfliBlockSplitLZ77; cdecl; external;
procedure ZopfliInitCache; cdecl; external;
procedure ZopfliCleanCache; cdecl; external;
procedure ZopfliMaxCachedSublen; cdecl; external;
procedure ZopfliCacheToSublen; cdecl; external;
procedure ZopfliSublenToCache; cdecl; external;
procedure ZopfliResetHash; cdecl; external;
procedure ZopfliWarmupHash; cdecl; external;
procedure ZopfliUpdateHash; cdecl; external;
procedure ZopfliFindLongestMatch; cdecl; external;
procedure ZopfliVerifyLenDist; cdecl; external;
procedure ZopfliStoreLitLenDist; cdecl; external;
procedure ZopfliCalculateBlockSize; cdecl; external;
procedure ZopfliCopyLZ77Store; cdecl; external;
procedure ZopfliLengthLimitedCodeLengths; cdecl; external;
{$ENDIF}

const
  InitOptions: procedure(out Options: TZopfliOptions); cdecl =
    {$IFDEF WITH_UNDERSCORE}
      _ZopfliInitOptions
    {$ELSE}
      ZopfliInitOptions
    {$ENDIF};

  GzipCompress: procedure(const Options: PZopfliOptions; const InData: Pointer;
    const InSize: TZopfliSize; out OutData: Pointer; out OutSize: TZopfliSize);
      cdecl =
      {$IFDEF WITH_UNDERSCORE}
        _ZopfliGzipCompress
      {$ELSE}
        ZopfliGzipCompress
      {$ENDIF};

  ZlibCompress: procedure(const Options: PZopfliOptions; const InData: Pointer;
    const InSize: TZopfliSize; out OutData: Pointer; out OutSize: TZopfliSize);
      cdecl =
      {$IFDEF WITH_UNDERSCORE}
        _ZopfliZlibCompress
      {$ELSE}
        ZopfliZlibCompress
      {$ENDIF};

  Deflate: procedure(const Options: PZopfliOptions; const BType: Integer;
    const Final: Integer; const InData: Pointer; const InSize: TZopfliSize;
    const Bp: PAnsiChar; out OutData: Pointer; out OutSize: TZopfliSize);
      cdecl =
      {$IFDEF WITH_UNDERSCORE}
        _ZopfliDeflate
      {$ELSE}
        ZopfliDeflate
      {$ENDIF};

function ZopfliCompress(const Data: EncodedString; out Encoded: EncodedString;
  const Format: TZopfliFormat = zfGZip; const NumIterations: Integer = 15;
  const BlockSplittingMax: Integer = 15): Boolean;
const
  EMPTY_GZIP: array[0..19] of Byte =
    ($1F, $8B, $08, $00, $00, $00, $00, $00,
     $00, $00, $03, $00, $00, $00, $00, $00,
     $00, $00, $00, $00);

  EMPTY_DEFLATE: array[0..1] of Byte =
    ($03, $00);

  EMPTY_ZLIB: array[0..7] of Byte =
    ($78, $DA, $03, $00, $00, $00, $00, $01);
var
  Options: TZopfliOptions;
  OutData: Pointer;
  OutSize: TZopfliSize;
  Bp: Char;
begin
  if Data = '' then
  begin
    case Format of
      zfGZip:
        SetString(Encoded, PAnsiChar(@EMPTY_GZIP[0]), Length(EMPTY_GZIP));

      zfZLib:
        SetString(Encoded, PAnsiChar(@EMPTY_ZLIB[0]), Length(EMPTY_ZLIB));

      zfDeflate:
        SetString(Encoded, PAnsiChar(@EMPTY_DEFLATE[0]), Length(EMPTY_DEFLATE));
    end;
    Result := True;
    Exit;
  end;

  OutSize := 0;
  OutData := nil;
  {$IFNDEF FPC}
  try
  {$ENDIF}
    try
      InitOptions(Options);
      Options.NumIterations := NumIterations;
      Options.BlockSplittingMax := BlockSplittingMax;

      case Format of
        zfGZip:
          GZipCompress(@Options, Pointer(Data), Length(Data), OutData, OutSize);

        zfZLib:
          ZLibCompress(@Options, Pointer(Data), Length(Data), OutData, OutSize);

        zfDeflate:
          begin
            Bp := #0;
            Deflate(@Options, 2 { Dynamic block }, Integer(True),
              Pointer(Data), Length(Data), @Bp, OutData, OutSize);
          end;
      end;
      SetString(Encoded, PAnsiChar(OutData), OutSize);
      Result := True;
    except
      on EZopfliException do
        Result := False;
    end;
  {$IFNDEF FPC}
  finally
    FreeMem(OutData);
  end;
  {$ENDIF}
end;

{$IFNDEF FPC}
{$IFDEF WITH_UNDERSCORE}
procedure __exit(Status: Integer); cdecl; export;
{$ELSE}
procedure _exit(Status: Integer); cdecl; export;
{$ENDIF}
var
  E: EZopfliExitException;
begin
  E := EZopfliExitException.CreateFmt('Zopfli exit: Status=%d', [Status]);
  E.Status := Status;
  raise E;
end;

// See https://github.com/caodj/dSqlite3/blob/master/src/sqlite3/MSVCRT.pas

{$IFDEF WITH_UNDERSCORE}
function _malloc(Size: Cardinal): Pointer; cdecl;
{$ELSE}
function malloc(Size: Cardinal): Pointer; cdecl;
{$ENDIF}
begin
  GetMem(Result, Size);
end;

{$IFDEF WITH_UNDERSCORE}
procedure _free(P: Pointer); cdecl;
{$ELSE}
procedure free(P: Pointer); cdecl;
{$ENDIF}
begin
  FreeMem(P);
end;

{$IFDEF WITH_UNDERSCORE}
function _realloc(P: Pointer; Size: Integer): Pointer; cdecl;
{$ELSE}
function realloc(P: Pointer; Size: Integer): Pointer; cdecl;
{$ENDIF}
begin
  Result := P;
  ReallocMem(Result, Size);
end;

{$IFDEF WITH_UNDERSCORE}
function _memset(P: Pointer; B: Integer; Count: Integer): Pointer; cdecl;
{$ELSE}
function memset(P: Pointer; B: Integer; Count: Integer): Pointer; cdecl;
{$ENDIF}
// a fast full pascal version of the standard C library function
begin
  FillChar(P^, Count, B);
  Result := P;
end;

{$IFDEF WITH_UNDERSCORE}
function _memcpy(Dest, Source: Pointer; Count: Integer): Pointer; cdecl;
{$ELSE}
function memcpy(Dest, Source: Pointer; Count: Integer): Pointer; cdecl;
{$ENDIF}
begin
  Move(Source^, Dest^, Count);
  Result := Dest;
end;

{$IFDEF WITH_UNDERSCORE}
function _fprintf(Stream: Pointer; const Format: PChar): Integer; cdecl;
{$ELSE}
function fprintf(Stream: Pointer; const Format: PChar): Integer; cdecl;
{$ENDIF}
begin
  Result := 0;
end;

{$IFDEF WITH_UNDERSCORE}
procedure __assert(const Test: Boolean); cdecl;
{$ELSE}
procedure _assert(const Test: Boolean); cdecl;
{$ENDIF}
begin
  Assert(Test);
end;

type
  // qsort() is used if SQLITE_ENABLE_FTS3 is defined
  // this function type is defined for calling termDataCmp() in sqlite3.c
  // The _qsort is taken from
  //   https://github.com/synopse/mORMot/blob/master/SynSQLite3Static.pas
  qsort_compare_func = function(P1, P2: Pointer): Integer; cdecl;

procedure QuickSort4(Base: PPointerArray; L, R: Integer;
  ComparF: qsort_compare_func);
var I, J, P: Integer;
    PP, C: PAnsiChar;
begin
  repeat // from SQLite (FTS), With=sizeof(PAnsiChar) AFAIK
    I := L;
    J := R;
    P := (L+R) shr 1;
    repeat
      PP := @base[P];
      while comparF(@base[I],PP)<0 do
        inc(I);
      while comparF(@base[J],PP)>0 do
        dec(J);
      if I<=J then begin
        C := base[I];
        base[I] := base[J];
        base[J] := C; // fast memory exchange
        if P=I then P := J else if P=J then P := I;
        inc(I);
        dec(J);
      end;
    until I>J;
    if L<J then
      QuickSort4(base, L, J, comparF);
    L := I;
  until I>=R;
end;

procedure QuickSort(BaseP: PAnsiChar; Width: Integer; L, R: Integer;
  ComparF: qsort_compare_func);
// code below is very fast and optimized
  procedure Exchg(P1,P2: PAnsiChar; Size: integer);
  var B: AnsiChar;
      i: integer;
  begin
    for i := 0 to Size-1 do begin
      B := P1[i];
      P1[i] := P2[i];
      P2[i] := B;
    end;
  end;
var I, J, P: Integer;
    PP, C: PAnsiChar;
begin
  repeat // generic sorting algorithm
    I := L;
    J := R;
    P := (L+R) shr 1;
    repeat
      PP := baseP+P*Width; // compute PP at every loop, since P may change
      C := baseP+I*Width;
      while comparF(C,PP)<0 do begin
        inc(I);
        inc(C,width); // avoid slower multiplication in loop
      end;
      C := baseP+J*Width;
      while comparF(C,PP)>0 do begin
        dec(J);
        dec(C,width); // avoid slower multiplication in loop
      end;
      if I<=J then begin
        Exchg(baseP+I*Width,baseP+J*Width,Width); // fast memory exchange
        if P=I then P := J else if P=J then P := I;
        inc(I);
        dec(J);
      end;
    until I>J;
    if L<J then
      QuickSort(baseP, Width, L, J, comparF);
    L := I;
  until I>=R;
end;

{$IFDEF WITH_UNDERSCORE}
procedure _qsort(BaseP: Pointer; NElem, Width: Integer;
  ComparF: pointer); cdecl;
{$ELSE}
procedure qsort(BaseP: Pointer; NElem, Width: Integer;
  ComparF: pointer); cdecl;
{$ENDIF}
// a fast full pascal version of the standard C library function
begin
  if (Cardinal(NElem) > 1) and (Width > 0) then
    if Width = SizeOf(Pointer) then
      QuickSort4(BaseP, 0, NElem - 1, qsort_compare_func(ComparF))
    else
      QuickSort(BaseP, Width, 0, NElem - 1, qsort_compare_func(ComparF));
end;

{$IFDEF WIN32}
function __ftol: Int64; cdecl;
// Borland C++ float to integer (Int64) conversion
asm
  jmp System.@Trunc  // FST(0) -> EDX:EAX, as expected by BCC32 compiler
end;
{$ENDIF}

{$IFDEF WIN64}
function fwrite(Ptr: Pointer; const size, nelem: TZopfliSize;
  stream: Pointer): TZopfliSize; cdecl;
begin
  Result := 0;
end;

/// Allocate temporary stack memory
//
// __chkstk is a helper function for the compiler. It is called in the prologue
// to a function that has more than 4K bytes of local variables. It performs a
// stack probe by poking all pages in the new stack area. The number of bytes
// that will be allocated is passed in RAX.
//
// See: $(BDS)\source\cpprtl\Source\memory\chkstk.nasm
procedure __chkstk; cdecl;
asm
  lea r10, [rsp]
  mov r11, r10
  sub r11, rax
  and r11w, 0f000h
  and r10w, 0f000h
@loop1:
  sub r10, 01000h
  cmp r10, r11 // more to go?
  jl @exit
  mov qword [r10], 0 // probe this page
  jmp @loop1
@exit:
end;
{$ENDIF WIN64}

{$IFDEF MSWINDOWS}
{$IFDEF WIN32}
function _zopfliLog(const Val: Double): Double; cdecl;
asm
  fld qword ptr Val
  fldln2
  fxch
  fyl2x
end;
{$ENDIF WIN32}
{$IFDEF WIN64}
function _zopfliLog(X: Double): Double; cdecl;
begin
  Result := Ln(x);
end;
function zopfliLog(X: Double): Double; cdecl;
begin
  Result := Ln(x);
end;
{$ENDIF WIN64}
{$ENDIF MSWINDOWS}
{$ELSE FPC}
// FPC expects .o linking, and only one version including FTS
function zopfliLog(X: Double): Double; cdecl; export;
begin
  Result := Ln(x);
end;
{$ENDIF FPC}

{$IFNDEF FPC}
{$IFDEF WIN32}
const
  __streams: Pointer = nil; { not used, but must be present for linking }
var
  __turboFloat: Word; { not used, but must be present for linking }
{$ENDIF}
{$IFDEF WIN64}
const
  _streams: Pointer = nil; { not used, but must be present for linking }
var
  _fltused: Cardinal = 0; { not used, but must be present for linking with
                            old non-LLVM bcc64.exe compiler }
{$ENDIF}
{$ENDIF}

end.
