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

  "$(PROJECTDIR)\post-build.bat" "$(OUTPUTDIR)\$(PROJECTNAME).exe"
    
*)

program resedit;

{$APPTYPE CONSOLE}

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  SysUtils,
  Classes,
  PJResFile in 'PJResFile.pas';

{$I MinPE.inc}

type
  TResource = (rtCursor, rtBitmap, rtIcon, rtMenu, rtDialog, rtString,
    rtFontDir, rtFont, rtAccelerator, rtRCData, rtMessageTable, rtGroupCursor,
    rtGroupIcon, rtVersion, rtDlgInclude, rtPlugPlay, rtVXD, rtAniCursor,
    rtAniIcon, rtHTML, rtManifest);

const
  {$IFDEF FPC}
    RT_DLGINCLUDE = MAKEINTRESOURCE(17);
    RT_PLUGPLAY = MAKEINTRESOURCE(19);
    RT_VXD = MAKEINTRESOURCE(20);
  {$ENDIF}

  RESOURCE_NAMES: array[TResource] of string = ('CURSOR', 'BITMAP', 'ICON',
    'MENU', 'DIALOG', 'STRING', 'FONTDIR', 'FONT', 'ACCELERATOR', 'RCDATA',
    'MESSAGETABLE', 'GROUPCURSOR', 'GROUPICON', 'VERSION', 'DLGINCLUDE',
    'PLUGPLAY', 'VXD', 'ANICURSOR', 'ANIICON', 'HTML', 'MANIFEST');

  RESOURCES: array[TResource] of PChar = (RT_CURSOR, RT_BITMAP, RT_ICON,
    RT_MENU, RT_DIALOG, RT_STRING, RT_FONTDIR, RT_FONT, RT_ACCELERATOR,
    RT_RCDATA, RT_MESSAGETABLE, RT_GROUP_CURSOR, RT_GROUP_ICON, RT_VERSION,
    RT_DLGINCLUDE, RT_PLUGPLAY, RT_VXD, RT_ANICURSOR, RT_ANIICON, RT_HTML,
    RT_MANIFEST);

var
  FileName: string;
  ResourceType: string;
  ResourceName: string;
  Language: Integer;
  SourceFileName: string;
  SourceResourceName: string;
  SourceLanguage: Integer;
  SourceData: TBytes;
  DeleteSource: Boolean;
  Success: Boolean;

procedure WriteManual;
begin
  {$IFDEF MSWINDOWS}
  Writeln('Updates resource in PE (*.exe, *.dll, etc) or resource (*.res) file.');
  {$ELSE}
  Writeln('Updates resource in *.res file.');
  {$ENDIF}
  Writeln('');
  Writeln('Usage:');
  Writeln('');
  Writeln('  resedit [options] destination type name[:language] [source [name[:language]]]');
  Writeln('');
  Writeln('  Options:');
  Writeln('');
  Writeln('    /D or -D    Deletes source file after update');
  Writeln('');
  Writeln('  Type:');
  Writeln('    cursor, bitmap, icon, menu, dialog, string, fontdir, font,');
  Writeln('    accelerator, rcdata, messagetable, groupcursor, groupicon,');
  Writeln('    version, dlginclude, plugplay, vxd, anicursor, aniicon,');
  Writeln('    html, manifest');
  Writeln('');
  Writeln('  Language:');
  Writeln('    0 - 65535 or \x0 - \xFFFF');
  Writeln('');
  {$IFDEF MSWINDOWS}
  Writeln('  If Language is omit then LCID checked for 0, UserLCID, and SystemLCID');
  {$ELSE}
  Writeln('  If Language is omit then LCID checked for 0');
  {$ENDIF}
end;

function StrToName(const Name: string): PChar;
var
  Value: Integer;
begin
  if Name = '' then
  begin
    Result := nil;
    Exit;
  end;

  if not TryStrToInt(Name, Value) then
  begin
    Result := PChar(Name);
    Exit;
  end;

  if (Value < 0) or (Value > $FFFF) then
  begin
    Result := PChar(Name);
    Exit;
  end;
  
  Result := PChar(Pointer(Value));
end;

function StrToType(const TypeName: string): PChar;
var
  Index: TResource;
begin
  if TypeName = '' then
  begin
    Result := nil;
    Exit;
  end;
  for Index := Low(RESOURCE_NAMES) to High(RESOURCE_NAMES) do
    if LowerCase(RESOURCE_NAMES[Index]) = LowerCase(Trim(TypeName)) then
    begin
      Result := RESOURCES[Index];
      Exit;
    end;

  Result := StrToName(TypeName);
end;

function TypeToStr(TypeValue: PChar): string;
var
  Resource: TResource;
  Value: Cardinal;
