unit uBuildEngine;

interface

{$I BuildEvents.inc}

uses
  Windows, Messages, SysUtils, Classes, Forms, Dialogs;

type
  EPipeError = class(Exception);
  EBuildEngineError = class(Exception);

  TBuildEngine = class(TObject)
  private
    FLastCmd: string;
    FLastOutput: string;
    FMacroList: TStringList;
    function GetMacroList: TStringList;
  protected
    function RunPipe(const psCommandLine, psWorkDir: string;
      const phInputHandle: THandle = 0): string; overload;
    function OpenInputFile(AFileName : String): THandle;
    procedure CloseInputFile(phHandle : THandle);
    function GetBuildMacroValue(const Name: string): string;
    function ExpandBuildMacros(const Params: string): string;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function Command(const Params: string): string; overload;
    function Command(const Params, RunDir: string): string; overload;
    function Command(const Params: string;
      InputData: TStrings): string; overload;
    function Command(const Params, RunDir: string;
      InputData: TStrings): string; overload;
    function Command(const AParams, ARunDir: string;
      AInputData: string): string; overload;

    procedure RefreshMacros;
    procedure AddMacro(AName, AValue: String);
    procedure EditMacro(AName, ANewName, AValue: String);
    procedure DeleteMacro(AName: String);

    property LastCmd : String read FLastCmd;
    property LastOutput : String read FLastOutput;
    property MacroList: TStringList read GetMacroList;
  end;

var
  BuildEngine: TBuildEngine;

implementation

uses
  Registry,
  {$IFDEF D6_UP} DateUtils, {$ENDIF}
  uBuildMisc,
  uBuildOptionExpert;

const
  BUFFER_SIZE = 4096;
  MAX_CMDLINE_SIZE = 32768;

{ TBuildEngine }
procedure TBuildEngine.CloseInputFile(phHandle: THandle);
begin
  CloseHandle(phHandle);
end;

constructor TBuildEngine.Create;
begin
  inherited Create;
  FLastCmd := '';
  FLastOutput := '';
end;

destructor TBuildEngine.Destroy;
begin
  FMacroList.Free;
  inherited Destroy;
end;

function TBuildEngine.RunPipe(const psCommandLine, psWorkDir: string;
  const phInputHandle: THandle): String;
var
  iError, iBytesRead, hReadHandle,
  hWriteHandle: Cardinal;
  Security: TSecurityAttributes;
  ProcInfo: TProcessInformation;
  Buf: PByte;
  StartupInfo: TStartupInfo;
  bDone: Boolean;
  iCounter: Integer;
  ACmdLine: array[0..MAX_CMDLINE_SIZE] of Char;
  AWorkDir: array[0..MAX_PATH] of Char;
  ErrorMessage, sComSpec: string;
begin
  Result := '';

  {$IFDEF D6_UP}
    sComSpec := Trim(GetEnvironmentVariable('COMSPEC'));
  {$ELSE}
    sComSpec := Trim(GetEnvVar('COMSPEC'));
  {$ENDIF}

  Security.lpSecurityDescriptor := nil;
  Security.bInheritHandle := true;
  Security.nLength := SizeOf(Security);

  if CreatePipe(hReadHandle, hWriteHandle, @Security, BUFFER_SIZE) then
  begin
    try
      { Startup Info for command process }
      with StartupInfo do
      begin
        lpReserved := nil;
        lpDesktop := nil;
        lpTitle := nil;
        dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
        cbReserved2 := 0;
        lpReserved2 := nil;
        { Prevent the command window being displayed }
        wShowWindow := SW_HIDE;
        { Standard Input - Default handle }
        if phInputHandle = 0 then
          hStdInput := GetStdHandle(STD_INPUT_HANDLE)
        else
          hStdInput := phInputHandle;
        { Standard Output - Point to Write end of pipe }
        hStdOutput := hWriteHandle;
        { Standard Error - Default handle }
        hStdError := GetStdHandle(STD_ERROR_HANDLE);
      end;

      StartupInfo.cb := SizeOf(StartupInfo);

      FillChar(ACmdLine[Low(ACmdLine)],
        Length(ACmdLine) * SizeOf(ACmdLine[Low(ACmdLine)]), 0);
      // 6 chars for '/C "' and '"#0'
      StrPCopy(ACmdLine,
        '/C "' + Copy(psCommandLine, 1, MAX_CMDLINE_SIZE - 6) + '"');

      FillChar(AWorkDir[Low(AWorkDir)],
        Length(AWorkDir) * SizeOf(AWorkDir[Low(AWorkDir)]), 0);
      StrPCopy(AWorkDir, Copy(psWorkDir, 1, MAX_CMDLINE_SIZE - 1));

      //BuildOptionExpert.LogLine(mtDebug, 'Executing: %s', [ACmdLine]);
      if CreateProcess(PAnsiChar(sComSpec), ACmdLine, nil, nil, True,
        CREATE_NEW_PROCESS_GROUP or NORMAL_PRIORITY_CLASS, nil, AWorkDir,
        StartupInfo, ProcInfo) then
      begin
        try
          { We don't need this handle any more, and keeping it open on this end
            will cause errors. It remains open for the child process though. }
          CloseHandle(hWriteHandle);
          { Allocate memory to the buffer }
          GetMem(Buf, BUFFER_SIZE * SizeOf(Char));
          try
            bDone := false;
            while not bDone do
            begin
              Application.ProcessMessages;
              if not Windows.ReadFile(hReadHandle, Buf^, BUFFER_SIZE,
                iBytesRead, nil) then
              begin
                iError := GetLastError;
                case iError of
                  ERROR_BROKEN_PIPE: // Broken pipe means client app has ended.
                    bDone := true;
                  ERROR_INVALID_HANDLE:
                    raise EPipeError.Create('Error: Invalid Handle');
                  ERROR_HANDLE_EOF:
                    raise EPipeError.Create('Error: End of file');
                  ERROR_IO_PENDING:
                    ; // Do nothing... just waiting
                  else
                    raise EPipeError.Create('Error: #' + IntToStr(iError));
                end;
              end;

              if iBytesRead > 0 then
              begin
                for iCounter := 0 to iBytesRead - 1 do
                  Result := Result + Char(PAnsiChar(Buf)[iCounter]);
              end;
            end;
          finally
            FreeMem(Buf, BUFFER_SIZE);
          end;
        finally
          CloseHandle(ProcInfo.hThread);
          CloseHandle(ProcInfo.hProcess);
        end
      end else
      begin
        ErrorMessage := GetLastWindowsError;
        CloseHandle(hWriteHandle);
        raise EPipeError.CreateFmt('Error: %s.'#13#10'(Command="%s")',
          [ErrorMessage, psCommandLine]);
      end;
    finally
      CloseHandle(hReadHandle);
    end;
  end;
