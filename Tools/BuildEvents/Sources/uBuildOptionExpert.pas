unit uBuildOptionExpert;

interface

{$I BuildEvents.inc}

uses
  Windows, SysUtils, Graphics, Classes, Menus, ActnList, ToolsAPI, Dialogs,
  Forms, ComCtrls, Contnrs, ExtCtrls, uBuildMisc;

type
  { This is an enumerater for the message types that we will display }
  TMessageType = (mtInfo, mtWarning, mtError, mtSuccess, mtDebug, mtCustom);
  { This is an enumerate for the types of messages that can be cleared. }
  TClearMessage = (cmBuildEvents, cmCompiler, cmSearch, cmTool, cmAll);
  { This is a set of messages that can be cleared. }
  TClearMessages = Set of TClearMessage;

  TBuildOptionExpert = class(TObject)
  private
    { Private declarations }
    FProjectMenu,
    FMenuOptions: TMenuItem;
    FActionOptions: TAction;
    FNotifier: IOTAIDENotifier;
    FNotifyIndex: Integer;
    FOptions: TBuildOptions;
    FBuildTimer: TTimer;
    FAutoSaveTimer: TTimer;
    procedure LogResults(AType: TMessageType; AText: String);
    procedure InitAutoSave;
    procedure UninitAutoSave;
  protected
    { Protected declarations }
    FBuildSpan: TDateTime;
    FBuildSuccess: Boolean;
    {$IFDEF D7_UP}
    FBuildEventsGroup: IOTAMessageGroup;
    function BuildEventsGroup: IOTAMessageGroup;
    function GetSourceEditor: IOTASourceEditor;
    function GetEditorFileName: String;
    {$ENDIF}
    function GetModuleName: String;
    function GetProjectName: String;

    function AddAction(ACaption, AHint, AName : String; AExecuteEvent,
      AUpdateEvent : TNotifyEvent) : TAction;
    procedure RemoveAction(AAction: TAction; AToolbar: TToolbar);
    procedure RemoveActionFromToolbar(AAction: TAction);
    procedure DoOnPostBuildTimerEvent(Sender: TObject);
    procedure DoOnAutoSaveTimerEvent(Sender: TObject);
  public
    { Public declarations }
    constructor Create; virtual;
    destructor Destroy; override;
    class function Instance: TBuildOptionExpert;

    procedure AddMessage(AText: String; AForeColour: TColor;
      AStyle: TFontStyles; ABackColour: TColor = clWindow);
    procedure AddMessageTitle(AType: TMessageType; AText: String);
    procedure ClearMessages(AMsgType : TClearMessages);
    procedure ExecutePostBuildEvent(const Text: string);
    procedure ExecutePreBuildEvent;
    procedure LoadBuildOptions(const FileName: String);
    procedure LogLine(AType: TMessageType; AText : String); overload;
    procedure LogLine(AType: TMessageType; const AFormat: string;
      AParams: array of const); overload;
    procedure LogMessages(AType: TMessageType; AStrings : TStrings);
    procedure TriggerPostBuildEvent(ASuccess: Boolean);
    procedure SetAutoSaveOptions;

    { Action Event Handlers }
    procedure MenuOptionsExecute(Sender : TObject);

    procedure RefreshShortcuts;

    { Property declarations }
    property Options : TBuildOptions read FOptions;
    property ModuleName: String read GetModuleName;
    property ProjectName: String read GetProjectName;
    {$IFDEF D7_UP}
    function Modified: Boolean;
    property EditorFileName: String read GetEditorFileName;
    {$ENDIF}
  end;

  function BuildOptionExpert: TBuildOptionExpert;

implementation

uses Controls, uBuildNotifier, uBuildEngine, uBuildMessages;

const
  clAmber = TColor($004094FF);
  C_MESSAGE_TYPE_COLOUR : array [TMessageType] of TColor =
    (clBlue, clAmber, clRed, clGreen, clPurple, clBlack);

var
  FBuildOptionExpert: TBuildOptionExpert;

{ TBuildOptionExpert }
function BuildOptionExpert: TBuildOptionExpert;
begin
  Result := TBuildOptionExpert.Instance;
