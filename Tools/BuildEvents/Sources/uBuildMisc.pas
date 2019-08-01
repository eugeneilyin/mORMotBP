unit uBuildMisc;

interface

{$I BuildEvents.inc}

uses
  Classes,
  SysUtils,
  Windows,
  Forms,
  ShellAPI,
  Dialogs,
  StdCtrls,
  Buttons,
  ExtCtrls,
  Graphics,
  Controls,
  Menus,
  ToolsAPI,
  ActnList;

type

{ TAutoCloseMessage }

  TAutoCloseMessage = class
  private
    FForm: TForm;
    FInterval: Integer;
    FLabel: TLabel;
    FLabelTime: TLabel;
    FResult: Word;
    FTimer: TTimer;
    FTimeOut: Boolean;
    procedure DoOnDialogShow(Sender: TObject);
    procedure DoOnDialogClose(Sender: TObject; var Action: TCloseAction);
    procedure SetDefaultButton(AButtons: TMsgDlgButtons);
  protected
    procedure DoOnTimerTick(Sender: TObject);
    procedure FreeResources;
    procedure InitLabel(ASeconds: Integer);
    procedure InitTimer(ASeconds: Integer);
  public
    constructor Create(const AMessage: string; AType: TMsgDlgType;
      AButtons: TMsgDlgButtons; AHelpContext: Longint; ADefResult: Word;
      ASeconds: Integer = 10);
    destructor Destroy; override;

    function ResultStr(AIndex: Integer): string;
    function Execute: Word;
  end;

  TWaitOption = (woNoWait, woUntilStart, woUntilFinish);
  TPostBuildOption = (boAlways, boSuccess, boFailed, boNone);
  EatsWindowsError = class(Exception);

{ TBuildOptions }

  TBuildOptions = class(TObject)
  private
    FFileName: String;
    FShortcut: TShortcut;
    FPreBuildEvents: TStringList;
    FPostBuildEvents: TStringList;
    FPostBuildOption: TPostBuildOption;
    FShowMsg: Boolean;
    FFontSize: Integer;
    FFontName: String;
    FPreBuildEnabled: Boolean;
    FPostBuildEnabled: Boolean;
    FAutoSaveProject: Boolean;
    FAutoSaveInterval: Integer;
    procedure SetFileName(const Value: string);
    procedure SetPreBuildEvents(AValue: TStringList);
    procedure SetPostBuildEvents(AValue: TStringList);
    function GetFileName: String;
    function ConvertBuildEventStringToIniFormat(
      Strings: TStringList): string;
    procedure ConvertIniFormatStringToBuildEvent(const Text: String;
      var Strings: TStringList);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    { Methods }
    procedure LoadFromReg(psRegKey : String);
    procedure SaveToReg(psRegKey : String);
    procedure LoadProjectEvents(const NewFileName: string);
    procedure SaveProjectEvents(const FileCheck: Boolean = False);
    function CopyProjectEvents(const ASourceFile: string): Boolean;

    procedure SaveAll;
    procedure ClearEvents;
    procedure Reset;
    function ShowDialog(AFileName: String): Boolean;

    { IDE level Properties }
    property Shortcut : TShortcut read FShortcut write FShortcut;
    property FontSize: Integer read FFontSize Write FFontSize;
    property FontName: String read FFontName Write FFontName;
    property ShowMessages : Boolean read FShowMsg write FShowMsg;
    property AutoSaveInterval: Integer read FAutoSaveInterval
      write FAutoSaveInterval;

    { Project Properties }
    property AutoSaveProject: Boolean read FAutoSaveProject
      write FAutoSaveProject;
    property PreBuildEvents : TStringList read FPreBuildEvents
      write SetPreBuildEvents;
    property PostBuildEvents : TStringList read FPostBuildEvents
      write SetPostBuildEvents;
    property PostBuildOption: TPostBuildOption read FPostBuildOption
      write FPostBuildOption;

    property FileName: String read GetFileName
      write SetFileName;
    property PreBuildEnabled: Boolean read FPreBuildEnabled
      write FPreBuildEnabled;
    property PostBuildEnabled: Boolean read FPostBuildEnabled
      write FPostBuildEnabled;
  end;

function PosBack(psSearch, psSource : String):  Integer;
function PosFrom(psSearch, psSource : String; piStartPos : Integer) : Integer;
function GetLastWindowsError : String;
function RunProgram(psCmdLine : String;
  AWaitUntil : TWaitOption) : TProcessInformation;
function WildcardCompare(psWildCard, psCompare : String;
  pbCaseSens : Boolean = false) : Boolean;
function GetBuildMacroList: TStringList;
function StringContains(ASource: String; AStringArray: array of string;
  AIgnoreCase: Boolean = True): Boolean;
function ContainsString(ASource: String; AStringArray: array of string;
  AIgnoreCase: Boolean = True): Boolean;
function IfThen(ACondition: Boolean; ATrueValue, AFalseValue: Variant): Variant;
{$IFNDEF D6_UP}
function BoolToStr(ABoolean: Boolean; AUseBoolStrs: Boolean = False): string;
{$ENDIF}
function GetConfirmation(AMessage: String): Boolean; overload;
function GetConfirmation(const AFormat: string;
  AParams: array of const): Boolean; overload;
procedure SafeFreeAndNil(var AObject);
procedure ShowError(AMessage: String); overload;
procedure ShowError(const AFormat: string; AParams: array of const); overload;
procedure ShowInformation(ACaption, AMessage: String); overload;
procedure ShowInformation(AMessage: String); overload;
procedure ShowInformation(const AFormat: string; AParams: array of const); overload;
procedure ShowWarning(AMessage: String); overload;
procedure ShowWarning(const AFormat: string; AParams: array of const); overload;

