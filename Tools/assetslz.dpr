program assetslz;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  SynCommons,
  BoilerplateAssets in '..\BoilerplateAssets.pas';

procedure WriteManual;
begin
  Writeln('Creates SynLZ archive for further embedding as a RT_RCDATA resource');
  Writeln('');
  Writeln('Usage: assetslz path archive');
end;

var
  Path: string;
  ArchiveName: string;

function ParseParameters: Integer;
var
  Index: Integer;
  Param: string;
begin
  for Index := 1 to ParamCount do
  begin
    Param := SysUtils.LowerCase(SysUtils.Trim(ParamStr(Index)));

    if (Param = '-?') or (Param = '/?') or
      (Param = '-h') or (Param = '/h') or
      (Param = '/help') or (Param = '-help') then
      begin
        Result := 1;
        Exit;
      end;

    if Path = '' then
    begin
      Path := ExpandFileName(SysUtils.Trim(ParamStr(Index)));
      Path := IncludeTrailingPathDelimiter(Path);
    end else
      if ArchiveName = '' then
        ArchiveName := ExpandFileName(SysUtils.Trim(ParamStr(Index)))
      else begin
        Result := 1;
        Exit;
      end;
  end;

  if Path = '' then
  begin
    Result := 1;
    Exit;
  end else
    if not DirectoryExists(Path) then
    begin
      Writeln('Directory "' + Path + '" not found');
      Result := 2;
      Exit;
    end;

  Result := 0;
end;

procedure FindFiles(const DirName: string; var Files: TFileNameDynArray);
var
  F: TSearchRec;
begin
  if FindFirst(DirName + '*', faAnyFile, F) <> 0 then Exit;
  try
    repeat
      if F.Name[1] = '.' then Continue;
      if (F.Attr and faDirectory) > 0 then
        FindFiles(DirName + F.Name + PathDelim, Files)
      else begin
        SetLength(Files, Length(Files) + 1);
        Files[High(Files)] := DirName + F.Name;
      end;
    until FindNext(F) <> 0;
  finally
    FindClose(F);
  end;
end;

procedure CreateArchive;
var
  Index: Integer;
  Assets: TAssets;
  Files: TFileNameDynArray;
begin
  Assets.Init;
  FindFiles(Path, Files);
  for Index := Low(Files) to High(Files) do
    Assets.Add(Path, Files[Index]);
  Assets.CompressToFile(ArchiveName);
end;

begin
  try
    case ParseParameters of
      0: CreateArchive;
      1: WriteManual;
      2: ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
