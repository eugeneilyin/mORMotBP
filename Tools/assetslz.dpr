(*

  This file is a path of integration project between HTML5 Boilerplate and
  Synopse mORMot Framework.

    https://synopse.info
    https://html5boilerplate.com

  Boilerplate HTTP Server
  (c) 2016-Present Yevgeny Iliyn

  License: MIT

  https://github.com/eugeneilyin/mORMotBP

  You could add the next "Post-build event" to shrink exe size:

  "$(PROJECTDIR)\post-build.bat" "$(PROJECTDIR)\$(PROJECTNAME).exe"

*)

program assetslz;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  SynCommons,
  SynZip,
  Brotli in '..\Brotli.pas',
  Zopfli in 'Zopfli\Zopfli.pas',
  BoilerplateAssets in '..\BoilerplateAssets.pas';

{$I MinPE.inc}

var
  Root: TFileName;
  ArchiveName: TFileName;
  GZipLevel: Integer = 9;
  GZipUsed: Boolean = False;
  ZopfliNumIterations: Integer = 15;
  ZopfliBlockSplittingMax: Integer = 15;
  BrotliQuality: Integer = 11;
  BrotliWindowsBits: Integer = 24;
  Extensions: TFileName = 'appcache,atom,bmp,css,cur,eot,geojson,htc,html,' +
    'ico,ics,js,json,jsonld,map,markdown,md,mjs,otf,rdf,rss,svg,topojson,ttc,' +
    'ttf,txt,vcard,vcf,vtt,wasm,webapp,webmanifest,xhtml,xloc,xml';

type
  TParseParametersResult = (pprSuccess, pprWriteManual, pprError);

procedure WriteManual;
begin
  Writeln('Creates assets bundle with all files in directory.');
  Writeln('');
  Writeln('Usage:');
  Writeln('');
  Writeln('  assetslz [options] directory bundle');
  Writeln('');
  Writeln('  Options:');
  Writeln('');
  Writeln('    /E or -E      Specifies the comma-separated list of assets extenstions');
  Writeln('                  used for GZip and Brotli compression.');
  Writeln('                  -E means skip compression stage');
  Writeln('                  -E* means compress all assets');
  Writeln('                  Default: -Eappcache,atom,bmp,css,cur,eot,geojson,htc,html,');
  Writeln('                             ico,ics,js,json,jsonld,map,markdown,md,mjs,otf,');
  Writeln('                             rdf,rss,svg,topojson,ttc,ttf,txt,vcard,vcf,vtt,');
  Writeln('                             wasm,webapp,webmanifest,xhtml,xloc,xml');
  Writeln('');
  Writeln('    /GZ# or -GZ#  Specifies the GZip compression level.');
  Writeln('                  Range: 0-9');
  Writeln('                  Default: Zopfli is used');
  Writeln('');
  Writeln('    /Z# or -Z#    Specifies to use Zopfli compression instead of GZip with');
  Writeln('                  maximum amount of times to rerun forward and backward pass.');
  Writeln('                  Good values: 10, 15 for small files, 5 for files over');
  Writeln('                  several MB in size or it take a lot of time for compression.');
  Writeln('                  Default: -Z15');
  Writeln('');
  Writeln('    /ZB# or -ZB#  Specifies the BlockSplittingMax parameter used in Zopfli');
  Writeln('                  compression (0 for unlimited, but this can give extreme');
  Writeln('                  results that hurt compression on some files).');
  Writeln('                  Default: -ZB15');
  Writeln('');
  Writeln('    /B# or -B#    Specifies the Brotli compression level. Bigger values cause');
  Writeln('                  denser, but slower compression.');
  Writeln('                  Range: 0-11');
  Writeln('                  Default: -B11');
  Writeln('');
  Writeln('    /BW# or -BW#  Specifies the LZ77 window size in bits used in Brotli');
  Writeln('                  compression. Decoder might require up to window');
  Writeln('                  size (2 ^ Size - 16) memory to operate.');
  Writeln('                  Range: 0, 10-24');
  Writeln('                    (0 lets compressor decide over the optimal value)');
  Writeln('                  Default: -BW24');
end;

function CheckPrefix(const Param, Prefix: string; out Value: string): Boolean;
begin
  Result :=
    (Copy(Param, 1, Length(Prefix) + 1) = '/' + Prefix) or
    (Copy(Param, 1, Length(Prefix) + 1) = '-' + Prefix);
  if Result then
    Value := Copy(Param, Length(Prefix) + 2, MaxInt);
end;

function CheckRange(const Value, Min, Max: Integer): Boolean;
begin
  Result := (Value >= Min) and (Value <= Max);
end;

function ParseParameters: TParseParametersResult;
var
  Index: Integer;
  Param, ParamLC, ParamValue: string;