procedure LogText(AText: String); overload;
procedure LogText(const AFormat: String; AParams: array of const); overload;
procedure LogException(AException: Exception; AMethod: String = '');

function GetDoneTimeStr(ATime: Double): String;
function GetDoneNowTimeStr(AStartTime: Double): String;

function ValidatePath(const Path: string): string;
function ValidateDir(const Dir: string): string;

{ Registry Methods }
procedure AddCustomMacro(AName, AValue: String);
procedure EditCustomMacro(AName, ANewName, AValue: String);
procedure DeleteCustomMacro(AName: String);
function GetCustomMacros: TStringList;

{ Open Tools Methods }
function GetProjectPath: string;
function ExecuteIDEAction(const ActionName: string): Boolean;
function FindIDEAction(const ActionName: string): TContainedAction;
function FindEditorContextPopupMenu: TPopupMenu;
function GetCurrentProject: IOTAProject;
function GetCurrentProjectFileName: string;
function GetCurrentProjectName: String;
function GetEnvVar(const AVarName: string): String;
function GetIDEMainMenu: TMainMenu;
function GetIDEMenuItem(AName: String): TMenuItem;
function GetProject: IOTAProject;
function GetProjectGroup: IOTAProjectGroup;
function GetProjectGroupFileName: string;
function GetProjectOption(const Name: string): string;
function GetActiveProjectOptions(
  AProject: IOTAProject = nil): IOTAProjectOptions;
function GetProjectOptionsNames(AOptions: IOTAOptions;
  AList: TStrings; AIncludeType: Boolean = False): Boolean;
function QuerySvcs(const Instance: IUnknown;
  const Intf: TGUID; out Inst): Boolean;

const
  C_DEFAULT_FONT_NAME = 'Tahoma';
  C_DEFAULT_FONT_SIZE = 8;
  C_CTRL_SHIFT_F12    = 24699;
  C_5_MINUTES         = 60000 * 5;

implementation

uses
  Registry,
  {$IFDEF D6_UP} Variants, {$ENDIF}
  IniFiles,
  uBuildOptionsForm;

const
  REG_KEY = '\Software\Kurapaty Solutions\Experts';
  REG_BUILD_OPTIONS = 'BuildOptions';
  REG_MACROS = 'Macros';
  MAX_BUFFER_SIZE = 255;
  MULTI_CHAR = ['*'];
  SINGLE_CHAR = ['?'];
  WILD_CARDS = MULTI_CHAR + SINGLE_CHAR;

{$IFNDEF D6_UP}
function BoolToStr(ABoolean: Boolean; AUseBoolStrs: Boolean = False): string;
const
  cSimpleBoolStrs: array [boolean] of String = ('No', 'Yes');
  cTrueFalseStr: array[Boolean] of String = ('False', 'True');
begin
  if AUseBoolStrs then
    Result := cTrueFalseStr[ABoolean]
  else
    Result := cSimpleBoolStrs[ABoolean];
end;
{$ENDIF}

function GetProjectPath: string;
begin
  Result := ValidatePath(ExtractFilePath(GetCurrentProjectFileName));
end;

procedure LogText(AText: String);
begin
  {$IFDEF DEBUG_ON}
  if (AText = EmptyStr) then Exit;
  OutputDebugString(PAnsiChar(FormatDateTime('[hh:nn:ss.zzz] ', Time) + AText));
  {$ENDIF}
end;

procedure LogText(const AFormat: String; AParams: array of const);
begin
  LogText(Format(AFormat, AParams));
end;

procedure LogException(AException: Exception; AMethod: String = '');
begin
  LogText('Exception: %s, occured in %s method', [AException.Message, AMethod]);
end;

function QuerySvcs(const Instance: IUnknown; const Intf: TGUID;
  out Inst): Boolean;
begin
  Result := (Instance <> nil) and Supports(Instance, Intf, Inst);
end;

function GetEnvVar(const AVarName: string): string;
{$IFNDEF D6_UP}
var
  nSize: DWORD;
{$ENDIF}
begin
{$IFDEF D6_UP}
  Result := GetEnvironmentVariable(AVarName);
{$ELSE}
  nSize := GetEnvironmentVariable(PChar(AVarName), @Result[1], 0);
  SetLength(Result, nSize);
  GetEnvironmentVariable(PChar(AVarName), @Result[1], nSize);
{$ENDIF}
  Result := Trim(Result);
end;

function GetProjectGroup: IOTAProjectGroup;
var
  IModuleServices: IOTAModuleServices;
  IModule: IOTAModule;
  i: Integer;
begin
  Result := nil;
  QuerySvcs(BorlandIDEServices, IOTAModuleServices, IModuleServices);
  if IModuleServices <> nil then
    for i := 0 to IModuleServices.ModuleCount - 1 do
    begin
      IModule := IModuleServices.Modules[i];
      if Supports(IModule, IOTAProjectGroup, Result) then
        Break;
    end;
end;

function GetActiveProjectOptions(AProject: IOTAProject = nil): IOTAProjectOptions;
begin
  Result := nil;
  if Assigned(AProject) then
  begin
    Result := AProject.ProjectOptions;
    Exit;
  end else
  begin
    AProject := GetCurrentProject;
    if Assigned(AProject) then
      Result := AProject.ProjectOptions;
  end;
end;

function GetProjectOptionsNames(AOptions: IOTAOptions; AList: TStrings;
  AIncludeType: Boolean = False): Boolean;