end;

class function TBuildOptionExpert.Instance: TBuildOptionExpert;
begin
  if FBuildOptionExpert = nil then
    FBuildOptionExpert := TBuildOptionExpert.Create;
  Result := FBuildOptionExpert;
end;

constructor TBuildOptionExpert.Create;
var
  Service : INTAServices;
begin
  inherited Create;
  FBuildTimer := TTimer.Create(nil);
  FBuildTimer.Interval := 500;
  FBuildTimer.Enabled := False;
  FBuildTimer.OnTimer := DoOnPostBuildTimerEvent;

  FOptions := TBuildOptions.Create();

  Service := (BorlandIDEServices as INTAServices);

  FNotifier := TBuildNotifier.Create;

  with BorlandIDEServices as IOTAServices do
    FNotifyIndex := AddNotifier(FNotifier);

  { Main menu item }
  FProjectMenu := Service.MainMenu.Items.Find('&Project');
  if (FProjectMenu <> nil) then
  begin
    FMenuOptions := TMenuItem.Create(FProjectMenu);
  end else
  begin
    FMenuOptions := TMenuItem.Create(Service.MainMenu);
  end;
  FMenuOptions.Caption := 'Build Options';
  FMenuOptions.AutoHotkeys := maAutomatic;
  FActionOptions := AddAction('Build Events', 'Project Build Events|',
    'BuildEventsOptionAction', MenuOptionsExecute, nil);
  FActionOptions.Shortcut := C_CTRL_SHIFT_F12;
  FMenuOptions.Action := FActionOptions;

  if (FProjectMenu <> nil) then
  begin
    FProjectMenu.Add(FMenuOptions);
  end else
  begin
    Service.MainMenu.Items.Insert(6, FMenuOptions);
  end;

  RefreshShortcuts;
  InitAutoSave;
end;

destructor TBuildOptionExpert.Destroy;
var
  Service : INTAServices;
begin
  Service := (BorlandIDEServices as INTAServices);

  { Destroy the menu item }
  if (FProjectMenu = nil) then
  begin
    if (-1 <> Service.MainMenu.Items.IndexOf(FMenuOptions)) then
      Service.MainMenu.Items.Remove(FMenuOptions);
  end else
  begin
    if (-1 <> FProjectMenu.IndexOf(FMenuOptions)) then
      FProjectMenu.Remove(FMenuOptions);
  end;

  FMenuOptions.Free;
  FActionOptions.Free;

  UnInitAutoSave;

  if Assigned(FBuildTimer) then FBuildTimer.Free;

  with BorlandIDEServices as IOTAServices do
    RemoveNotifier(FNotifyIndex);
  FNotifier := nil;

  FOptions.Free;
  ClearMessages([cmBuildEvents, cmAll]);
  inherited Destroy;
end;

procedure TBuildOptionExpert.InitAutoSave;
begin
  if (not Assigned(FAutoSaveTimer)) then
    FAutoSaveTimer := TTimer.Create(nil);
  FAutoSaveTimer.Interval := C_5_MINUTES;
  FAutoSaveTimer.Enabled := False;
  FAutoSaveTimer.OnTimer := DoOnAutoSaveTimerEvent;
end;

procedure TBuildOptionExpert.UninitAutoSave;
begin
  if Assigned(FAutoSaveTimer) then
  begin
    FAutoSaveTimer.Enabled := False;
    FAutoSaveTimer.Free;
  end;
end;

function TBuildOptionExpert.AddAction(ACaption, AHint, AName: String;
  AExecuteEvent, AUpdateEvent: TNotifyEvent): TAction;
var
  Service : INTAServices;
begin
  Service := (BorlandIDEServices as INTAServices);

  Result := TAction.Create(Service.ActionList);
  with Result do
  begin
    ActionList := Service.ActionList;
    Category := 'Build';
    Caption := ACaption;
    Hint := AHint;
    Name := AName;
    Visible := True;
    OnExecute := AExecuteEvent;
    OnUpdate := AUpdateEvent;
  end;
end;
{$IFDEF D7_UP}
function TBuildOptionExpert.GetEditorFileName: String;
var
  Serv: IOTAModuleServices;
