unit uBuildOptionsForm;

{$I BuildEvents.Inc}

interface

uses
  Windows, Messages, SysUtils, {$IFDEF D6_UP}Variants, {$ENDIF} Classes,
  Graphics, Controls, Forms, Dialogs, StdCtrls, Buttons, ComCtrls, ExtCtrls,
  uBuildMisc, Spin;

type
  TBuildOptionsForm = class(TForm)
    pgcOptions: TPageControl;
    tsOptions: TTabSheet;
    tsAbout: TTabSheet;
    gbBuildEvents: TGroupBox;
    Label14: TLabel;
    mPreBuildEvent: TMemo;
    mPostBuildEvent: TMemo;
    cbPostBuildEvents: TComboBox;
    Label12: TLabel;
    hkShortcut: THotKey;
    ChkShowMessages: TCheckBox;
    LabelProduct: TLabel;
    lblDescription: TLabel;
    LabelAuthor: TLabel;
    lblFileName: TLabel;
    btnLoad: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    OpenDialog1: TOpenDialog;
    lblFontName: TLabel;
    SpinEditSize: TSpinEdit;
    cbFontNames: TComboBox;
    edFileName: TEdit;
    lblSize: TLabel;
    PreBuildCheck: TCheckBox;
    PostBuildCheck: TCheckBox;
    CheckAutoSaveProject: TCheckBox;
    SpinInterval: TSpinEdit;
    procedure FormCreate(Sender: TObject);
    procedure mPreBuildEventDblClick(Sender: TObject);
    procedure mPostBuildEventDblClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure cbFontNamesDrawItem(AControl: TWinControl; AIndex: Integer;
      ARect: TRect; AState: TOwnerDrawState);
    procedure PreBuildCheckClick(Sender: TObject);
    procedure PostBuildCheckClick(Sender: TObject);
    procedure LabelAuthorClick(Sender: TObject);
  private
    function GetFontNameIndex(AName: String): Integer;
    function GetSelectedFontName: String;
    procedure LoadFontNames;
    procedure EnablePostBuild(AEnabled: Boolean);
    procedure EnablePreBuild(AEnabled: Boolean);
  public
    function Execute(AOptions : TBuildOptions) : Boolean;
  end;

implementation

{$R *.dfm}

uses
  ShellAPI,
  uBuildCommandEditor,
  uBuildOptionExpert,
  uBuildEngine;

{ TfrmOptions }
function EnumFontsProc(var LogFont: TLogFont; var TextMetric: TTextMetric;
  FontType: Integer; Data: Pointer): Integer; stdcall;
begin
  TStrings(Data).Add(LogFont.lfFaceName);
  Result := 1;
end;

procedure TBuildOptionsForm.LoadFontNames;
var
  DC: HDC;
begin
  DC := GetDC(0);
  EnumFonts(DC, nil, @EnumFontsProc, Pointer(cbFontNames.Items));
  ReleaseDC(0, DC);
  cbFontNames.Sorted := True;
end;

function TBuildOptionsForm.GetFontNameIndex(AName: String): Integer;
begin
  Result := cbFontNames.Items.IndexOf(AName);
end;

function TBuildOptionsForm.GetSelectedFontName: String;
begin
  Result := Trim(cbFontNames.Text);
  if (Result = EmptyStr) then Result := C_DEFAULT_FONT_NAME;
end;