end;

function TBuildEngine.OpenInputFile(AFileName: String): THandle;
var
  Security: TSecurityAttributes;
begin
  Security.lpSecurityDescriptor := nil;
  Security.bInheritHandle := true;
  Security.nLength := SizeOf(Security);

  Result := CreateFile(PChar(AFileName), GENERIC_READ, FILE_SHARE_READ,
    @Security, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
end;

function TBuildEngine.Command(const Params, RunDir: string): string;
begin
  FLastCmd := ExpandBuildMacros(Params);
  FLastOutput := RunPipe(FLastCmd, RunDir);
  Result := FLastOutput;
end;

function TBuildEngine.Command(const AParams, ARunDir: String;
  AInputData: String): String;
var
  slInput : TStringList;
begin
  slInput := TStringList.Create;
  try
    slInput.Text := AInputData;
    Result := Command(AParams, ARunDir, slInput);
    //BuildOptionExpert.LogMessages(mtDebug, slInput);
  finally
    slInput.Free;
  end;
end;

function TBuildEngine.Command(const Params, RunDir: string;
  InputData: TStrings): string;

  function GetTempFile: string;
  var
    PathName: array[0..MAX_PATH] of Char;
  begin
    Windows.GetTempPath(MAX_PATH, @PathName);
    Result := string(PathName);
    if AnsiLastChar(Result)^ <> '\' then
      Result := Result + '\';
    Result := Result +
      Format('build-output-%s.txt', [FormatDateTime('yyyy-mm-dd', Date)]);
  end;

var
  hInput : THandle;
begin
  Result := '';

  FLastCmd := ExpandBuildMacros(Params);

  InputData.SaveToFile(GetTempFile);
  try
    hInput := OpenInputFile(GetTempFile);
    try
      FLastOutput := RunPipe(FLastCmd, RunDir, hInput);
      Result := FLastOutput;
    finally
      CloseInputFile(hInput);
    end;
  finally
    DeleteFile(GetTempFile);
  end;
end;

function TBuildEngine.GetMacroList: TStringList;
begin
  if not Assigned(FMacroList) or (FMacroList.Count = 0) then
    FMacroList := GetBuildMacroList;
  Result := FMacroList;
end;

function TBuildEngine.GetBuildMacroValue(const Name: string): string;
begin
  Result := '';
  if Assigned(MacroList) then
    Result := MacroList.Values[Name];
end;

function TBuildEngine.ExpandBuildMacros(const Params: string): string;
var
  Index: Integer;
  Name, Value: string;
begin
  Result := Params;

  if not Assigned(MacroList) then Exit;

  for Index := 0 to MacroList.Count - 1 do
  begin
    Name := MacroList.Names[Index];
    {$IFDEF D7_UP}
      Value := MacroList.ValueFromIndex[Index];
    {$ELSE}
      Value := MacroList.Values[Name];
    {$ENDIF}
    Result := StringReplace(Result,
      Format('$(%s)', [Name]), Value, [rfReplaceAll]);
  end;
end;

procedure TBuildEngine.RefreshMacros;
begin
  if Assigned(FMacroList) then
    FMacroList.Clear;
  FMacroList := GetBuildMacroList;
end;

procedure TBuildEngine.AddMacro(AName, AValue: String);
begin
  MacroList.Add(Format('%s=%s', [AName, AValue]));
  AddCustomMacro(AName, AValue);
end;

procedure TBuildEngine.DeleteMacro(AName: String);
var
  Index: Integer;
begin
  Index := MacroList.IndexOfName(AName);
  if Index <> -1 then
    MacroList.Delete(Index);
  DeleteCustomMacro(AName);
end;

procedure TBuildEngine.EditMacro(AName, ANewName, AValue: String);
var
  Index: Integer;
begin
  Index := MacroList.IndexOfName(AName);
  if Index <> -1 then
    MacroList[Index] := Format('%s=%s', [ANewName, AValue])
  else
    MacroList.Add(Format('%s=%s', [ANewName, AValue]));

  { Update Registry item }
  EditCustomMacro(AName, ANewName, AValue);
end;

function TBuildEngine.Command(const Params: string): string;
begin
  Result := Command(Params, GetProjectPath);
end;

function TBuildEngine.Command(const Params: string; InputData: TStrings): string;
begin
  Result := Command(Params, GetProjectPath, InputData);
end;

initialization
  BuildEngine := TBuildEngine.Create;

finalization
  FreeAndNil(BuildEngine);

end.

