/// HTML5 Boilerplate integration with Synopse mORMot Framework
// Licensed under The MIT License (MIT)
unit BoilerplateAssets;

(*
  This file is a path of integration project between HTML5 Boilerplate and
  Synopse mORMot Framework.

    http://synopse.info
    https://html5boilerplate.com

  Boilerplate HTTP Server
  (c) 2016 Yevgeny Iliyn

  https://github.com/eugeneilyin/mORMotBP

  Version 1.0
  - First public release

*)

{$I Synopse.inc} // define HASINLINE USETYPEINFO CPU32 CPU64 OWNNORMTOUPPER

interface

uses
  SysUtils, SynCommons;

type

  TFileCheck = (ccCreated, ccModified, ccSize);
  TFileChecks = set of TFileCheck;

  TAsset = packed record
    Path: RawUTF8;
    Created: TDateTime;
    Modified: TDateTime;
    ContentType: RawUTF8;
    ContentHash: Cardinal;
    Content: RawByteString;
    function GetFileName(const Root: TFileName): TFileName;
      {$ifdef HASINLINE} inline;{$endif}
    function LoadFromFile(const Root, FileName: TFileName): Boolean;
    procedure SaveToFile(const FileName: TFileName;
      const ChecksNotModified: TFileChecks = [ccCreated, ccModified, ccSize]);
  end;
  PAsset = ^TAsset;
  TAssetDynArray = array of TAsset;

  {$ifdef UNDIRECTDYNARRAY}
  TAssets = record
  private
  {$else}
  TAssets = object
  protected
  {$endif}
    FAssetsDAH: TDynArrayHashed;
  public
    Assets: TAssetDynArray;
    Count: Integer;
    procedure Init;
    procedure Add(const Root, FileName: TFileName);
    procedure CompressToFile(const FileName: string);
    procedure DecompressFromFile(const FileName: string);
    procedure DecompressFromResource(const ResName: string);
    procedure SaveAssets(const Root: TFileName; const AllowedCSV: RawUTF8 = '';
      const ChecksNotModified: TFileChecks = [ccCreated, ccModified, ccSize]);
    function Find(const Path: RawUTF8): PAsset;
      {$ifdef HASINLINE} inline;{$endif}
  end;

const
  MIME_CONTENT_TYPES =

//  HTML / mustache partial template

    '.html=text/html' + #10 +
    '.partial=text/html' + #10 +

//  Text

    '.txt=text/plain' + #10 +

//  Data interchange

    '.atom=application/atom+xml'#10 +
    '.json=application/json'#10 +
    '.map=application/json'#10 +
    '.topojson=application/json'#10 +
    '.jsonld=application/ld+json'#10 +
    '.rss=application/rss+xml'#10 +
    '.geojson=application/vnd.geo+json'#10 +
    '.rdf=application/xml'#10 +
    '.xml=application/xml'#10 +

//  JavaScript
//  Normalize to standard type.
//  https://tools.ietf.org/html/rfc4329#section-7.2

    '.js=application/javascript'#10 +

//  Manifest files

    '.webmanifest=application/manifest+json'#10 +
    '.webapp=application/x-web-app-manifest+json'#10 +
    '.appcache=text/cache-manifest'#10 +

//  Media files

    '.f4a=audio/mp4'#10 +
    '.f4b=audio/mp4'#10 +
    '.m4a=audio/mp4'#10 +
    '.oga=audio/ogg'#10 +
    '.ogg=audio/ogg'#10 +
    '.opus=audio/ogg'#10 +
    '.bmp=image/bmp'#10 +
    '.svg=image/svg+xml'#10 +
    '.svgz=image/svg+xml'#10 +
    '.webp=image/webp'#10 +
    '.f4v=video/mp4'#10 +
    '.f4p=video/mp4'#10 +
    '.m4v=video/mp4'#10 +
    '.mp4=video/mp4'#10 +
    '.ogv=video/ogg'#10 +
    '.webm=video/webm'#10 +
    '.flv=video/x-flv'#10 +

//  Serving `.ico` image files with a different media type
//  prevents Internet Explorer from displaying then as images:
//  https://github.com/h5bp/html5-boilerplate/commit/37b5fec090d00f38de64b591bcddcb205aadf8ee

    '.cur=image/x-icon'#10 +
    '.ico=image/x-icon'#10 +

//  Web fonts

    '.woff=application/font-woff'#10 +
    '.woff2=application/font-woff2'#10 +
    '.eot=application/vnd.ms-fontobject'#10 +