begin
  if not Assigned(TypeValue) then
  begin
    Result := '';
    Exit;
  end;

  for Resource := Low(TResource) to High(TResource) do
    if RESOURCES[Resource] = TypeValue then
    begin
      Result := RESOURCE_NAMES[Resource];
      Exit;
    end;

  Value := Cardinal(Pointer(TypeValue));
  if (Value > 0) and (Value < $FFFF) then
    Result := IntToStr(Value)
  else
    Result := TypeValue;
end;

function ParseLanguage(const Param: string; out Name: string;
  out Language: Integer; Default: Integer = -1): Boolean;
var
  Position: Integer;
  Value: Integer;
  ValueStr: string;
begin
  Result := False;
  if Param = '' then Exit;
  Position := Pos(':', Param);
  if Position > 0 then
  begin
    Name := Copy(Param, 1, Position - 1);
    ValueStr := Copy(Param, Position + 1, MaxInt);
    if LowerCase(Copy(ValueStr, 1, 2)) = '\x' then
    begin
      if not TryStrToInt('$' + Copy(ValueStr, 3, MaxInt), Value) then Exit;
    end else begin
      if not TryStrToInt(ValueStr, Value) then Exit;
    end;
    if (Value < 0) or (Value > $FFFF) then Exit;
    Language := Value;
  end else begin
    Name := Param;
    Language := Default;
  end;
  Result := True;
end;

function ParseParameters: Boolean;
var
  Index: Integer;
  Param, ParamLC: string;
  SourceResourcesProvided: Boolean;
begin
  SourceFileName := '';
  SourceResourcesProvided := False;
  for Index := 1 to ParamCount do
  begin
    Param := Trim(ParamStr(Index));
    if Param = '' then Continue;

    ParamLC := LowerCase(Param);
    if (ParamLC = '-?') or (ParamLC = '/?') or
      (ParamLC = '-h') or (ParamLC = '/h') or
      (ParamLC = '--help') or (ParamLC = '/help') or
      (ParamLC = '-help') then
    begin
      Result := False;
      Exit;
    end;

    if (ParamLC = '-d') or (ParamLC = '/d') then
    begin
      DeleteSource := True;
      Continue;
    end;

    if FileName = '' then
      FileName := Param
    else if ResourceType = '' then
      ResourceType := Param
    else if ResourceName = '' then
    begin
      if not ParseLanguage(Param, ResourceName, Language) then
      begin
        Result := False;
        Exit;
      end;
    end else if SourceFileName = '' then
      SourceFileName := Param
    else begin
      if not ParseLanguage(Param,
        SourceResourceName, SourceLanguage, Language) then
      begin
        Result := False;
        Exit;
      end;
      SourceResourcesProvided := True;
    end;
  end;

  if SourceFileName = '' then
  begin
    SourceResourceName := '';
    SourceLanguage := $FFFF;
  end else if not SourceResourcesProvided then
  begin
    SourceResourceName := ResourceName;
    SourceLanguage := Language;
  end;

  Result := (FileName <> '') and (ResourceType <> '') and (ResourceName <> '');
end;

function GetDataFromRes: Boolean;
var
  FileExt: string;
  ResourceFile: TPJResourceFile;
  ResourceEntry: TPJResourceEntry;
  Stream: TStream;
begin
  Result := False;
  FileExt := LowerCase(ExtractFileExt(SourceFileName));
  if (FileExt <> '.res')
    {$IFDEF MSWINDOWS}
      and (FileExt <> '.exe')
      and (FileExt <> '.dll')
    {$ENDIF} then
  begin
    Stream := nil;
    try
      Stream := TFileStream.Create(SourceFileName,
        fmOpenRead or fmShareDenyWrite);
      SetLength(SourceData, Stream.Size);

      if (Stream.Size > 0) and
        (Stream.Read(SourceData[0], Stream.Size) <> Stream.Size) then Exit;

      Result := True;
    finally
      Stream.Free;
    end;
  end else begin
    ResourceFile := TPJResourceFile.Create;
    try
      ResourceFile.LoadFromFile(SourceFileName);

      if SourceLanguage <> -1 then
        ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
          StrToName(SourceResourceName), Word(SourceLanguage))
      else begin
        ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
          StrToName(SourceResourceName));
        {$IFDEF MSWINDOWS}
        if not Assigned(ResourceEntry) then
        begin
          ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
            StrToName(SourceResourceName), GetUserDefaultLCID);
          if not Assigned(ResourceEntry) then
            ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
              StrToName(SourceResourceName), GetSystemDefaultLCID);
        end;
        {$ENDIF}
      end;

      if not Assigned(ResourceEntry) then Exit;

      SourceData := ResourceEntry.DataBytes;
      Result := True;
    finally
      ResourceFile.Free;
    end;
  end;