begin
  Result := '';

  Serv := (BorlandIDEServices as IOTAModuleServices);
  if (Serv.CurrentModule <> nil) and
    (Serv.CurrentModule.CurrentEditor <> nil) then
  begin
    Result := Serv.CurrentModule.CurrentEditor.FileName;
  end;
end;

function TBuildOptionExpert.GetSourceEditor: IOTASourceEditor;
var
  Serv      : IOTAModuleServices;
  iCounter  : Integer;
begin
  Result := nil;
  if Supports(BorlandIDEServices, IOTAModuleServices, Serv) then
  begin
    iCounter := 0;
    while (iCounter < Serv.CurrentModule.ModuleFileCount) and (Result = nil) do
    begin
      if not Supports(Serv.CurrentModule.ModuleFileEditors[iCounter],
        IOTASourceEditor, Result) then
          Inc(iCounter);
    end;
  end;
end;

function TBuildOptionExpert.Modified: Boolean;
var
  Serv: IOTAModuleServices;
begin
  Result := False;

  Serv := (BorlandIDEServices as IOTAModuleServices);
  if Serv.CurrentModule <> nil then
    Result := Serv.CurrentModule.CurrentEditor.Modified;
end;

function TBuildOptionExpert.BuildEventsGroup: IOTAMessageGroup;
begin
  with (BorlandIDEServices as IOTAMessageServices) do
  begin
    { First we try to retrieve if we already have group }
    if (FBuildEventsGroup = nil) then
      FBuildEventsGroup := GetGroup('Build Events');

    { if not, we will add new group }
    if (FBuildEventsGroup = nil) then
      FBuildEventsGroup := AddMessageGroup('Build Events');

    if (FBuildEventsGroup = nil) then
      FBuildEventsGroup := GetMessageGroup(0);
  end;
  Result := FBuildEventsGroup;
end;

{$ENDIF}

function TBuildOptionExpert.GetModuleName: String;
begin
  Result := GetCurrentProjectFileName;
end;

function TBuildOptionExpert.GetProjectName: String;
begin
  Result := GetCurrentProjectName;
end;

procedure TBuildOptionExpert.LogLine(AType: TMessageType; AText: String);
begin
  if FOptions.ShowMessages then
  begin
    AddMessage(Format('[%s] %s', [TimeToStr(Time), AText]),
      C_MESSAGE_TYPE_COLOUR[AType], []);
  end;
end;

procedure TBuildOptionExpert.AddMessageTitle(AType: TMessageType; AText: String);
begin
  if FOptions.ShowMessages then
    AddMessage(AText, C_MESSAGE_TYPE_COLOUR[AType], []);
end;

procedure TBuildOptionExpert.LogLine(AType: TMessageType; const AFormat: String;
  AParams: array of const);
begin
  LogLine(AType, Format(AFormat, AParams));
end;

procedure TBuildOptionExpert.LogMessages(AType: TMessageType;
  AStrings: TStrings);
var
  I: Integer;
  mType: TMessageType;
begin
  if FOptions.ShowMessages then
  begin
    for I := 0 to AStrings.Count - 1 do
    begin
      if ContainsString(AStrings[I],
        ['error', 'exception', 'failed', 'denied']) then
          mType := mtError
      else
      if ContainsString(AStrings[I], ['invalid']) then
        mType := mtWarning
      else
        mType := AType;

      LogLine(mType, AStrings[I]);
    end;
  end;
end;

procedure TBuildOptionExpert.MenuOptionsExecute(Sender: TObject);
begin
  if Options.ShowDialog(ModuleName) then
    RefreshShortcuts;
end;

procedure TBuildOptionExpert.RefreshShortcuts;
begin
  FOptions.LoadProjectEvents(ModuleName);
  FActionOptions.ShortCut := IfThen(FOptions.Shortcut = 0, C_CTRL_SHIFT_F12,
    FOptions.Shortcut);
  SetAutoSaveOptions();
end;

procedure TBuildOptionExpert.RemoveAction(AAction: TAction; AToolbar: TToolbar);
var
  iCounter: Integer;
  btnTool : TToolButton;