begin
  Result := pprWriteManual;
  for Index := 1 to ParamCount do
  begin
    Param := SysUtils.Trim(ParamStr(Index));
    if Param = '' then Continue;

    ParamLC := SysUtils.LowerCase(Param);
    if (ParamLC = '-?') or (ParamLC = '/?') or
      (ParamLC = '-h') or (ParamLC = '/h') or
      (ParamLC = '--help') or (ParamLC = '/help') or
      (ParamLC = '-help')  then Exit;

    if CheckPrefix(ParamLC, 'e', ParamValue) then
    begin
      Extensions := ParamValue;
      Continue;
    end;

    if CheckPrefix(ParamLC, 'gz', ParamValue) then
    begin
      if not TryStrToInt(ParamValue, GZipLevel) or
        not CheckRange(GZipLevel, 0, 9) then Exit;
      GZipUsed := True;
      Continue;
    end;

    if CheckPrefix(ParamLC, 'zb', ParamValue) then
    begin
      if not TryStrToInt(ParamValue, ZopfliBlockSplittingMax) or
        not (ZopfliBlockSplittingMax >= 0) then Exit;
      GZipUsed := False;
      Continue;
    end;

    if CheckPrefix(ParamLC, 'z', ParamValue) then
    begin
      if not TryStrToInt(ParamValue, ZopfliNumIterations) or
        not (ZopfliNumIterations >= 1) then Exit;
      GZipUsed := False;
      Continue;
    end;

    if CheckPrefix(ParamLC, 'bw', ParamValue) then
    begin
      if not TryStrToInt(ParamValue, BrotliWindowsBits) or
        not ((BrotliWindowsBits = 0) or
          CheckRange(BrotliWindowsBits, 10, 24)) then Exit;
      Continue;
    end;

    if CheckPrefix(ParamLC, 'b', ParamValue) then
    begin
      if not TryStrToInt(ParamValue, BrotliQuality) or
        not CheckRange(BrotliQuality, 0, 11) then Exit;
      Continue;
    end;

    if (Param[1] = '-') {$IFDEF MSWINDOWS} or (Param[1] = '/') {$ENDIF} then
      Exit;

    if Root = '' then
      Root := ExcludeTrailingPathDelimiter(ExpandFileName(Param))
    else
      if ArchiveName = '' then
        ArchiveName := ExpandFileName(Param)
      else
        Exit;
  end;

  if (Root = '') or (ArchiveName = '') then Exit;

  if not (DirectoryExists(Root) or FileExists(Root)) then
  begin
    Writeln(Format('Directory or file "%s" not found', [Root]));
    Result := pprError;
    Exit;
  end;

  Result := pprSuccess;
end;

/// See SynZip.CompressGZip for details
procedure CompressGZip(var DataRawByteString; const Level: Integer);
const
  GZHEAD: array [0..2] of Cardinal = ($088B1F, 0, 0);
  GZHEAD_SIZE = 10;
var
  L: Integer;
  P: PAnsiChar;
  Data: ZipString absolute DataRawByteString;
  Buffer: AnsiString;
begin
  L := Length(Data);
  SetString(Buffer, nil, L + 128 + L shr 3); // maximum possible memory required
  P := Pointer(Buffer);
  MoveFast(GZHEAD, P^, GZHEAD_SIZE);
  Inc(P, GZHEAD_SIZE);
  Inc(P, CompressMem(Pointer(Data), P, L,
    Length(Buffer) - (GZHEAD_SIZE + 8), Level));
  PCardinal(P)^ := SynZip.crc32(0, Pointer(Data), L);
  Inc(P, 4);
  PCardinal(P)^ := L;
  Inc(P, 4);
  SetString(Data, PAnsiChar(Pointer(Buffer)), P - Pointer(Buffer));
end;

function SortDynArrayFileName(const A, B): Integer;
begin
  Result := AnsiCompareStr(TFileName(A), TFileName(B));
end;

/// Creates upper-cased, sorted, deduplicated, '.'-prefixed TFileName array
// ready for O(log(n)) file extension binary search
procedure UpArrayFromCSV(const ExtsCSV: TFileName; var Exts: TFileNameDynArray);
var
  Index, DeduplicateIndex, Count: Integer;
  P: PChar;
  ArrayDA: TDynArray;
  FileExt: TFileName;