end;

{$IFDEF MSWINDOWS}
function GetDataFromPE: Boolean;
type
  LPVOID = Pointer;
const
  LOAD_LIBRARY_AS_IMAGE_RESOURCE = $20;
var
  Module: HMODULE;
  Resource: HRSRC;
  ResourceSize: DWORD;
  ResourceLoad: HGLOBAL;
  ResourceLock: LPVOID;
begin
  Result := False;

  Module := LoadLibraryEx(PChar(SourceFileName), 0,
    LOAD_LIBRARY_AS_IMAGE_RESOURCE or LOAD_LIBRARY_AS_DATAFILE);
  if Module = 0 then Exit;

  try
    if SourceLanguage = 0 then
      Resource := FindResource(Module, StrToName(SourceResourceName),
        StrToType(ResourceType))
    else if SourceLanguage <> -1 then
      Resource := FindResourceEx(Module, StrToType(ResourceType),
        StrToName(SourceResourceName), Word(SourceLanguage))
    else begin
      Resource := FindResourceEx(Module, StrToType(ResourceType),
        StrToName(SourceResourceName), 0);
      if Resource = 0 then
      begin
        Resource := FindResourceEx(Module, StrToType(ResourceType),
          StrToName(SourceResourceName), GetUserDefaultLCID);
        if Resource = 0 then
          Resource := FindResourceEx(Module, StrToType(ResourceType),
            StrToName(SourceResourceName), GetSystemDefaultLCID);
      end;
    end;

    if Resource = 0 then Exit;

    ResourceSize := SizeofResource(Module, Resource);
    if ResourceSize = 0 then Exit;

    ResourceLoad := LoadResource(Module, Resource);
    if ResourceLoad = 0 then Exit;

    ResourceLock := LockResource(ResourceLoad);
    if not Assigned(ResourceLock) then Exit;

    SetLength(SourceData, ResourceSize);
    Move(ResourceLock^, SourceData[0], ResourceSize);

    Result := True;
  finally
    if not FreeLibrary(Module) then
      Result := False;
  end;
end;
{$ENDIF}

procedure CreateEmptyResFile(const FileName: string);
const
  EMPTY_RES_FILE_CONTENT: array[0..31] of Byte = (
    $00, $00, $00, $00, $20, $00, $00, $00,
    $FF, $FF, $00, $00, $FF, $FF, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00
  );
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate or fmShareDenyNone);
  try
    Stream.Size := 0;
    Stream.Write(EMPTY_RES_FILE_CONTENT[0], Length(EMPTY_RES_FILE_CONTENT));
  finally
    Stream.Free;
  end;
end;

function UpdateDataInRes: Boolean;
var
  ResourceFile: TPJResourceFile;
  ResourceEntry: TPJResourceEntry;
begin
  ResourceFile := TPJResourceFile.Create;
  try
    ResourceFile.LoadFromFile(FileName);

    if Language <> -1 then
      ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
        StrToName(ResourceName), Word(Language))
    else begin
      ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
        StrToName(ResourceName));
      {$IFDEF MSWINDOWS}
      if not Assigned(ResourceEntry) then
      begin
        ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
          StrToName(ResourceName), GetUserDefaultLCID);
        if not Assigned(ResourceEntry) then
          ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
            StrToName(ResourceName), GetSystemDefaultLCID);
      end;
      {$ENDIF}
    end;

    if Assigned(ResourceEntry) then
      if not ResourceFile.DeleteEntry(ResourceEntry) then
      begin
        Result := False;
        Exit;
      end;

    if Assigned(SourceData) then
    begin
      if SourceLanguage <> -1 then
        ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
          StrToName(ResourceName), Word(SourceLanguage))
      else begin
        ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
          StrToName(ResourceName));
        {$IFDEF MSWINDOWS}
        if not Assigned(ResourceEntry) then
        begin
          ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
            StrToName(ResourceName), GetUserDefaultLCID);
          if not Assigned(ResourceEntry) then
            ResourceEntry := ResourceFile.FindEntry(StrToType(ResourceType),
              StrToName(ResourceName), GetSystemDefaultLCID)
        end;
        {$ENDIF}
      end;

      if not Assigned(ResourceEntry) then
      begin
        if SourceLanguage <> -1 then
          ResourceEntry := ResourceFile.AddEntry(StrToType(ResourceType),
            StrToName(ResourceName), Word(SourceLanguage))
        else
          ResourceEntry := ResourceFile.AddEntry(StrToType(ResourceType),
            StrToName(ResourceName));
      end;
      ResourceEntry.DataBytes := SourceData;
    end;

    ResourceFile.SaveToFile(FileName);
    Result := True;
  finally
    ResourceFile.Free;
  end;