var
  Names: TOTAOptionNameArray;
  I: Integer;
begin
  Result := False;
  AList.Clear;
  Names := nil;
  if not Assigned(AOptions) then
    AOptions := GetActiveProjectOptions(nil);

  if not Assigned(AOptions) then Exit;

  Names := AOptions.GetOptionNames;
  try
    for I := Low(Names) to High(Names) do
      {if AIncludeType then  AList.Add(Names[i].Name + ': ' +
        GetEnumName(TypeInfo(TTypeKind), Ord(Names[i].Kind)))
      else}
        AList.Add(Names[i].Name + '=' +
          VarToStr(AOptions.Values[Names[I].Name]));
  finally
    Names := nil;
    Result := AList.Count > 0;
  end;
end;

function GetProjectGroupFileName: string;
var
  IModuleServices: IOTAModuleServices;
  IModule: IOTAModule;
  IProjectGroup: IOTAProjectGroup;
  i: Integer;
begin
  Result := '';
  IModuleServices := BorlandIDEServices as IOTAModuleServices;
  if IModuleServices = nil then Exit;

  IProjectGroup := nil;
  for i := 0 to IModuleServices.ModuleCount - 1 do
  begin
    IModule := IModuleServices.Modules[i];
    if IModule.QueryInterface(IOTAProjectGroup, IProjectGroup) = S_OK then
      Break;
  end;
  // Delphi 5 does not return the file path when querying IOTAProjectGroup
  // directly
  if IProjectGroup <> nil then
    Result := IModule.FileName;
end;

function GetCurrentProject: IOTAProject;
var
  IProjectGroup: IOTAProjectGroup;
begin
  Result := nil;

  IProjectGroup := GetProjectGroup;
  if not Assigned(IProjectGroup) then Exit;

  try
    // This raises exceptions in D5 with .bat projects active
    Result := IProjectGroup.ActiveProject;
  except
    Result := nil;
  end;
end;

function GetProject: IOTAProject;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  i: Integer;
begin
  Result := nil;
  QuerySvcs(BorlandIDEServices, IOTAModuleServices, ModuleServices);
  if ModuleServices <> nil then
    for i := 0 to ModuleServices.ModuleCount - 1 do
    begin
      Module := ModuleServices.Modules[i];
      if Supports(Module, IOTAProject, Result) then
        Break;
    end;

end;

function GetCurrentProjectFileName: string;
var
  IProject: IOTAProject;
begin
  Result := '';

  IProject := GetCurrentProject;
  if Assigned(IProject) then
  begin
    Result := IProject.FileName;
  end;
end;

function FindEditorContextPopupMenu: TPopupMenu;
var
  EditorServices: IOTAEditorServices;
begin
  Result := nil;

  EditorServices := BorlandIDEServices as IOTAEditorServices;
  if not Assigned(EditorServices) then Exit;
  if not Assigned(EditorServices.TopView) then Exit;
  if not Assigned(EditorServices.TopView.GetEditWindow) then Exit;
  if not Assigned(EditorServices.TopView.GetEditWindow.Form) then Exit;
  Result := (EditorServices.TopView.GetEditWindow.Form.FindComponent(
    'EditorLocalMenu') as TPopupMenu);
end;

function FindIDEAction(const ActionName: string): TContainedAction;
var
  Svcs: INTAServices;
  ActionList: TCustomActionList;
  i: Integer;
begin
  Result := nil;
  if ActionName = '' then Exit;

  QuerySvcs(BorlandIDEServices, INTAServices, Svcs);
  ActionList := Svcs.ActionList;
  for i := 0 to ActionList.ActionCount - 1 do
    if SameText(ActionList.Actions[i].Name, ActionName) then
    begin
      Result := ActionList.Actions[i];
      Exit;
    end;
end;

function ExecuteIDEAction(const ActionName: string): Boolean;
var
  Action: TContainedAction;
begin
  Action := FindIDEAction(ActionName);
  if Assigned(Action) then
    Result := Action.Execute
  else
    Result := False;
end;

function GetIDEMainMenu: TMainMenu;
var
  Svcs40: INTAServices40;
begin
  QuerySvcs(BorlandIDEServices, INTAServices40, Svcs40);
  Result := Svcs40.MainMenu;
end;

// Usage: GetIDEMenuItem('Tools')
function GetIDEMenuItem(AName: String): TMenuItem;
var
  MainMenu: TMainMenu;
  i: Integer;
begin
  Result := nil;
  MainMenu := GetIDEMainMenu;
  if MainMenu <> nil then
  begin
    for i := 0 to MainMenu.Items.Count - 1 do
      if AnsiCompareText(AName, MainMenu.Items[i].Name) = 0 then
      begin
        Result := MainMenu.Items[i];
        Exit;
      end
  end;
end;

function GetCurrentProjectName: String;
var
  activeProject: IOTAProject;
begin
  Result := '';
  activeProject := GetCurrentProject;
  if Assigned(activeProject) then
  begin
    Result := ExtractFileName(activeProject.FileName);
    Result := ChangeFileExt(Result, '');
  end;
end;

procedure SafeFreeAndNil(var AObject);
begin
  try
    if Assigned(Pointer(AObject)) then
      FreeAndNil(AObject);
  except end;
end;

