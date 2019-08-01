unit uBuildCommandEditor;

interface

{$I BuildEvents.inc}

uses
  Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, Buttons,
  ExtCtrls, Grids, ComCtrls, uBuildMisc, Menus;

type
  TBuildCommandEditorDlg = class(TForm)
    ButtonOK: TButton;
    ButtonCancel: TButton;
    ButtonInsert: TButton;
    PanelBase: TPanel;
    Editor: TMemo;
    Splitter1: TSplitter;
    MacroValues: TListView;
    ButtonToggle: TButton;
    pmMacro: TPopupMenu;
    mniAddMacro: TMenuItem;
    mniDeleteMacro: TMenuItem;
    mniEditMacro: TMenuItem;
    procedure ButtonInsertClick(Sender: TObject);
    procedure ButtonToggleClick(Sender: TObject);
    procedure mniAddMacroClick(Sender: TObject);
    procedure mniEditMacroClick(Sender: TObject);
    procedure mniDeleteMacroClick(Sender: TObject);
    procedure pmMacroPopup(Sender: TObject);
  protected
    procedure UpdateUI;
  public
    procedure ToggleMacroDisplay;
    procedure PopulateDefaultMacros;
  end;

  function ShowBuildCommandEditor(const Caption, CommandStr: string): string;

implementation

{$R *.dfm}

uses
  uBuildEngine,
  uBuildMacroEditor;

function ShowBuildCommandEditor(const Caption, CommandStr: string): string;
var
  Dialog: TBuildCommandEditorDlg;
begin
  Dialog := TBuildCommandEditorDlg.Create(Application);
  try
   Dialog.PopulateDefaultMacros;
   Dialog.Editor.Text := CommandStr;
   Dialog.Caption := Format('%s-build Event Command Line', [Caption]);
   if Dialog.ShowModal = mrOk then
     Result := Dialog.Editor.Text
   else
     Result := CommandStr;
  finally
    Dialog.Free;
  end;
end;

procedure TBuildCommandEditorDlg.ButtonInsertClick(Sender: TObject);
begin
  if Assigned(MacroValues.Selected) then
    Editor.SelText := Format('$(%s)', [MacroValues.Selected.Caption]);
end;

procedure TBuildCommandEditorDlg.ToggleMacroDisplay;
begin
  if (MacroValues.Visible) then
  begin
    Splitter1.Visible := False;
    MacroValues.Visible := False;
    Height := 310;
    ButtonToggle.Caption := 'Macros >>';
  end else
  begin
    Splitter1.Visible := True;
    MacroValues.Visible := True;
    Height := 500;
    ButtonToggle.Caption := '<< Macros';
  end;
end;

procedure TBuildCommandEditorDlg.ButtonToggleClick(Sender: TObject);
begin
  ToggleMacroDisplay();
end;

procedure TBuildCommandEditorDlg.PopulateDefaultMacros;
var
  Index: Integer;
begin
  try
    if Assigned(BuildEngine) then
    begin
      BuildEngine.RefreshMacros;
      for Index := 0 to BuildEngine.MacroList.Count - 1 do
        with MacroValues.Items.Add do
        begin
          Caption := BuildEngine.MacroList.Names[Index];
          SubItems.Add(
            {$IFDEF D7_UP}
              BuildEngine.MacroList.ValueFromIndex[Index]
            {$ELSE}
              BuildEngine.MacroList.Values[BuildEngine.MacroList.Names[Index]]
            {$ENDIF}
            );
        end;
    end;
    UpdateUI;
  except
    ButtonInsert.Visible := False;
  end;
end;

procedure TBuildCommandEditorDlg.UpdateUI;
begin
  ButtonInsert.Enabled := MacroValues.Items.Count > 0;
  mniEditMacro.Enabled := MacroValues.SelCount > 0;
  mniDeleteMacro.Enabled := MacroValues.SelCount > 0;
end;

procedure TBuildCommandEditorDlg.mniAddMacroClick(Sender: TObject);
var
  sName, sPath: String;
begin
  if (EditMacroItem('Add', sName, sPath)) then
  begin
    with MacroValues.Items.Add do
    begin
      Caption := sName;
      SubItems.Add(sPath);
    end;
    BuildEngine.AddMacro(sName, sPath);
  end;
end;

procedure TBuildCommandEditorDlg.mniEditMacroClick(Sender: TObject);
var
  sOldName, sName, sPath: String;
begin
  if (MacroValues.Selected = nil) then Exit;

  sName := MacroValues.Selected.Caption;
  sOldName:= sName;
  sPath := MacroValues.Selected.SubItems.Strings[0];
  if (EditMacroItem('Edit', sName, sPath)) then
  begin
    with MacroValues.Selected do
    begin
      Caption := sName;
      SubItems.Strings[0] := sPath;
    end;
    BuildEngine.EditMacro(sOldName, sName, sPath);
  end;
end;

procedure TBuildCommandEditorDlg.mniDeleteMacroClick(Sender: TObject);
var
  sName: String;
begin
  if MacroValues.Selected = nil then Exit;
  sName := MacroValues.Selected.Caption;
  MacroValues.Selected.Delete;
  BuildEngine.DeleteMacro(sName);
end;

procedure TBuildCommandEditorDlg.pmMacroPopup(Sender: TObject);
begin
  UpdateUI;
end;

end.