begin
  if ExtsCSV = '' then
  begin
    Exts := nil;
    Exit;
  end;
  ArrayDA.Init(TypeInfo(TFileNameDynArray), Exts, @Count);
  P := Pointer(ExtsCSV);
  while P <> nil do
  begin
    FileExt := GetNextItemString(P, ',');
    if FileExt <> '' then
    begin
      FileExt := '.' + SysUtils.UpperCase(FileExt);
      ArrayDA.Add(FileExt);
    end;
  end;
  if Count <= 1 then
    SetLength(Exts, Count)
  else begin
    ArrayDA.Sort(SortDynArrayFileName);
    DeduplicateIndex := 0;
    for Index := 1 to Count - 1 do
      if Exts[DeduplicateIndex] <> Exts[Index] then
      begin
        Inc(DeduplicateIndex);
        if DeduplicateIndex <> Index then
          Exts[DeduplicateIndex] := Exts[Index];
      end;
    SetLength(Exts, DeduplicateIndex + 1);
  end;
end;

// Fast O(log(n)) binary search of TFileName value in array
function FastFindFileNameSorted(const Value: TFileName;
  const FileNames: TFileNameDynArray): PtrInt;
var
  L, R: PtrInt;
  Compare: Integer;
begin
  L := 0;
  R := High(FileNames);
  if (Value <> '') and (R >= 0) then
    repeat
      Result := (L + R) shr 1;
      Compare := SortDynArrayFileName(FileNames[Result], Value);
      if Compare = 0 then Exit;
      if Compare < 0 then
        L := Result + 1
      else
        R := Result - 1;
      if L <= R then Continue;
      Break;
    until False;
  Result := -1;
end;

function GetBrotliEncoderMode(const ContentType: RawUTF8): TBrotliEncoderMode;
begin
  if IdemPChar(Pointer(ContentType), 'TEXT/') or
    (ContentType = 'application/json') or
    (ContentType = 'application/xml') or
    (PosEx('+xml', ContentType) > 0) or
    (PosEx('+json', ContentType) > 0) then
      Result := bemText
  else if IdemPChar(Pointer(ContentType), 'FONT/') then
    Result := bemFont
  else
    Result := bemGeneric;
end;

procedure CreateArchive;
var
  Index: Integer;
  Assets: TAssets;
  Files: TFindFilesDynArray;
  CompressAll: Boolean;
  CompressibleExts: TFileNameDynArray;

  function AddAsset(const Root, FileName: TFileName): Boolean;
  var
    Asset: PAsset;
    Content: EncodedString;
  begin
    Result := False;

    Asset := Assets.Add(Root, FileName);
    if not Assigned(Asset) then
    begin
      Writeln(Format('Asset add failed: "%s"', [FileName]));
      Exit;
    end;

    if CompressAll or (FastFindFileNameSorted(
      SysUtils.UpperCase(ExtractFileExt(FileName)), CompressibleExts) >= 0) then
    begin
      if GZipUsed then
      begin
        Content := Asset.Content;
        CompressGZip(Content, GZipLevel);
        if Length(Content) < Length(Asset.Content) then
          Asset.SetContent(Content, aeGZip);
      end else begin
        if not ZopfliCompress(Asset.Content, Content, zfGZip,
          ZopfliNumIterations, ZopfliBlockSplittingMax) then
        begin
          Writeln(Format('Zopfli compression failed: "%s"', [FileName]));
          Exit;
        end;
        if Length(Content) < Length(Asset.Content) then
          Asset.SetContent(Content, aeGZip);
      end;

      if not BrotliCompress(Asset.Content, Content,
        GetBrotliEncoderMode(Asset.ContentType),
        BrotliQuality, BrotliWindowsBits) then
      begin
        Writeln(Format('Brotli compression failed: "%s"', [FileName]));
        Exit;
      end;
      if Length(Content) < Length(Asset.Content) then
        Asset.SetContent(Content, aeBrotli);
    end;
    Result := True;
  end;

begin
  {$IFDEF VER140} Files := nil; {$ENDIF} // Delphi 6 unused hint prevention
  Assets.Init;
  CompressAll := Extensions = '*';
  if not CompressAll then
    UpArrayFromCSV(Extensions, CompressibleExts);
  if DirectoryExists(Root) then
  begin
    Root := IncludeTrailingPathDelimiter(Root);
    Files := FindFiles(Root, '*', '', True, True, True);
    for Index := Low(Files) to High(Files) do
      if not AddAsset(Root, Files[Index].Name) then
      begin
        ExitCode := 1;
        Exit;
      end;
  end else
    if not AddAsset(ExtractFilePath(Root), Root) then
    begin
      ExitCode := 1;
      Exit;
    end;
  if not Assets.SaveToFile(ArchiveName) then
  begin
    Writeln(Format('Assets save failed: "%s"', [ArchiveName]));
    ExitCode := 1;
    Exit;
  end;
end;

begin
  try
    case ParseParameters of
      pprSuccess: CreateArchive;
      pprWriteManual: WriteManual;
      pprError: ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln(Format('%s: %s', [E.ClassName, E.Message]));
      ExitCode := 1;
    end;
  end;
end.
