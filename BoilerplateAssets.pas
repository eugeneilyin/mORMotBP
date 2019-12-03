/// HTML5 Boilerplate integration with Synopse mORMot Framework
// Licensed under The MIT License (MIT)
unit BoilerplateAssets;

(*
  This unit is a path of integration project between HTML5 Boilerplate and
  Synopse mORMot Framework.

    https://synopse.info
    https://html5boilerplate.com

  Boilerplate HTTP Server
  (c) 2016-Present Yevgeny Iliyn

  License: MIT

  https://github.com/eugeneilyin/mORMotBP

  Version 1.0
  - First public release

  Version 1.7
  - get rid of system PosEx for better compatibility with Delphi 2007 and below

  Version 2.0
  - Zopfli compression support
    (save up to 5-15% compared to max GZip Level)
  - Brotli compression support as per RFC 7932
    (save another 15%-25% compared to Zopfli)
  - Embed all compressed encoding into Asset
  - New COMPRESSED_TYPES_CSV list to has compressed versions only for
    specific MIME types
  - Assets now saved in 'identity/*', 'gzip/*.gz', and 'brotli/*.br' directories
  - Updated assetslz tool
  - Free Pascal support
  - All Delphi compilers support started from Delphi 6
  - Kylix 3 support (over CrossKilyx)

  Version 2.1.1
  - Fix TAsset.SaveIdentityToFile bug when Root is empty

  Version 2.2
  - Content types normalization
*)

interface

{$I Synopse.inc} // define HASINLINE USETYPEINFO CPU32 CPU64 OWNNORMTOUPPER

uses
  SysUtils,
  SynCommons;

type

{TAsset }

  TFileCheck = (fcModified, fcSize);
  TFileChecks = set of TFileCheck;

  TAssetEncoding = (aeIdentity, aeGZip, aeBrotli);

  {$IFDEF FPC} {$PACKRECORDS 1} {$ELSE} {$A-} {$ENDIF}
  TAsset = {$IFDEF FPC_OR_UNICODE}record{$ELSE}object{$ENDIF}
  public
    Path: RawUTF8;
    Modified: TDateTime;
    ContentType: RawUTF8;
    Content: RawByteString;
    Hash: Cardinal;
    // We cann't use array[TAssetEncoding] here due to TDynArrayHashed.SaveTo
    // limitations in old Delphi compilers: Delphi 2009 and below. That's why
    // the TAsset structure without nested arrays.
    GZipExists: Boolean;
    GZipEncoding: RawByteString;
    GZipHash: Cardinal;
    BrotliExists: Boolean;
    BrotliEncoding: RawByteString;
    BrotliHash: Cardinal;
    function LoadFromFile(const Root, FileName: TFileName): Boolean;
    procedure SetEncoding(const Encoded: RawByteString;
      const Encoding: TAssetEncoding = aeIdentity);
    function SaveToFile(const Root: TFileName = '';
      const Encoding: TAssetEncoding = aeIdentity;
      const ChecksNotModified: TFileChecks = [fcModified, fcSize]): TFileName;
    function SaveIdentityToFile(const Root: TFileName = '';
      const ChecksNotModified: TFileChecks = [fcModified, fcSize]): TFileName;
  end;
  PAsset = ^TAsset;

  TAssetDynArray = array of TAsset;

{ TAssets }

type
  TAssets = {$IFDEF FPC_OR_UNICODE}record private{$ELSE}object protected{$ENDIF}
    FAssetsDAH: TDynArrayHashed;
  public
    Assets: TAssetDynArray;
    Count: Integer;
    procedure Init;
    function Add(const Root, FileName: TFileName): PAsset;
    procedure SaveToFile(const FileName: TFileName);
    procedure LoadFromFile(const FileName: TFileName);
    procedure LoadFromResource(const ResName: string);
    procedure SaveAll(const Root: TFileName = '';
      const ChecksNotModified: TFileChecks = [fcModified, fcSize]);
    procedure SaveAllIdentities(const Root: TFileName = '';
      const ChecksNotModified: TFileChecks = [fcModified, fcSize]);
    function Find(const Path: RawUTF8): PAsset;
      {$IFDEF HASINLINE}inline;{$ENDIF}
  end;