function ValidatePath(const Path: string): string;
begin
  Result := Trim(Path);

  {$IFDEF D6_UP}
    Result := ExcludeTrailingPathDelimiter(Result);
    Result := IncludeTrailingPathDelimiter(Result);
  {$ELSE}
    Result := ExcludeTrailingBackslash(Result);
    Result := IncludeTrailingBackslash(Result);
  {$ENDIF}

  Result := StringReplace(Result, '\\', '\', [rfReplaceAll]);
end;

function ValidateDir(const Dir: string): string;
begin
  Result := ValidatePath(Dir);
  Result :=
    {$IFDEF D6_UP}
      ExcludeTrailingPathDelimiter(Result);
    {$ELSE}
      ExcludeTrailingBackslash(Result);
    {$ENDIF}
end;

function GetProjectOption(const Name: string): string;
var
  IProject: IOTAProject;
  IProjectOptions: IOTAProjectOptions;
begin
  Result := '';

  IProject := GetCurrentProject;
  if not Assigned(IProject) then Exit;

  IProjectOptions := IProject.ProjectOptions;
  if not Assigned(IProjectOptions) then Exit;

  Result := VarToStr(IProjectOptions.Values[Name]);
end;

function GetProjectFileName: string;
var
  IProject: IOTAProject;
begin
  IProject := GetCurrentProject;
  if Assigned(IProject) then
    Result := IProject.FileName
  else
    Result := '';
end;

function GetBuildMacroList: TStringList;
var
  Value: string;
begin
  Result := GetCustomMacros;

  Value := ValidateDir(GetEnvVar('BDS'));
  if Value = '' then
  begin
    Value := ValidateDir(ExtractFileDir(ParamStr(0)));
    if LowerCase(Copy(Value, Length(Value) - 3, 4)) = '\bin' then
      Delete(Value, Length(Value) - 3, 4);
  end;
  Result.Add(Format('BDS=%s', [Value]));

  Result.Add(Format('DEFINES=%s', [GetProjectOption('Defines')]));
  Result.Add(Format('DIR=%s', [GetEnvVar('DIR')]));

//  Result.Add('INCLUDEPATH={The project''s include path}'); // GetProjectOption('IncludePath')

//  Result.Add('INPUTDIR={The input file''s directory}');
//  Result.Add('INPUTEXT={The input file''s extension}');
//  Result.Add('INPUTFILENAME={The input file''s name, with extension}');
//  Result.Add('INPUTNAME={The input file''s name, without extension}');
//  Result.Add('INPUTPATH={The input file''s full path}');

//  Result.Add('LOCALCOMMAND={Local command entered by user in project manager}');

  Result.Add(Format('OUTPUTDIR=%s', [GetProjectOption('OutputDir')]));
//  Result.Add('OUTPUTEXT={The output file''s extension}');
//  Result.Add('OUTPUTFILENAME={The output file''s name, with extension}');
//  Result.Add('OUTPUTNAME={The output file''s name, without extension}');
//  Result.Add('OUTPUTPATH={The output file''s full path}');

  Result.Add(Format('Path=%s', [GetEnvVar('Path')]));

  Value := GetProjectFileName;
  Result.Add(Format('PROJECTDIR=%s', [ValidateDir(ExtractFileDir(Value))]));
  Result.Add(Format('PROJECTEXT=%s', [ExtractFileExt(Value)]));
  Result.Add(Format('PROJECTFILENAME=%s', [ExtractFileName(Value)]));
  Result.Add(Format('PROJECTNAME=%s', [Copy(ExtractFileName(Value), 1,
    Length(ExtractFileName(Value)) - Length(ExtractFileExt(Value)))]));
  Result.Add(Format('PROJECTPATH=%s', [Value]));

  Result.Add(Format('SystemRoot=%s', [GetEnvVar('SystemRoot')]));

  Value := ValidateDir(GetEnvVar('TEMP'));
  if Value = '' then
    Value := ValidateDir(GetEnvVar('TMP'));
  Result.Add(Format('TEMPDIR=%s', [Value]));

  Result.Add(Format('UNITOUTPUTDIR=%s', [GetProjectOption('UnitOutputDir')]));
  Result.Add(Format('WINDIR=%s', [GetEnvVar('WINDIR')]));
end;

function IfThen(ACondition: Boolean; ATrueValue, AFalseValue: Variant): Variant;
begin
  if ACondition then
    Result := ATrueValue
  else
    Result := AFalseValue;
end;

procedure AddCustomMacro(AName, AValue: String);
begin
  with TRegIniFile.Create(REG_KEY) do
  try
    WriteString(REG_MACROS, AName, AValue);
  finally
    Free;
  end;
end;

procedure EditCustomMacro(AName, ANewName, AValue: String);
begin
  with TRegIniFile.Create(REG_KEY) do
  try
    DeleteKey(REG_MACROS, AName);
    WriteString(REG_MACROS, ANewName, AValue);
  finally
    Free;
  end;
end;

procedure DeleteCustomMacro(AName: String);
begin
  with TRegIniFile.Create(REG_KEY) do
  try
    DeleteKey(REG_MACROS, AName);
  finally
    Free;
  end;
end;

function GetCustomMacros: TStringList;
begin
  Result := TStringList.Create;

  with TRegIniFile.Create(REG_KEY) do
  try
    { Custom Macros }
    ReadSectionValues(REG_MACROS, Result);
  finally
    Free;
  end;
end;

function StringContains(ASource: String; AStringArray: array of string;
  AIgnoreCase: Boolean = True): Boolean;
var
  Loop: Integer;
begin
  Result := False;
  for Loop := Low(AStringArray) to High(AStringArray) do
  begin
    Result := IfThen(AIgnoreCase,
      (0 = CompareText(ASource, AStringArray[Loop])),
      (ASource = AStringArray[Loop]));
    if Result then Break;
  end;
end;

function ContainsString(ASource: String; AStringArray: array of string;
  AIgnoreCase: Boolean = True): Boolean;
var
  Loop: Integer;
begin
  Result := False;
  if AIgnoreCase then
  begin
    ASource := LowerCase(ASource);
    for Loop := Low(AStringArray) to High(AStringArray) do
      AStringArray[Loop] := LowerCase(AStringArray[Loop]);
  end;

  for Loop := Low(AStringArray) to High(AStringArray) do
  begin
    Result := (Pos(AStringArray[Loop], ASource) > 0);
    if Result then Break;
  end;
end;

function GetDoneTimeStr(ATime: Double): String;
begin
  if (ATime * 24 * 60 > 1) then
    Result := FormatDateTime('hh:nn:ss', ATime) //'done' time is more than 1 min
  else
    Result := Format('%f ms.', [ATime * 24 * 60 * 60 * 60]);
end;

function GetDoneNowTimeStr(AStartTime: Double): String;
begin
  Result := GetDoneTimeStr(Now - AStartTime);
end;

function PosBack(psSearch, psSource:  String):  Integer;
var
  blnFound  :  Boolean;
begin
  Result := Length(psSource) - Length(psSearch) + 1;
  blnFound := false;
  while (Result > 0) and (not blnFound) do
    begin
      if psSearch = Copy(psSource, Result, Length(psSearch)) then
        blnFound := true
      else
        Result := Result - Length(psSearch);
    end;
  if Result < 0 then
    Result := 0;
end;

function PosFrom(psSearch, psSource:  String; piStartPos: Integer): Integer;
begin
  Dec(piStartPos);
  if piStartPos < 0 then
    piStartPos := 0;
  Delete(psSource, 1, piStartPos);
  Result := Pos(psSearch, psSource);
  if Result > 0 then
    Result := piStartPos + Result;
end;

function GetLastWindowsError : String;
var
  dwrdError          :  DWord;
  pchrBuffer         :  PChar;
begin
  dwrdError := GetLastError;
  GetMem(pchrBuffer, MAX_BUFFER_SIZE);
  try
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, dwrdError, 0, pchrBuffer,
      MAX_BUFFER_SIZE, nil);
    Result := String(pchrBuffer);
  finally
    FreeMem(pchrBuffer, MAX_BUFFER_SIZE);
  end;
