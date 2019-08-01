{ ********************************************************************** }
{ ******** Custom Delphi IDE Build Notifier for Build Options ********** }
{ ******* Written by Kiran Kurapaty (kuraki@morganstanley.com) ********* }
{ ********************************************************************** }
unit uBuildNotifier;

interface

{$I BuildEvents.inc}

uses
  Windows, SysUtils, Controls, Graphics, Classes, Menus, ActnList, ToolsAPI,
  Dialogs, Forms;

type

  TBuildNotifier = class(TNotifierObject, IOTAIDENotifier, IOTAIDENotifier50)
  protected
    { This procedure is to load files related }
    procedure ListFiles(const FileName: string; Files: TStrings);
    { This procedure is to check if we are processing correct file for our purpose }
    function IsValidExtension(const FileName: string): Boolean;
  public
    procedure BeforeCompile(const Project: IOTAProject;
      var Cancel: Boolean); overload;
    { Same as BeforeCompile on IOTAIDENotifier except indicates if the compiler
      was invoked due to a CodeInsight compile }
    procedure BeforeCompile(const Project: IOTAProject; IsCodeInsight: Boolean;
      var Cancel: Boolean); overload;

    procedure AfterCompile(Succeeded: Boolean); overload;
    { Same as AfterCompile on IOTAIDENotifier except indicates if the compiler
      was invoked due to a CodeInsight compile }
    procedure AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean); overload;
    { This procedure is called for many various file operations within the IDE }
    procedure FileNotification(NotifyCode: TOTAFileNotification;
      const FileName: string; var Cancel: Boolean);
  end;

implementation

uses
  uBuildEngine,
  uBuildOptionExpert,
  uBuildMisc;

const
  C_OTA_FILE_NOTIFICATION_STR : array [TOTAFileNotification] of String = (
    'ofnFileOpening', 'ofnFileOpened', 'ofnFileClosing',
    'ofnDefaultDesktopLoad', 'ofnDefaultDesktopSave', 'ofnProjectDesktopLoad',
    'ofnProjectDesktopSave', 'ofnPackageInstalled', 'ofnPackageUninstalled'
    {$IFDEF D6_UP}, 'ofnActiveProjectChanged'{$ENDIF} );

{ TBuildNotifier }

procedure TBuildNotifier.AfterCompile(Succeeded: Boolean);
begin
 // Do nothing, keep it for backward compatibility
end;

procedure TBuildNotifier.AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean);
begin
  if not IsCodeInsight then
    BuildOptionExpert.TriggerPostBuildEvent(Succeeded);
end;

procedure TBuildNotifier.BeforeCompile(const Project: IOTAProject;
  var Cancel: Boolean);
begin
 // Do nothing, keep it for backward compatibility
end;

procedure TBuildNotifier.BeforeCompile(const Project: IOTAProject;
  IsCodeInsight: Boolean; var Cancel: Boolean);
begin
  if not IsCodeInsight then
    BuildOptionExpert.ExecutePreBuildEvent;
end;

procedure TBuildNotifier.FileNotification(NotifyCode: TOTAFileNotification;
  const FileName: string; var Cancel: Boolean);
begin
  if not IsValidExtension(FileName) then Exit;

  LogText('TBuildNotifier.FileNotification: NotifyCode=%s, FileName=%s',
    [C_OTA_FILE_NOTIFICATION_STR[NotifyCode], FileName]);

  case NotifyCode of
    { the file passed in FileName is opening where FileName is the name of the
      file being opened }
    ofnFileOpening:           ; // do nothing
    { the file passed in FileName has opened where FileName is the name of the
      file that was opened }
    ofnFileOpened:
      BuildOptionExpert.LoadBuildOptions(FileName);
    { the file passed in FileName is closing where FileName is the name of the
      file being closed }
    ofnFileClosing:
      BuildOptionExpert.Options.Reset;
    { I haven’t found when this is triggered in my test but I assume it is when
      the IDE loads the Default Desktop settings }
    ofnDefaultDesktopLoad:    ; // do nothing
    { I haven’t found when this is triggered in my test but I assume it is when
      the IDE saves the Default Desktop settings }
    ofnDefaultDesktopSave:    ; // do nothing
    { this is triggered when the IDE loads a project’s desktop settings where
      FileName is the name of the desktop settings file }
    ofnProjectDesktopLoad:
      {BuildOptionExpert.LoadBuildOptions(FileName)};
    { this is triggered when the IDE saves a project’s desktop settings where
      FileName is the name of the desktop settings file }
    ofnProjectDesktopSave:    ; // do nothing
    { this is triggered when a package (BPL) list loaded by the IDE where
      FileName is the name of the BPL file }
    ofnPackageInstalled:      ; // do nothing
    { this is triggered when a package (BPL) list unloaded by the IDE where
      FileName is the name of the BPL file }
    ofnPackageUninstalled:    ; // do nothing
    { this is triggered when a project is made active in the IDE’s Project
      Manager where the FileName is the project file
      (.dproj, bdsproj or .dpr for older version of Delphi) }
    {$IFDEF D6_UP}
    ofnActiveProjectChanged:
      BuildOptionExpert.LoadBuildOptions(FileName);
    {$ENDIF}
  end;

  LogText('TBuildNotifier.FileNotification: NotifyCode=%s, FileName=%s',
    [C_OTA_FILE_NOTIFICATION_STR[NotifyCode], FileName]);
end;

function TBuildNotifier.IsValidExtension(const FileName: string): Boolean;
const
  EXTENSIONS: array[0..4] of string =
    ('.dpr', '.bpg', '.dpk', '.bdsproj', '.bdsgroup');
var
  Index: Integer;
  FileExt: string;
begin
  FileExt := LowerCase(ExtractFileExt(FileName));
  for Index := Low(EXTENSIONS) to High(EXTENSIONS) do
    if EXTENSIONS[Index] = FileExt then
    begin
      Result := True;
      Exit;
    end;
  Result := False;
end;

procedure TBuildNotifier.ListFiles(const FileName: string; Files: TStrings);
var
  FileMask, FilePath: string;
  SR: TSearchRec;
begin
  Files.Clear;
  FileMask := ChangeFileExt(FileName, '.*');
  if FindFirst(FileMask, faAnyFile, SR) = 0 then
  begin
    FilePath := ExtractFilePath(FileName);
    repeat
      if LowerCase(ExtractFileExt(SR.Name)) = '.dpr' then
        Files.Add(FilePath + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

end.