const
  /// Default asset extenstions used for GZip/Zopfli and Brotli compression
  COMPRESSED_TYPES_CSV = 'html,css,js,json,svg,' +
    'atom,mjs,map,topojson,jsonld,webmanifest,rdf,rss,geojson,eot,ttf,ttc,' +
    'wasm,webapp,xml,otf,bmp,cur,ico,appcache,ics,markdown,md,vcard,vcf,' +
    'xloc,vtt,htc';

  MIME_CONTENT_TYPES =

//  HyperText Markup Language

    '.html=text/html' + #10 +

//  Cascading Style Sheets

    '.css=text/css' + #10 +

//  JavaScript
//  Servers should use text/javascript for JavaScript resources.
//  https://html.spec.whatwg.org/multipage/scripting.html#scriptingLanguages

    '.js=text/javascript'#10 +
    '.mjs=text/javascript'#10 +

//  Text

    '.txt=text/plain' + #10 +

//  Data interchange

    '.json=application/json'#10 +
    '.map=application/json'#10 +
    '.geojson=application/geo+json'#10 +
    '.topojson=application/json'#10 +
    '.jsonld=application/ld+json'#10 +
    '.atom=application/atom+xml'#10 +
    '.rss=application/rss+xml'#10 +
    '.rdf=application/rdf+xml'#10 +
    '.xml=application/xml'#10 +

//  Manifest files

    '.webmanifest=application/manifest+json'#10 +
    '.webapp=application/x-web-app-manifest+json'#10 +
    '.appcache=text/cache-manifest'#10 +

//  Media files

    '.svg=image/svg+xml'#10 +
    '.svgz=image/svg+xml'#10 +
    '.f4a=audio/mp4'#10 +
    '.f4b=audio/mp4'#10 +
    '.m4a=audio/mp4'#10 +
    '.oga=audio/ogg'#10 +
    '.ogg=audio/ogg'#10 +
    '.opus=audio/ogg'#10 +
    '.bmp=image/bmp'#10 +
    '.webp=image/webp'#10 +
    '.f4v=video/mp4'#10 +
    '.f4p=video/mp4'#10 +
    '.m4v=video/mp4'#10 +
    '.mp4=video/mp4'#10 +
    '.ogv=video/ogg'#10 +
    '.webm=video/webm'#10 +
    '.flv=video/x-flv'#10 +

//  Serving `.ico` image files with a different media type
//  prevents Internet Explorer from displaying them as images:
//  https://github.com/h5bp/html5-boilerplate/commit/37b5fec090d00f38de64b591bcddcb205aadf8ee

    '.cur=image/x-icon'#10 +
    '.ico=image/x-icon'#10 +

//  WebAssembly

    '.wasm=application/wasm'#10 +

//  Web fonts

    '.woff=font/woff'#10 +
    '.woff2=font/woff2'#10 +
    '.eot=application/vnd.ms-fontobject'#10 +
    '.ttf=font/ttf'#10 +
    '.ttc=font/collection'#10 +
    '.otf=font/otf'#10 +

//  Other

    '.safariextz=application/octet-stream'#10 +
    '.bbaw=application/x-bb-appworld'#10 +
    '.crx=application/x-chrome-extension'#10 +
    '.oex=application/x-opera-extension'#10 +
    '.xpi=application/x-xpinstall'#10 +
    '.ics=text/calendar'#10 +
    '.markdown=text/markdown'#10 +
    '.md=text/markdown'#10 +
    '.vcard=text/vcard'#10 +
    '.vcf=text/vcard'#10 +
    '.xloc=text/vnd.rim.location.xloc'#10 +
    '.vtt=text/vtt'#10 +
    '.htc=text/x-component'#10 +

// Mustache partial template

    '.partial=text/html' + #10 +

    '';

/// Fill the RawUTF8 array with unique, lower-cased and
// sorted values ready for binary search
procedure ArrayFromCSV(out anArray: TRawUTF8DynArray; const CSV: RawUTF8;
  const Prefix: RawUTF8 = '.'; const Sep: AnsiChar = ',');

procedure CreateDirectories(const FileName: TFileName);
  {$IFDEF HASINLINE}inline;{$ENDIF}

function GetFileInfo(const FileName: TFileName; Modified: PDateTime;
  Size: PInt64): Boolean;

function SetFileTime(const FileName: TFileName;
  const Modified: TDateTime): Boolean;

implementation

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF KYLIX3}
  Libc,
  {$ELSE KYLIX3}
    {$IFDEF LINUX}
    BaseUnix,
    {$ENDIF LINUX}
  {$ENDIF KYLIX3}
  Classes;

var
  KnownMIMEContentTypes: TSynNameValue;