end;

function RunProgram(psCmdLine: String;
  AWaitUntil: TWaitOption): TProcessInformation;
var
  sErrorMsg,
  sCmdLine       :  String;
  StartInfo      :  TStartupInfo;
  iExitCode      :  Cardinal;
begin
  sCmdLine := psCmdLine + #0;

  with StartInfo do
  begin
    lpReserved := nil;
    lpDesktop := nil;
    lpTitle := nil;
    dwFlags := 0;
    cbReserved2 := 0;
    lpReserved2 := nil;
  end;

  StartInfo.cb := SizeOf(StartInfo);

  if CreateProcess(nil, PChar(sCmdLine), nil, nil, true, 0, nil, nil,
    StartInfo, Result) then
  begin
    if AWaitUntil in [woUntilStart, woUntilFinish] then
      WaitForInputIdle(Result.hProcess, INFINITE);

    if (AWaitUntil = woUntilFinish) then
      repeat
        Application.ProcessMessages;
        GetExitCodeProcess(Result.hProcess, iExitCode);
      until iExitCode <> STILL_ACTIVE;
  end else
  begin
    sErrorMsg := GetLastWindowsError;
    raise EatsWindowsError.Create(sErrorMsg);
  end;
end;   { RunProgram }

function WildcardCompare(psWildCard, psCompare : String;
  pbCaseSens : Boolean) : Boolean;
var
  strlstWild : TStringList;
  intPos,
  intStart,
  intCounter : Integer;
  strWork    : String;
  blnAtStart : Boolean;
