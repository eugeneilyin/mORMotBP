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
  Zopfli in 'Zopfli\Zopfli.pas',
  Brotli in 'Brotli\Brotli.pas',
  BoilerplateAssets in '..\BoilerplateAssets.pas';

{$I MinPE.inc}

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
  Writeln('                  -E* means compress all assets (not recommended)');
  Writeln('                  Default: -Ehtml,css,js,json,svg,atom,mjs,map,topojson,jsonld,');
  Writeln('                             webmanifest,rdf,rss,geojson,eot,ttf,ttc,wasm,');
  Writeln('                             webapp,xml,otf,bmp,cur,ico,appcache,ics,markdown,');
  Writeln('                             md,vcard,vcfxloc,vtt,htc');
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

var
  Extensions: string = COMPRESSED_TYPES_CSV;
  GZipLevel: Integer = 9;
  GZipUsed: Boolean = False;
  ZopfliNumIterations: Integer = 15;
  ZopfliBlockSplittingMax: Integer = 15;
  BrotliQuality: Integer = 11;
  BrotliWindowsBits: Integer = 24;
  Path: string;
  ArchiveName: string;

type
  TParseParametersResult = (pprSuccess, pprWriteManual, pprError);

function CheckPrefix(const Param, Prefix: string; out Value: string): Boolean;
begin
  Result := (Copy(Param, 1, Length(Prefix) + 1) = '/' + Prefix) or
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
  Param, ParamLC, Value: string;
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

    if CheckPrefix(ParamLC, 'e', Value) then
    begin
      Extensions := Value;
      Continue;
    end;

    if CheckPrefix(ParamLC, 'gz', Value) then
    begin
      if not TryStrToInt(Value, GZipLevel) or
        not CheckRange(GZipLevel, 0, 9) then Exit;
      GZipUsed := True;
      Continue;
    end;

    if CheckPrefix(ParamLC, 'zb', Value) then
    begin
      if not TryStrToInt(Value, ZopfliBlockSplittingMax) or
        not (ZopfliBlockSplittingMax >= 0) then Exit;
      GZipUsed := False;
      Continue;
    end;

    if CheckPrefix(ParamLC, 'z', Value) then
    begin
      if not TryStrToInt(Value, ZopfliNumIterations) or
        not (ZopfliNumIterations >= 1) then Exit;
      GZipUsed := False;
      Continue;
    end;

    if CheckPrefix(ParamLC, 'bw', Value) then
    begin
      if not TryStrToInt(Value, BrotliWindowsBits) or
        not ((BrotliWindowsBits = 0) or
          CheckRange(BrotliWindowsBits, 10, 24)) then Exit;
      Continue;
    end;

    if CheckPrefix(ParamLC, 'b', Value) then
    begin
      if not TryStrToInt(Value, BrotliQuality) or
        not CheckRange(BrotliQuality, 0, 11) then Exit;
      Continue;
    end;

    if (Param[1] = '-') {$IFDEF MSWINDOWS}or (Param[1] = '/'){$ENDIF} then Exit;

    if Path = '' then
      Path := ExcludeTrailingPathDelimiter(ExpandFileName(Param))
    else
      if ArchiveName = '' then
        ArchiveName := ExpandFileName(Param)
      else
        Exit;
  end;

  if (Path = '') or (ArchiveName = '') then Exit;

  if not (DirectoryExists(Path) or FileExists(Path)) then
  begin
    Writeln(Format('Directory or file "%s" not found', [Path]));
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

procedure CreateArchive;
var
  Index: Integer;
  Assets: TAssets;
  Files: TFindFilesDynArray;
  CompressAll: Boolean;
  CompressExts: TRawUTF8DynArray;

  function IsCompressionExtension(const Ext: RawUTF8): Boolean;
  begin
    Result := CompressAll or
      (FastLocatePUTF8CharSorted(Pointer(CompressExts), High(CompressExts),
        Pointer(Ext)) = -1);
  end;

  function AddAsset(const Root, FileName: TFileName): Boolean;
  var
    Asset: PAsset;
    Encoded: EncodedString;
  begin
    Result := False;

    Asset := Assets.Add(Root, FileName);
    if not Assigned(Asset) then
    begin
      Writeln(Format('Asset add failed: "%s"', [FileName]));
      Exit;
    end;

    if IsCompressionExtension(LowerCase(ToUTF8(ExtractFileExt(FileName)))) then
    begin
      if GZipUsed then
      begin
        Encoded := Asset.Content;
        CompressGZip(Encoded, GZipLevel);
        Asset.SetEncoding(Encoded, aeGZip);
      end else begin
        if not ZopfliCompress(Asset.Content, Encoded, zfGZip,
          ZopfliNumIterations, ZopfliBlockSplittingMax) then
        begin
          Writeln(Format('Zopfli compression failed: "%s"', [FileName]));
          Exit;
        end;
        Asset.SetEncoding(Encoded, aeGZip);
      end;
      if not BrotliCompress(Asset.Content, Encoded, bemGeneric,
        BrotliQuality, BrotliWindowsBits) then
      begin
        Writeln(Format('Brotli compression failed: "%s"', [FileName]));
        Exit;
      end;
      Asset.SetEncoding(Encoded, aeBrotli);
    end;
    Result := True;
  end;

begin
  {$IFDEF VER140} Files := nil; {$ENDIF} // Delphi 6 unused hint prevention
  Assets.Init;
  CompressAll := Extensions = '*';
  if not CompressAll then
    ArrayFromCSV(CompressExts, ToUTF8(Extensions));
  if DirectoryExists(Path) then
  begin
    Path := IncludeTrailingPathDelimiter(Path);
    Files := FindFiles(Path, '*', '', True, True, True);
    for Index := Low(Files) to High(Files) do
      if not AddAsset(Path, Files[Index].Name) then
      begin
        ExitCode := 1;
        Exit;
      end;
  end else
    if not AddAsset(ExtractFilePath(Path), Path) then
    begin
      ExitCode := 1;
      Exit;
    end;
  Assets.SaveToFile(ArchiveName);
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