procedure ArrayFromCSV(out anArray: TRawUTF8DynArray; const CSV: RawUTF8;
  const Prefix: RawUTF8; const Sep: AnsiChar);
var
  Values: PUTF8Char;
  Value: RawUTF8;
  ArrayDA: TDynArray;
  ArrayCount: Integer;
  Index: Integer;
begin
  ArrayDA.Init(TypeInfo(TRawUTF8DynArray), anArray, @ArrayCount);
  Values := PUTF8Char(CSV);
  while Values <> nil do
  begin
    Value := GetNextItem(Values, Sep);
    if Value <> '' then
    begin
      Value := Prefix + LowerCase(Value);
      ArrayDA.Add(Value);
    end;
  end;
  ArrayDA.Sort(SortDynArrayPUTF8Char);
  for Index := ArrayDA.Count - 1 downto 1 do
    if anArray[Index] = anArray[Index - 1] then
      ArrayDA.Delete(Index);
  SetLength(anArray, ArrayDA.Count);
end;

function GetFileInfo(const FileName: TFileName; Modified: PDateTime;
  Size: PInt64): Boolean;
{$IFDEF MSWINDOWS}
var
  FA: TWin32FileAttributeData;
  SystemTime: TSystemTime;
begin
  Result := GetFileAttributesEx(Pointer(FileName), GetFileExInfoStandard, @FA);
  if not Result then Exit;

  if Modified <> nil then
  begin
    Result := FileTimeToSystemTime(FA.ftLastWriteTime, SystemTime);
    if not Result then Exit;
    Modified^ := SystemTimeToDateTime(SystemTime);
  end;

  if Size <> nil then
  begin
    PInt64Rec(Size)^.Lo := FA.nFileSizeLow;
    PInt64Rec(Size)^.Hi := FA.nFileSizeHigh;
  end;
end;
{$ENDIF}
{$IFDEF FPCLINUX}
var
  fd: cint;
  sb: Stat;
begin
  fd := FpOpen(PChar(FileName), O_RdOnly);
  Result := fd > 0;
  if not Result then Exit;

  try
    Result := FpFStat(fd, sb) = 0;
    if not Result then Exit;

    if Modified <> nil then
      Modified^ := UnixMSTimeToDateTime(sb.st_mtime * MSecsPerSec);

    if Size <> nil then
      Size^ := sb.st_size;
  finally
    if FpClose(fd) <> 0 then
      Result := False;
  end;
end;
{$ENDIF}
{$IFDEF KYLIX3}
var
  Handle: Integer;
  StatBuf: TStatBuf;
  Current, LSize: Int64;
begin
  Handle := Libc.open(PChar(FileName), O_RDONLY);
  Result := PtrInt(Handle) > 0;
  if not Result then Exit;

  try
    if Modified <> nil then
    begin
      Result := Libc.fstat(Handle, StatBuf) = 0;
      if not Result then Exit;
    
      Modified^ := UnixMSTimeToDateTime(
        TUnixMSTime(StatBuf.st_mtime) * MSecsPerSec);
    end;

    if Size <> nil then
    begin
      Current := Libc.lseek64(Handle, 0, SEEK_CUR);
      Result := Current <> -1;
      if not Result then Exit;

      LSize := Libc.lseek64(Handle, 0, SEEK_END);
      Result := LSize <> -1;
      if not Result then Exit;

      Result := lseek64(Handle, Current, SEEK_SET) <> -1;
      if not Result then Exit;

      Size^ := LSize;
    end;
  finally
    if Libc.__close(Handle) <> 0 then
      Result := False;
  end;
end;
{$ENDIF}

function SetFileTime(const FileName: TFileName;
  const Modified: TDateTime): Boolean;
{$IFDEF MSWINDOWS}
var
  Handle: THandle;
  SystemTime: TSystemTime;
  LModified: TFileTime;
begin
  DateTimeToSystemTime(Modified, SystemTime);
  Result := SystemTimeToFileTime(SystemTime, LModified);
  if not Result then Exit;

  Handle := FileOpen(FileName, fmOpenWrite or fmShareDenyNone);
  if Handle = THandle(-1) then
  begin
    Result := False;
    Exit;
  end;
  Result := Windows.SetFileTime(Handle, @LModified, @LModified, @LModified);
  FileClose(Handle);
end;
{$ENDIF}
{$IFDEF FPCLINUX}
var
  times: UTimBuf;