begin
  { If it's not case sensitive, convert both strings to all uppercase. }
  if not pbCaseSens then
  begin
    psWildCard := UpperCase(psWildCard);
    psCompare := UpperCase(psCompare);
  end;

  { If either string is empty, return false immediately. }
  if (psWildCard = '') or (psCompare = '') then
  begin
    Result := false;
    Exit;
  end;

  strlstWild := TStringList.Create;
  try
    { ----------------------------------------------------------------------- }
    { First, we split the wildcard string up into sections - text vs wild
      cards with a line in a string list for each.

      So, the wildcard "abc*def?ghi" would be broken up into a string list
      like this:
             abc
             *
             def
             ?
             ghi

      }
    intStart := 1;
    for intCounter := 1 to Length(psWildCard) do
    begin
      {$IFDEF UNICODE}
      if CharInSet(psWildCard[intCounter], WILD_CARDS) then
      {$ELSE}
      if psWildCard[intCounter] in WILD_CARDS then
      {$ENDIF}
       begin
         if intStart < intCounter then
         begin
           strWork := Copy(psWildCard, intStart, intCounter - intStart);
           strlstWild.Add(strWork);
         end;
         strlstWild.Add(psWildCard[intCounter]);
         intStart := intCounter + 1;
       end;
    end;
    { If there's still some characters left over after the last wildcard has been found,
      add them to the end of the string list. This is for wildcard strings like "*bob". }
    if intStart <= Length(psWildCard) then
    begin
      strWork := Copy(psWildCard, intStart, Length(psWildCard));
      strlstWild.Add(strWork);
    end;

    Result := true;
    blnAtStart := true;
    intStart := 1;
    intCounter := 0;
    while (intCounter < strlstWild.Count) and Result do
    begin
      strWork := strlstWild[intCounter];
      {$IFDEF UNICODE}
      if (Length(strWork) = 1) and (CharInSet(strWork[1], WILD_CARDS)) then
      {$ELSE}
      if (Length(strWork) = 1) and (strWork[1] in WILD_CARDS) then
      {$ENDIF}
      begin
        {$IFDEF UNICODE}
        if CharInSet(strWork[1], MULTI_CHAR) then
        {$ELSE}
        if strWork[1] in MULTI_CHAR then
        {$ENDIF}
           { A multi-character wildcard (eg "*") }
           blnAtStart := false
        else
        begin
          { A single-character wildcard (eg "?") }
          blnAtStart := true;
          if intStart > Length(psCompare) then
            Result := false;
          Inc(intStart);
        end;
      end else
      begin
        if blnAtStart then
        begin
          { Text after a "?" }
          if Copy(psCompare, intStart, Length(strWork)) = strWork then
            intStart := intStart + Length(strWork)
          else
            Result := false;
        end else
        begin
          { Text after a "*" }
          if intCounter = strlstWild.Count - 1 then
            intPos := PosBack(strWork, psCompare)
          else
            intPos := PosFrom(strWork, psCompare, intStart);
          if intPos > 0 then
            intStart := intPos + Length(strWork)
          else
            Result := false;
         end;

        blnAtStart := true;
      end;
      Inc(intCounter);
    end;
    if Result and (blnAtStart) and (intStart <= Length(psCompare)) then
      Result := false;
  finally
    strlstWild.Free;
  end;
end;

function MessageDlgEx(const AMessage: string; AType: TMsgDlgType;
  AButtons: TMsgDlgButtons; AHelpContext: Longint; ADefResult: Word;
  ASeconds: Integer = 10): Word;
begin
  with TAutoCloseMessage.Create(AMessage, AType, AButtons, AHelpContext,
    ADefResult, ASeconds) do
  try
    Result := Execute;
  finally
    Free;
  end;
end;

procedure ShowError(AMessage: String);
begin
  MessageDlgEx(AMessage, mtError, [mbOk], 0, IDOK);
end;

procedure ShowError(const AFormat: string; AParams: array of const);
begin
  ShowError(Format(AFormat, AParams));
end;

procedure ShowWarning(AMessage: String);
begin
  MessageDlgEx(AMessage, mtWarning, [mbOK], 0, IDOK);
end;

procedure ShowWarning(const AFormat: string; AParams: array of const);
begin
  ShowError(Format(AFormat, AParams));
end;

procedure ShowInformation(ACaption, AMessage: String);
begin
  MessageBox(0, PAnsiChar(AMessage), PAnsiChar(ACaption),
    MB_OK or MB_ICONEXCLAMATION);
end;

procedure ShowInformation(AMessage: String);
begin
  MessageDlgEx(AMessage, mtInformation, [mbOK], 0, IDOK);
end;

procedure ShowInformation(const AFormat: string; AParams: array of const);
begin
  ShowInformation(Format(AFormat, AParams));
end;

function GetConfirmation(AMessage: String): Boolean;
begin
  Result :=
    MessageDlgEx(AMessage, mtConfirmation, [mbYes, mbNo], 0, IDNO) = IDYES;
end;

function GetConfirmation(const AFormat: string;
  AParams: array of const): Boolean;
begin
  Result := GetConfirmation(Format(AFormat, AParams));
end;

{ TAutoCloseMessage }

constructor TAutoCloseMessage.Create(const AMessage: string; AType: TMsgDlgType;
  AButtons: TMsgDlgButtons; AHelpContext: Longint; ADefResult: Word;
  ASeconds: Integer = 10);
begin
  inherited Create;
  FForm := CreateMessageDialog(AMessage, AType, AButtons);
  FForm.HelpContext := AHelpContext;
  FForm.OnShow := DoOnDialogShow;
  FForm.OnClose := DoOnDialogClose;
  FResult := ADefResult;
  FInterval := ASeconds;
  FTimeOut := False;
  SetDefaultButton(AButtons);
  if (ASeconds > 0) then
  begin
    InitLabel(ASeconds);
    InitTimer(ASeconds);
  end;
end;

destructor TAutoCloseMessage.Destroy;
begin
  FreeResources;
  inherited;
end;

procedure TAutoCloseMessage.DoOnTimerTick(Sender: TObject);
begin
  Dec(FInterval);
  FLabelTime.Caption := Format('%.2d', [FInterval]);
  FLabelTime.Refresh;

  if (FInterval <= 0) then
  begin
    (Sender as TTimer).Enabled := False;
    FTimeOut := True;
    FForm.ModalResult := FResult;
    FForm.Close;
  end;
end;

procedure TAutoCloseMessage.InitLabel(ASeconds: Integer);
begin
  FLabel:= TLabel.Create(FForm);
  FLabel.Parent := FForm;
  FLabel.Caption := 'This window will automatically close in 00 sec';
  FLabel.Font.Size := C_DEFAULT_FONT_SIZE;
  FLabel.Font.Color := clNavy;
  FLabel.Font.Style := [fsItalic];
  FLabel.Left := 6;
  FLabel.Top := FForm.ClientHeight - 16;

  FLabelTime:= TLabel.Create(FForm);
  FLabelTime.Parent := FForm;
  FLabelTime.Caption := Format('%.2d', [FInterval]);
  FLabelTime.Font.Size := C_DEFAULT_FONT_SIZE;
  FLabelTime.Font.Style := [fsItalic];
  FLabelTime.Left := FLabel.Left + FLabel.Width - 29;
  FLabelTime.Top := FLabel.Top;

  if (FForm.Width < 260) then FForm.Width := 260;
  FLabel.Visible := True;
  FLabelTime.Visible := True;
end;

procedure TAutoCloseMessage.InitTimer(ASeconds: Integer);
begin
  FTimer := TTimer.Create(FForm);
  FTimer.Interval := 1000;
  FTimer.OnTimer := DoOnTimerTick;
  FTimer.Enabled := True;
end;

function TAutoCloseMessage.ResultStr(AIndex: Integer): String;
const
  CReturnStr: array[0..10] of string = ('mrNone', 'mrOk', 'mrCancel', 'mrAbort',
    'mrRetry', 'mrIgnore', 'mrYes', 'mrNo', 'mrAll', 'mrNoToAll', 'mrYesToAll');
begin
  if (AIndex in [Low(CReturnStr).. High(CReturnStr)]) then
    Result := CReturnStr[AIndex]
  else
    Result := 'Unknown';
end;

procedure TAutoCloseMessage.SetDefaultButton(AButtons: TMsgDlgButtons);
var
  I: Integer;
begin
  if Assigned(FForm) then
  begin
    if (FResult = mrNone) then
    begin
      if (AButtons = mbOkCancel) then FResult := mrCancel;
    	 if (AButtons = mbYesNoCancel) then FResult := mrNo;
      if (AButtons = mbAbortRetryIgnore) then FResult := mrIgnore;
    end;

    for I := 0 to FForm.ComponentCount -1 do
    begin
      if (FForm.Components[I] is TButton) then
      begin
        //with FForm.Components[I] as TButton do ShowMessageFmt(
        //  '%s - %d - Default: %s', [Caption, ModalResult, ResultStr(FResult)]);

        if (TButton(FForm.Components[I]).ModalResult = FResult) then
        begin
          FForm.ActiveControl := TButton(FForm.Components[I]);
          Exit;
        end;
      end;
    end;
  end;
end;

procedure TAutoCloseMessage.DoOnDialogShow(Sender: TObject);
begin
  if Assigned(FForm) then
    AnimateWindow(FForm.Handle, 200, AW_CENTER or AW_ACTIVATE);
end;

procedure TAutoCloseMessage.DoOnDialogClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if Assigned(FForm) then
    AnimateWindow(FForm.Handle, 200, AW_CENTER or AW_HIDE);
end;

procedure TAutoCloseMessage.FreeResources;
begin
  SafeFreeAndNil(FTimer);
  SafeFreeAndNil(FLabelTime);
  SafeFreeAndNil(FLabel);
  SafeFreeAndNil(FForm);
end;

function TAutoCloseMessage.Execute: Word;
begin
 if Assigned(FForm) then
 begin
   FForm.ShowModal;
   if (FTimeOut) then
     Result := FResult
   else
     Result := FForm.ModalResult;
 end else
   Result := FResult;
end;

{ TBuildOptions }

constructor TBuildOptions.Create;
begin
  inherited Create;
  FShowMsg := True;
  FFontName := C_DEFAULT_FONT_NAME;
  FFontSize := C_DEFAULT_FONT_SIZE;
  FShortcut := C_CTRL_SHIFT_F12;
  FAutoSaveInterval := C_5_MINUTES;
  FAutoSaveProject := False;
  FPreBuildEnabled := False;
  FPostBuildEnabled := False;
  FPreBuildEvents := TStringList.Create;
  FPostBuildEvents := TStringList.Create;
  LoadFromReg(REG_KEY);
end;

destructor TBuildOptions.Destroy;
begin
  FPreBuildEvents.Free;
  FPostBuildEvents.Free;
  inherited;   
end;

procedure TBuildOptions.LoadFromReg(psRegKey: String);
begin
  with TRegIniFile.Create(psRegKey) do
  try
    { Shortcuts }
    FShortcut := ReadInteger(REG_BUILD_OPTIONS, 'Shortcut', FShortcut);
    FShowMsg  := ReadBool(REG_BUILD_OPTIONS, 'Show Messages', FShowMsg);
    FFontSize := ReadInteger(REG_BUILD_OPTIONS, 'Font Size', FFontSize);
    FFontName := ReadString(REG_BUILD_OPTIONS, 'Font Name', FFontName);
    FAutoSaveInterval := ReadInteger(REG_BUILD_OPTIONS, 'Interval',
      FAutoSaveInterval);
  finally
    Free;
  end;
end;

procedure TBuildOptions.SaveToReg(psRegKey: String);
begin
  with TRegIniFile.Create(psRegKey) do
  try
    WriteInteger(REG_BUILD_OPTIONS, 'Shortcut', FShortcut);
    WriteBool(REG_BUILD_OPTIONS, 'Show Messages', FShowMsg);
    WriteInteger(REG_BUILD_OPTIONS, 'Font Size', FFontSize);
    WriteString(REG_BUILD_OPTIONS, 'Font Name', FFontName);
    WriteInteger(REG_BUILD_OPTIONS, 'Interval', FAutoSaveInterval);
  finally
    Free;
  end;
end;

function TBuildOptions.ConvertBuildEventStringToIniFormat(
  Strings: TStringList): string;
var
  Index: Integer;
begin
  Result := '';
  for Index := 0 to Strings.Count - 1 do
    if Result = '' then
      Result := Trim(Strings[Index])
    else
      Result := Result + '|' + Trim(Strings[Index]);
end;

procedure TBuildOptions.ConvertIniFormatStringToBuildEvent(const Text: string;
  var Strings: TStringList);
begin
  Strings.Clear;
  Strings.Text := StringReplace(Text, '|', #$D#$A, [rfReplaceAll]);
end;

function TBuildOptions.CopyProjectEvents(const ASourceFile: string): Boolean;
begin
  LogText('TBuildOptions.CopyProjectEvents(ASourceFile: %s)', [ASourceFile]);
  Result := False;
  if FileExists(ASourceFile) then
  begin
    ClearEvents;
    with TIniFile.Create(ASourceFile) do
    begin
      try
        ConvertIniFormatStringToBuildEvent(Trim(ReadString(
          'Build Events', 'PreBuild', '')), FPreBuildEvents);
        ConvertIniFormatStringToBuildEvent(Trim(ReadString(
          'Build Events', 'PostBuild', '')), FPostBuildEvents);
        PostBuildOption := TPostBuildOption(ReadInteger(
          'Build Events', 'BuildEvent', 0));
        PreBuildEnabled := ReadBool('Build Events', 'PreBuildEnabled', False);
        PostBuildEnabled:= ReadBool('Build Events', 'PostBuildEnabled', False);
        AutoSaveProject := ReadBool('Build Events', 'AutoSave', False);
        LogText('%s - Loaded', [ASourceFile]);
        Result := True;
      finally
        Free;
      end;
    end;
  end;
  LogText('TBuildOptions.CopyProjectEvents(ASourceFile: %s)', [ASourceFile]);
end;

procedure TBuildOptions.LoadProjectEvents(const NewFileName: string);
begin
  LogText('TBuildOptions.LoadProjectEvents(FileName: %s, NewFileName: %s)',
    [FileName, NewFileName]);
  ClearEvents;
  FileName := NewFileName;
  CopyProjectEvents(FileName);
  LogText('TBuildOptions.LoadProjectEvents(NewFileName: %s)', [FileName]);
end;

procedure TBuildOptions.SaveProjectEvents(const FileCheck: Boolean);
begin
  LogText('TBuildOptionExpert.SaveProjectEvents (FileCheck: %s)',
    [BoolToStr(FileCheck, True)]);
  if FileName <> '' then
  begin
    if FileCheck then
      if not FileExists(FileName) then
      begin
        LogText('%s - File Not Found!', [FileName]);
        Exit;
      end;

    with TIniFile.Create(FileName) do
      try
        WriteString('Build Events', 'PreBuild',
          '"' + ConvertBuildEventStringToIniFormat(PreBuildEvents) + '"');
        WriteString('Build Events', 'PostBuild',
          '"' + ConvertBuildEventStringToIniFormat(PostBuildEvents) + '"');
        WriteInteger('Build Events', 'BuildEvent', Integer(PostBuildOption));
        WriteBool('Build Events', 'PreBuildEnabled', PreBuildEnabled);
        WriteBool('Build Events', 'PostBuildEnabled', PostBuildEnabled);
        WriteBool('Build Events', 'AutoSave', AutoSaveProject);
        LogText('%s - File Saved', [FileName]);
      finally
        Free;
      end;
  end;
  LogText('TBuildOptionExpert.SaveProjectEvents (FileCheck: %s)',
    [BoolToStr(FileCheck, True)]);
end;

function TBuildOptions.ShowDialog(AFileName: String): Boolean;
begin
  with TBuildOptionsForm.Create(Application) do
  begin
    try
      LoadProjectEvents(AFileName);
      Result := Execute(Self);
      if Result then
        SaveAll;
    finally
      Free;
    end;
  end;
end;

procedure TBuildOptions.SetFileName(const Value: string);
var
  FileExt: string;
begin
  LogText('In - TBuildOptions.SetFileName: Value=%s, FileName=%s',
    [FFileName, Value]);
  if FFileName <> Value then
  begin
    FileExt := LowerCase(ExtractFileExt(Value));
    if FileExt <> '.ini' then
      FFileName := ChangeFileExt(Value, '.ini')
    else
      FFileName := Value;
  end;
  LogText('Out - TBuildOptions.SetFileName: Value=%s, FileName=%s',
    [FFileName, Value]);
end;

procedure TBuildOptions.SaveAll;
begin
  LogText('In - TBuildOptions.SaveAll');
  SaveToReg(REG_KEY);
  SaveProjectEvents;
  LogText('Out - TBuildOptions.SaveAll');
end;

procedure TBuildOptions.ClearEvents;
begin
  LogText('In - TBuildOptions.ClearEvents');
  FPreBuildEvents.Clear;
  FPostBuildEvents.Clear;
  FPostBuildOption := boNone;
  FPreBuildEnabled := False;
  FPostBuildEnabled := False;
  FAutoSaveProject := False;
  LogText('Out - TBuildOptions.ClearEvents');
end;

function TBuildOptions.GetFileName: String;
begin
  Result := EmptyStr;
  if (FFileName = '') then
    FFileName := GetCurrentProjectFileName;
  if (FFileName <> '') then
  begin
    FFileName := ChangeFileExt(FFileName, '.ini');
    Result := FFileName;
  end;
  LogText('TBuildOptions.GetFileName(Result: %s)', [Result]);
end;

procedure TBuildOptions.Reset;
begin
  LogText('In - TBuildOptions.Reset(FileName: %s)', [FileName]);
  FileName := '';
  ClearEvents;
  LogText('Out - TBuildOptions.Reset(FileName: %s)', [FileName]);
end;

procedure TBuildOptions.SetPostBuildEvents(AValue: TStringList);
begin
  FPostBuildEvents.Assign(AValue);
end;

procedure TBuildOptions.SetPreBuildEvents(AValue: TStringList);
begin
  FPreBuildEvents.Assign(AValue);
end;

end.