function TBuildOptionsForm.Execute(AOptions: TBuildOptions): Boolean;
begin
  {  Shortcuts }
  hkShortcut.HotKey := AOptions.Shortcut;
  ChkShowMessages.Checked := AOptions.ShowMessages;
  mPreBuildEvent.Lines.Assign(AOptions.PreBuildEvents);
  mPostBuildEvent.Lines.Assign(AOptions.PostBuildEvents);
  cbPostBuildEvents.ItemIndex := Integer(AOptions.PostBuildOption);
  cbFontNames.ItemIndex := GetFontNameIndex(AOptions.FontName);
  SpinEditSize.Value := AOptions.FontSize;
  SpinInterval.Value := AOptions.AutoSaveInterval;
  edFileName.Text := AOptions.FileName;
  PreBuildCheck.Checked := AOptions.PreBuildEnabled;
  PostBuildCheck.Checked := AOptions.PostBuildEnabled;
  CheckAutoSaveProject.Checked := AOptions.AutoSaveProject;
  Result := (ShowModal = mrOK);

  if Result then
  begin
    AOptions.PreBuildEvents.Clear;
    AOptions.PostBuildEvents.Clear;
    AOptions.PreBuildEvents.Assign(mPreBuildEvent.Lines);
    AOptions.PostBuildEvents.Assign(mPostBuildEvent.Lines);
    AOptions.PostBuildOption := TPostBuildOption(cbPostBuildEvents.ItemIndex);
    { Shortcuts }
    AOptions.Shortcut := hkShortcut.HotKey;
    AOptions.ShowMessages := chkShowMessages.Checked;
    AOptions.FontSize := SpinEditSize.Value;
    AOptions.FontName := GetSelectedFontName;
    AOptions.PreBuildEnabled := PreBuildCheck.Checked;
    AOptions.PostBuildEnabled := PostBuildCheck.Checked;
    AOptions.AutoSaveProject := CheckAutoSaveProject.Checked;
    AOptions.AutoSaveInterval:= SpinInterval.Value;
    AOptions.SaveAll;
  end;
end;

procedure TBuildOptionsForm.FormCreate(Sender: TObject);
var
  sModule: String;
begin
  LoadFontNames;
  sModule := GetCurrentProjectName;
  if (sModule = EmptyStr) then sModule := 'Project';
  Caption := Format('Build Events for %s', [sModule]);
  pgcOptions.ActivePageIndex := 0;
end;

procedure TBuildOptionsForm.mPreBuildEventDblClick(Sender: TObject);
begin
  mPreBuildEvent.Lines.Text :=
    ShowBuildCommandEditor('Pre', mPreBuildEvent.Lines.Text );
end;

procedure TBuildOptionsForm.mPostBuildEventDblClick(Sender: TObject);
begin
  mPostBuildEvent.Lines.Text :=
    ShowBuildCommandEditor('Post', mPostBuildEvent.Lines.Text );
end;

procedure TBuildOptionsForm.btnLoadClick(Sender: TObject);
begin
  OpenDialog1.InitialDir := ExtractFilePath(GetCurrentProjectFileName);
  if (OpenDialog1.Execute) then
  begin
    if (BuildOptionExpert.Options.CopyProjectEvents(OpenDialog1.FileName)) then
    begin
      mPreBuildEvent.Lines.Assign(BuildOptionExpert.Options.PreBuildEvents);
      mPostBuildEvent.Lines.Assign(BuildOptionExpert.Options.PostBuildEvents);
      cbPostBuildEvents.ItemIndex :=
        Integer(BuildOptionExpert.Options.PostBuildOption);
      edFileName.Text := BuildOptionExpert.Options.FileName;
      PreBuildCheck.Checked := BuildOptionExpert.Options.PreBuildEnabled;
      PostBuildCheck.Checked := BuildOptionExpert.Options.PostBuildEnabled;
      CheckAutoSaveProject.Checked := BuildOptionExpert.Options.AutoSaveProject;
    end;
  end;
end;

procedure TBuildOptionsForm.cbFontNamesDrawItem(AControl: TWinControl;
  AIndex: Integer; ARect: TRect; AState: TOwnerDrawState);
begin
  with (AControl as TComboBox).Canvas do
  begin
    FillRect(ARect);
    Font.Name := cbFontNames.Items[AIndex];
    TextOut(ARect.Left, ARect.Top, cbFontNames.Items[AIndex]);
    edFileName.Font.Name := cbFontNames.Items[AIndex];
  end;
end;

procedure TBuildOptionsForm.EnablePostBuild(AEnabled: Boolean);
begin
  mPostBuildEvent.Enabled := AEnabled;
  cbPostBuildEvents.Enabled := AEnabled;
end;

procedure TBuildOptionsForm.EnablePreBuild(AEnabled: Boolean);
begin
  mPreBuildEvent.Enabled := AEnabled;
end;

procedure TBuildOptionsForm.PreBuildCheckClick(Sender: TObject);
begin
  EnablePreBuild(PreBuildCheck.Checked);
end;

procedure TBuildOptionsForm.PostBuildCheckClick(Sender: TObject);
begin
  EnablePostBuild(PostBuildCheck.Checked);
end;

procedure TBuildOptionsForm.LabelAuthorClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://kurapaty.wordpress.com/about-2/',
    nil, nil, SW_NORMAL);
end;

end.