begin
  for iCounter := AToolbar.ButtonCount - 1 downto 0 do
  begin
    btnTool := AToolbar.Buttons[iCounter];
    if btnTool.Action = AAction then
    begin
      AToolbar.Perform(CM_CONTROLCHANGE, WParam(btnTool), 0);
      btnTool.Free;
    end;
  end;
end;

procedure TBuildOptionExpert.RemoveActionFromToolbar(AAction: TAction);
var
  Services : INTAServices;
begin
  Services := (BorlandIDEServices as INTAServices);

  RemoveAction(AAction, Services.ToolBar[sCustomToolBar]);
  RemoveAction(AAction, Services.ToolBar[sDesktopToolBar]);
  RemoveAction(AAction, Services.ToolBar[sStandardToolBar]);
  RemoveAction(AAction, Services.ToolBar[sDebugToolBar]);
  RemoveAction(AAction, Services.ToolBar[sViewToolBar]);
//  RemoveAction(AAction, Services.ToolBar['InternetToolBar']);
end;

procedure TBuildOptionExpert.LogResults(AType: TMessageType; AText: String);
var
  slList: TStringList;
begin
  slList := TStringList.Create;
  try
    slList.Text := AText;
    LogMessages(AType, slList);
  finally
    slList.Free;
  end;
end;

procedure TBuildOptionExpert.TriggerPostBuildEvent(ASuccess: Boolean);
begin
  FBuildSuccess := ASuccess;
  FBuildTimer.Enabled := True;
end;

procedure TBuildOptionExpert.DoOnPostBuildTimerEvent(Sender: TObject);
begin
  FBuildTimer.Enabled := False;
  FBuildSpan := (Now - FBuildSpan);
  try
    case (Options.PostBuildOption) of
      boSuccess:
        if (FBuildSuccess) then
          ExecutePostBuildEvent('Build Success');
      boFailed:
        if (not FBuildSuccess) then
          ExecutePostBuildEvent('Build Failed');
      boAlways:
        ExecutePostBuildEvent('After Build');
      boNone:
        LogLine(mtDebug, '%s Compiled in %s',
          [ProjectName, GetDoneTimeStr(FBuildSpan)]);
    end;
  finally
    FBuildSuccess := False;
  end;
end;

procedure TBuildOptionExpert.ExecutePostBuildEvent(const Text: String);
var
  Index: Integer;
  Command: string;
  slList: TStringList;
begin
  if not Options.PostBuildEnabled then Exit;
  if Options.PostBuildEvents.Count = 0 then Exit;

  slList := TStringList.Create;
  LogLine(mtDebug, '%s Compiled in %s',
    [ProjectName, GetDoneTimeStr(FBuildSpan)]);

  BuildEngine.RefreshMacros;

  try
    for Index := 0 to Options.PostBuildEvents.Count - 1 do
    begin
      slList.Clear;
      Command := Trim(Options.PostBuildEvents[Index]);

      if Command = '' then Continue;
      if Pos('REM', UpperCase(Command)) = 1 then Continue;

      AddMessageTitle(mtCustom,
        Format('Post-build %s: %s', [Text, Command]));
      try
        LogResults(mtSuccess, BuildEngine.Command(Command, slList));
        if slList.Count > 0 then
          LogMessages(mtInfo, slList);
        // LogResults(mtInfo, BuildEngine.LastCmd);
      except
        on E: Exception do
        begin
          LogLine(mtError, E.Message);
          LogException(E, 'TBuildOptionExpert.ExecutePostBuildEvent');
        end;
      end;
    end;
  finally
    slList.Free;
  end;
end;

procedure TBuildOptionExpert.ExecutePreBuildEvent;
var
  Index: Integer;
  Command: string;
begin
  FBuildSpan := Now;
  ClearMessages([cmBuildEvents]);

  if not Options.PreBuildEnabled then Exit;
  if Options.PreBuildEvents.Count = 0 then Exit;

  BuildEngine.RefreshMacros;

  for Index := 0 to Options.PreBuildEvents.Count - 1 do
  begin
    try
      Command := Trim(Options.PreBuildEvents[Index]);
      if Command = '' then Continue;
      if Pos('REM', UpperCase(Command)) = 1 then Continue;
      AddMessageTitle(mtCustom,
        Format('Pre-build: %s', [Command]));
      LogResults(mtSuccess, BuildEngine.Command(Command));
    except
      on E: Exception do
      begin
        LogLine(mtError, E.Message);
        LogException(E, 'TBuildOptionExpert.ExecutePreBuildEvent');
      end;
    end;
  end;