end;

{$IFDEF MSWINDOWS}
function TryDeleteResource(const Language: Word): Boolean;
var
  Handle: THandle;
begin
  Result := True;

  Handle := BeginUpdateResource(PChar(FileName), False);
  if Handle = 0 then
  begin
    Result := False;
    Exit;
  end;

  try
    if not UpdateResource(Handle, StrToType(ResourceType),
      StrToName(ResourceName), Language, nil, 0) then
      begin
        Result := False;
        Exit;
      end;
  finally
    if not EndUpdateResource(Handle, not Result) then
      Result := False;
  end;
end;

function UpdateDataInPE: Boolean;
var
  Handle: THandle;
begin
  if Language <> -1 then
    Result := TryDeleteResource(Word(Language))
  else
    Result :=
      TryDeleteResource(0) or
      TryDeleteResource(GetUserDefaultLCID) or
      TryDeleteResource(GetSystemDefaultLCID);

  if not Result then Exit;

  if Assigned(SourceData) then
  begin
    Handle := BeginUpdateResource(PChar(FileName), False);
    if Handle = 0 then
    begin
      Result := False;
      Exit;
    end;

    try
      if SourceLanguage <> -1 then
        Result := UpdateResource(Handle, StrToType(ResourceType),
          StrToName(ResourceName), Word(SourceLanguage), SourceData,
          Length(SourceData))
      else
        Result := UpdateResource(Handle, StrToType(ResourceType),
          StrToName(ResourceName), 0, SourceData, Length(SourceData))
    finally
      if not EndUpdateResource(Handle, not Result) then
        Result := False;
    end;
  end;
end;
{$ENDIF}

begin
  {$IFDEF DEBUG} ReportMemoryLeaksOnShutdown := True; {$ENDIF}

  try
    if not ParseParameters then
    begin
      WriteManual;
      Exit;
    end;

    {$IFDEF DEBUG}
    Writeln(Format(
      'RESEDIT FileName="%s", ResourceType="%s", ResourceName="%s", ' +
      'Language="%d", SourceFileName="%s", SourceResourceName="%s", ' +
      'SourceLanguage="%d"',
      [FileName, ResourceType, ResourceName, Language,
        SourceFileName, SourceResourceName, SourceLanguage]));
    {$ENDIF}

    if SourceFileName <> '' then
    begin
      if not FileExists(SourceFileName) then
      begin
        Writeln(Format('Source file "%s" not found', [SourceFileName]));
        ExitCode := 1;
        Exit;
      end;

      {$IFDEF MSWINDOWS}
      if LowerCase(ExtractFileExt(SourceFileName)) = '.exe' then
        Success := GetDataFromPE
      else
      {$ENDIF}
        Success := GetDataFromRes;

      if not Success then
      begin
        if SourceLanguage <> -1 then
          Writeln(Format(
            'Unable to load %s resource "%s:\x%.4x" in file "%s"',
            [ResourceType, SourceResourceName, SourceLanguage, SourceFileName]))
        else
          Writeln(Format(
            'Unable to change %s resource "%s" in file "%s"',
            [ResourceType, SourceResourceName, SourceFileName]));
        ExitCode := 1;
        Exit;
      end;
    end else
      SourceData := nil;

    if not FileExists(FileName) and
      (LowerCase(ExtractFileExt(FileName)) = '.res') then
        CreateEmptyResFile(FileName);

    if not FileExists(FileName) then
    begin
      Writeln(Format('File "%s" not found', [FileName]));
      ExitCode := 1;
      Exit;
    end;

    {$IFDEF MSWINDOWS}
    if LowerCase(ExtractFileExt(FileName)) <> '.res' then
      Success := UpdateDataInPE
    else
    {$ENDIF}
      Success := UpdateDataInRes;

    if not Success then
    begin
      if Language <> -1 then
        Writeln(Format(
          'Unable to change %s resource "%s:\x%.4x" in file "%s"',
          [ResourceType, ResourceName, Language, FileName]))
      else
        Writeln(Format(
          'Unable to change %s resource "%s" in file "%s"',
          [ResourceType, ResourceName, FileName]));
      ExitCode := 1;
      Exit;
    end;

    if DeleteSource then
      if not DeleteFile(SourceFileName) then
      begin
        Writeln(Format('Unable to delete source file "%s"', [SourceFileName]));
        ExitCode := 1;
        Exit;
      end;

  except
    on E: Exception do
    begin
      Writeln(Format('%s: %s', [E.ClassName, E.Message]));
      ExitCode := 1;
    end;
  end;
end.