begin
  times.actime := DateTimeToUnixTime(Modified);
  times.modtime := times.actime;
  Result := FpUtime(PChar(FileName), @times) = 0;
end;
{$ENDIF}
{$IFDEF KYLIX3}
var
  AccessModTimes: TAccessModificationTimes;
  TimeStamp: Int64;
begin
  TimeStamp := DateTimeToUnixTime(Modified);
  AccessModTimes.AccessTime.tv_sec := TimeStamp;
  AccessModTimes.AccessTime.tv_usec := 0;
  AccessModTimes.ModificationTime.tv_sec := TimeStamp;
  AccessModTimes.ModificationTime.tv_usec := 0;
  Result := utimes(PChar(FileName), AccessModTimes) = 0;
end;
{$ENDIF}

procedure CreateDirectories(const FileName: TFileName);
var
  Index: Integer;
  LFileName: RawUTF8;
  Directory: TFileName;
begin
  LFileName := StringToUTF8(FileName);
  Index := 1;
  repeat
    Index := PosEx(PathDelim, LFileName, Index);
    if Index = 0 then Exit;
    SetString(Directory, PChar(FileName), Index);
    EnsureDirectoryExists(Directory, True);
    Inc(Index);
  until False;
end;

{ TAsset }

function TAsset.LoadFromFile(const Root, FileName: TFileName): Boolean;
begin
  Result := FileExists(FileName);
  if not Result then Exit;

  Result := GetFileInfo(FileName, @Modified, nil);
  if not Result then Exit;

  if (Root <> '') and (Length(FileName) > Length(Root)) and
    IdemPropName(Pointer(Root), Pointer(FileName),
      Length(Root), Length(Root)) then
        SetString(Path, PChar(@FileName[Length(Root)]),
          Length(FileName) - Length(Root) + 1)
  else
    SetString(Path, PChar(FileName), Length(FileName));

  {$IFDEF MSWINDOWS}
  Path := StringReplaceChars(Path, PathDelim, '/');
  {$ENDIF}

  Path := LowerCase(Path);

  SetEncoding(StringFromFile(FileName));

  ContentType := KnownMIMEContentTypes.Value(
    LowerCase(StringToAnsi7(ExtractFileExt(FileName))), #0);
  if ContentType = #0 then
    ContentType := GetMimeContentType(Pointer(Content), Length(Content),
      FileName);

  GZipExists := False;
  GZipEncoding := '';
  GZipHash := 0;

  BrotliExists := False;
  BrotliEncoding := '';
  BrotliHash := 0;
end;

function TAsset.SaveIdentityToFile(const Root: TFileName;
  const ChecksNotModified: TFileChecks): TFileName;
var
  LModified: TDateTime;
  LSize: Int64;
  FileModified: Boolean;
begin
  Result := UTF8ToString(Path);

  {$IFDEF MSWINDOWS}
  Result := StringReplace(Result, '/', PathDelim, [rfReplaceAll]);
  {$ENDIF}

  if Root = '' then
    Delete(Result, 1, 1)
  else if Root[Length(Root)] = PathDelim then
    Result := Root + Result
  else
    Result := Root + PathDelim + Result;

  if (ChecksNotModified <> []) and FileExists(Result) and
    GetFileInfo(Result, @LModified, @LSize) then
    begin
      FileModified := False;
      if fcModified in ChecksNotModified then
        FileModified := FileModified or
          (Round((LModified - Modified) * SecsPerDay) <> 0);
      if fcSize in ChecksNotModified then
        FileModified := FileModified or
          (FileSize(Result) <> Length(Content));
      if not FileModified then Exit;
    end;

  CreateDirectories(Result);

  if FileFromString(Content, Result) then
    SetFileTime(Result, Modified);
end;

function TAsset.SaveToFile(const Root: TFileName;
  const Encoding: TAssetEncoding;
  const ChecksNotModified: TFileChecks): TFileName;
const
  DIRS: array[TAssetEncoding] of TFileName = ('identity', 'gzip', 'brotli');
  EXTS: array[TAssetEncoding] of TFileName = ('', '.gz', '.br');
var
  LModified: TDateTime;
  LSize: Int64;
  FileModified: Boolean;
  FileContent: RawByteString;

begin
  case Encoding of
    aeIdentity:
      FileContent := Content;

    aeGZip:
      if GZipExists then
        FileContent := GZipEncoding
      else begin
        Result := '';
        Exit;
      end;

    aeBrotli:
      if BrotliExists then
        FileContent := BrotliEncoding
      else begin
        Result := '';
        Exit;
      end;
  end;

  Result := UTF8ToString(Path);

  {$IFDEF MSWINDOWS}
  Result := StringReplace(Result, '/', PathDelim, [rfReplaceAll]);
  {$ENDIF}

  if Root = '' then
    Result := DIRS[Encoding] + Result
  else if Root[Length(Root)] = PathDelim then
    Result := Root + DIRS[Encoding] + Result
  else
    Result := Root + PathDelim + DIRS[Encoding] + Result;

  if Encoding in [aeGZip, aeBrotli] then
    Result := Result + EXTS[Encoding];

  if (ChecksNotModified <> []) and FileExists(Result) and
    GetFileInfo(Result, @LModified, @LSize) then
    begin
      FileModified := False;
      if fcModified in ChecksNotModified then
        FileModified := FileModified or
          (Round((LModified - Modified) * SecsPerDay) <> 0);
      if fcSize in ChecksNotModified then
        FileModified := FileModified or
          (FileSize(Result) <> Length(FileContent));
      if not FileModified then Exit;
    end;

  CreateDirectories(Result);

  if FileFromString(FileContent, Result) then
    SetFileTime(Result, Modified);
end;

procedure TAsset.SetEncoding(const Encoded: RawByteString;
  const Encoding: TAssetEncoding);
begin
  case Encoding of
    aeIdentity:
      begin
        Content := Encoded;
        Hash := crc32c(0, Pointer(Encoded), Length(Encoded));
      end;

    aeGZip:
      begin
        GZipExists := True;
        GZipEncoding := Encoded;
        GZipHash := crc32c(0, Pointer(Encoded), Length(Encoded));
      end;

    aeBrotli:
      begin
        BrotliExists := True;
        BrotliEncoding := Encoded;
        BrotliHash := crc32c(0, Pointer(Encoded), Length(Encoded));
      end;
  end;
end;

{ TAssets }

function TAssets.Add(const Root, FileName: TFileName): PAsset;
var
  Asset: TAsset;
  Index: Integer;
  WasAdded: Boolean;
begin
  if not Asset.LoadFromFile(Root, FileName) then
  begin
    Result := nil;
    Exit;
  end;
  Index := FAssetsDAH.FindHashedForAdding(Asset.Path, WasAdded);
  Assets[Index] := Asset;
  Result := @Assets[Index];
end;

function TAssets.Find(const Path: RawUTF8): PAsset;
var
  Index: Integer;
begin
  Index := FAssetsDAH.FindHashed(Path);
  if Index >= 0 then
    Result := @Assets[Index]
  else
    Result := nil;
end;

procedure TAssets.Init;
begin
  Assets := nil;
  FillCharFast(Self, SizeOf(Self), 0);
  FAssetsDAH.InitSpecific(TypeInfo(TAssetDynArray), Assets, djRawUTF8, @Count);
end;

procedure TAssets.LoadFromFile(const FileName: TFileName);
begin
  FAssetsDAH.LoadFrom(Pointer(AlgoSynLZ.Decompress(StringFromFile(FileName))));
  FAssetsDAH.ReHash;
end;

procedure TAssets.LoadFromResource(const ResName: string);
var
  RawAssets: RawByteString;
begin
  ResourceSynLZToRawByteString(ResName, RawAssets);
  FAssetsDAH.LoadFrom(Pointer(RawAssets));
  FAssetsDAH.ReHash;
end;

procedure TAssets.SaveAll(const Root: TFileName;
  const ChecksNotModified: TFileChecks);
var
  Index: Integer;
  Encoding: TAssetEncoding;
begin
  for Index := 0 to Count - 1 do
    with Assets[Index] do
      for Encoding := Low(TAssetEncoding) to High(TAssetEncoding) do
        SaveToFile(Root, Encoding, ChecksNotModified);
end;

procedure TAssets.SaveAllIdentities(const Root: TFileName;
  const ChecksNotModified: TFileChecks);
var
  Index: Integer;
begin
  for Index := 0 to Count - 1 do
    with Assets[Index] do
        SaveIdentityToFile(Root, ChecksNotModified);
end;

procedure TAssets.SaveToFile(const FileName: TFileName);
begin
  FileFromString(AlgoSynLZ.Compress(FAssetsDAH.SaveTo), FileName);
end;

initialization
  KnownMIMEContentTypes.InitFromCSV(MIME_CONTENT_TYPES);

end.