//  Browsers usually ignore the font media types and simply sniff
//  the bytes to figure out the font type.
//  https://mimesniff.spec.whatwg.org/#matching-a-font-type-pattern
//
//  However, Blink and WebKit based browsers will show a warning
//  in the console if the following font types are served with any
//  other media types.

    '.ttc=application/x-font-ttf'#10 +
    '.ttf=application/x-font-ttf'#10 +
    '.otf=font/opentype'#10 +

//  Other

    '.safariextz=application/octet-stream'#10 +
    '.bbaw=application/x-bb-appworld'#10 +
    '.crx=application/x-chrome-extension'#10 +
    '.oex=application/x-opera-extension'#10 +
    '.xpi=application/x-xpinstall'#10 +
    '.vcard=text/vcard'#10 +
    '.vcf=text/vcard'#10 +
    '.xloc=text/vnd.rim.location.xloc'#10 +
    '.vtt=text/vtt'#10 +
    '.htc=text/x-component'#10 +

    '';

procedure CreateDirectories(const FileName: TFileName);
  {$ifdef HASINLINE} inline;{$endif}

function GetFileInfo(const FileName: TFileName; Created, Modified: PDateTime;
  Size: PInt64): Boolean;

procedure SetFileTime(const FileName: TFileName;
  const Created, Modified: TDateTime);

implementation

uses
  Classes, Windows;

var
  KnownMIMEContentTypes: TSynNameValue;

function GetPath(const Root, FileName: TFileName): RawUTF8;
  {$ifdef HASINLINE} inline;{$endif}
begin
  if (Root <> '') and (Length(FileName) > Length(Root)) and IdemPropName(
    Pointer(Root), Pointer(FileName), Length(Root), Length(Root)) then
      SetString(Result, PChar(@FileName[Length(Root)]),
        Length(FileName) - Length(Root) + 1)
  else
    SetString(Result, PChar(FileName), Length(FileName));
  Result := LowerCase(StringReplaceChars(Result, PathDelim, '/'));
end;

function FileTimeToDateTime(const FileTime: TFileTime;
  out DateTime: TDateTime): Boolean;
var
  SystemTime: TSystemTime;
begin
  Result := FileTimeToSystemTime(FileTime, SystemTime);
  if not Result then Exit;
  DateTime := SystemTimeToDateTime(SystemTime);
end;

function DateTimeToFileTime(const DateTime: TDateTime;
  out FileTime: TFileTime): Boolean;
  {$ifdef HASINLINE} inline;{$endif}
var
  SystemTime: TSystemTime;
begin
  DateTimeToSystemTime(DateTime, SystemTime);
  Result := SystemTimeToFileTime(SystemTime, FileTime);
end;

function GetFileInfo(const FileName: TFileName; Created, Modified: PDateTime;
  Size: PInt64): Boolean;
var
  FA: TWin32FileAttributeData;
begin
  Result := GetFileAttributesEx(Pointer(FileName), GetFileExInfoStandard, @FA);
  if not Result then Exit;
  if Created <> nil then
  begin
    Result := FileTimeToDateTime(FA.ftCreationTime, Created^);
    if not Result then Exit;
  end;
  if Modified <> nil then
  begin
    Result := FileTimeToDateTime(FA.ftLastWriteTime, Modified^);
    if not Result then Exit;
  end;
  if Size <> nil then
  begin
    PInt64Rec(Size)^.Lo := FA.nFileSizeLow;
    PInt64Rec(Size)^.Hi := FA.nFileSizeHigh;
  end;
end;

procedure SetFileTime(const FileName: TFileName;
  const Created, Modified: TDateTime);
var
  Handle: THandle;
  LCreated, LModified: TFileTime;
begin
  if not DateTimeToFileTime(Created, LCreated) then Exit;
  if not DateTimeToFileTime(Modified, LModified) then Exit;
  Handle := FileOpen(FileName, fmOpenWrite or fmShareDenyNone);
  if Handle = THandle(-1) then Exit;
  Windows.SetFileTime(Handle, @LCreated, @LModified, @LModified);
  FileClose(Handle);
end;

procedure CreateDirectories(const FileName: TFileName);
  {$ifdef HASINLINE} inline;{$endif}
var
  Index: Integer;
  Directory: TFileName;