end;

procedure TBuildOptionExpert.LoadBuildOptions(const FileName: string);
begin
  LogText('In - TBuildOptionExpert.LoadBuildOptions (File: %s)', [FileName]);
  try
//    Options.SaveProjectEvents(True);
    Options.LoadProjectEvents(FileName);
    BuildEngine.RefreshMacros;
  except
    on E: Exception do
    begin
      LogLine(mtError, E.Message);
      LogException(E, 'TBuildOptionExpert.LoadBuildOptions');
    end;
  end;
  LogText('Out - TBuildOptionExpert.LoadBuildOptions (File: %s)', [FileName]);
end;

procedure TBuildOptionExpert.AddMessage(AText: String; AForeColour: TColor;
  AStyle: TFontStyles; ABackColour : TColor = clWindow);
var
{$IFNDEF D7_UP}
  I: Integer;
{$ENDIF}
  Mesg : TBuildEventMessage;
begin
  if (Trim(AText) = '') then Exit; // do not add empty / blank lines
  Application.ProcessMessages;
  try
    With (BorlandIDEServices As IOTAMessageServices) Do
    begin
      Mesg := TBuildEventMessage.Create(AText, Options.FontName, AForeColour,
        AStyle, ABackColour);
      Mesg.FontSize := Options.FontSize;
      AddCustomMessage(Mesg As IOTACustomMessage
        {$IFDEF D7_UP}, BuildEventsGroup{$ENDIF});

      {$IFDEF D7_UP}
        ShowMessageView(BuildEventsGroup);
      {$ELSE}
      for I := 0 to Screen.FormCount - 1 do
        if CompareText(Screen.Forms[I].ClassName, 'TMessageViewForm') = 0 then
           Screen.Forms[I].Visible := True;
      {$ENDIF}
    end;
  except
    On E: Exception do LogException(E, 'TBuildOptionExpert.AddMessage');
  end;
end;

procedure TBuildOptionExpert.ClearMessages(AMsgType: TClearMessages);
begin
  with (BorlandIDEServices As IOTAMessageServices) do
  begin
    if (cmCompiler In AMsgType) then ClearCompilerMessages;
    if (cmSearch in AMsgType) then ClearSearchMessages;
    if (cmTool in AMsgType) then ClearToolMessages;
    if (cmBuildEvents in AMsgType) then {$IFDEF D7_UP}
      ClearMessageGroup(BuildEventsGroup); {$ELSE} ClearToolMessages; {$ENDIF}
    if (cmAll in AMsgType) then ClearAllMessages;
  end;
end;

procedure TBuildOptionExpert.DoOnAutoSaveTimerEvent(Sender: TObject);
var
  activeProject: IOTAProject;
begin
  if Assigned(FAutoSaveTimer) then
  begin
    FAutoSaveTimer.Enabled := False;
    if (Options.AutoSaveProject) then
    begin
      activeProject := GetCurrentProject;
      if (activeProject <> nil) then
      begin
        try
          if activeProject.Save(False, True) then
            LogLine(mtInfo, '%s Saved', [ProjectName]);
        except
          On E: Exception do LogException(E,
            'TBuildOptionExpert.DoOnAutoSaveTimerEvent');
        end;
      end;
    end;
    FAutoSaveTimer.Enabled := True;
  end;
end;

procedure TBuildOptionExpert.SetAutoSaveOptions;
begin
  if Assigned(FAutoSaveTimer) then
  begin
    FAutoSaveTimer.Interval := Options.AutoSaveInterval * 60000;
    FAutoSaveTimer.Enabled := Options.AutoSaveProject;
  end;
end;

initialization
  FBuildOptionExpert := TBuildOptionExpert.Instance;

finalization
  FreeAndNil(FBuildOptionExpert);

end.