begin
  Index := 1;
  repeat
    Index := Pos(PathDelim, FileName, Index);
    if Index = 0 then Exit;
    SetString(Directory, PChar(FileName), Index);
    EnsureDirectoryExists(Directory, True);
    Inc(Index);
  until False;
end;

function SortAssetByPath(const A, B): Integer;
begin
  Result := StrCompFast(Pointer(TAsset(A).Path), Pointer(TAsset(B).Path));
end;

{ TAsset }

function TAsset.GetFileName(const Root: TFileName): TFileName;
begin
  if (Root <> '') and (Root[Length(Root)] = PathDelim) then
    SetString(Result, PChar(Root), Length(Root) - 1)
  else
    SetString(Result, PChar(Root), Length(Root));
  Result := Result +
    StringReplace(UTF8ToString(Path), '/', PathDelim, [rfReplaceAll]);
end;

function TAsset.LoadFromFile(const Root, FileName: TFileName): Boolean;
begin
  Result := FileExists(FileName);
  if not Result then Exit;
  Result := GetFileInfo(FileName, @Created, @Modified, nil);
  if not Result then Exit;
  Path := GetPath(Root, FileName);
  Content := StringFromFile(FileName);
  ContentType :=
    KnownMIMEContentTypes.Value(ToUTF8(ExtractFileExt(FileName)), #0);
  if ContentType = #0 then
    ContentType := GetMimeContentType(
      Pointer(Content), Length(Content), FileName);
  ContentHash := crc32c(0, Pointer(Content), Length(Content));
end;

procedure TAsset.SaveToFile(const FileName: TFileName;
  const ChecksNotModified: TFileChecks);
var
  LCreated, LModified: TDateTime;
  LSize: Int64;
  FileModified: Boolean;
begin
  if (ChecksNotModified <> []) and FileExists(FileName) and
    GetFileInfo(FileName, @LCreated, @LModified, @LSize) then
    begin
      FileModified := False;
      if ccCreated in ChecksNotModified then
        FileModified := FileModified or (LCreated <> Created);
      if ccModified in ChecksNotModified then
        FileModified := FileModified or (LModified <> Modified);
      if ccSize in ChecksNotModified then
        FileModified := FileModified or (FileSize(FileName) <> Length(Content));
      if not FileModified then Exit;
    end;
  CreateDirectories(FileName);
  FileFromString(Content, FileName);
  SetFileTime(FileName, Created, Modified);
end;

procedure TAssets.Add(const Root, FileName: TFileName);
var
  Asset: TAsset;
  Index: Integer;
  WasAdded: Boolean;
begin
  if not Asset.LoadFromFile(Root, FileName) then Exit;
  Index := FAssetsDAH.FindHashedForAdding(Asset.Path, WasAdded);
  Assets[Index] := Asset;
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
  FAssetsDAH.InitSpecific(
    TypeInfo(TAssetDynArray), Assets, djRawUTF8, @Count, False);
end;

procedure TAssets.DecompressFromFile(const FileName: string);
begin
  FAssetsDAH.LoadFrom(Pointer(SynLZDecompress(StringFromFile(FileName))));
  FAssetsDAH.ReHash;
end;

procedure TAssets.DecompressFromResource(const ResName: string);
var
  RawAssets: RawByteString;
begin
  ResourceSynLZToRawByteString(ResName, RawAssets);
  FAssetsDAH.LoadFrom(Pointer(RawAssets));
  FAssetsDAH.ReHash;
end;

procedure TAssets.SaveAssets(const Root: TFileName; const AllowedCSV: RawUTF8;
  const ChecksNotModified: TFileChecks);
var
  Index, PatternIndex: Integer;
  Patterns: TRawUTF8DynArray;
  Match: Boolean;
begin
  CSVToRawUTF8DynArray(Pointer(AllowedCSV), Patterns);
  for Index := 0 to Count - 1 do
    with Assets[Index] do
    begin
      if Patterns <> nil then
      begin
        Match := False;
        for PatternIndex := Low(Patterns) to High(Patterns) do
          if IsMatch(Patterns[PatternIndex], Path) then
          begin
            Match := True;
            Break;
          end;
        if not Match then Continue;
      end;
      SaveToFile(GetFileName(Root), ChecksNotModified);
    end;
end;

procedure TAssets.CompressToFile(const FileName: string);
begin
  FileFromString(SynLZCompress(FAssetsDAH.SaveTo), FileName);
end;

initialization
  KnownMIMEContentTypes.InitFromCSV(MIME_CONTENT_TYPES);

end.
