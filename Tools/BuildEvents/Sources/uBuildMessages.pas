{ ********************************************************************** }
{ ***** Custom Delphi IDE Build Events Messager for Build Options ****** }
{ ******* Written by Kiran Kurapaty (kuraki@morganstanley.com) ********* }
{ ********************************************************************** }
unit uBuildMessages;

interface

{$I BuildEvents.inc}

uses
  Windows, SysUtils, Controls, Graphics, Classes, Menus, ActnList, ToolsAPI,
  Dialogs, Forms;

type

  TBuildEventMessage = class(TInterfacedObject,
    IOTACustomMessage, INTACustomDrawMessage)
  private
    FMsg : String;
    FFontName   : String;
    FForeColour : TColor;
    FStyle : TFontStyles;
    FBackColour : TColor;
    FMessagePtr : Pointer;
    FFontSize: Integer;
    procedure SetFontSize(const Value: Integer);
  protected
    function CalcRect(ACanvas: TCanvas; AMaxWidth: Integer;
      AWrap: Boolean): TRect;
    procedure Draw(ACanvas: TCanvas; const ARect: TRect; AWrap: Boolean);
    function GetColumnNumber: Integer;
    function GetFileName: string;
    function GetLineNumber: Integer;
    function GetLineText: string;
    procedure ShowHelp;
    Procedure SetForeColour(AColour : TColor);
  public
    constructor Create(AMsg: String; AFontName: String;
      AForeColour: TColor = clBlack; AStyle: TFontStyles = [];
      ABackColour: TColor = clWindow);
    property ForeColour : TColor Write SetForeColour;
    property MessagePtr : Pointer Read FMessagePtr Write FMessagePtr;
    property FontSize: Integer read FFontSize Write SetFontSize default 10;
  end;

implementation

Const
  C_ValidChars : Set Of Char = [#10, #13, #32..#128];

{ TBuildEventMessage }
constructor TBuildEventMessage.Create(AMsg, AFontName: String;
  AForeColour: TColor; AStyle: TFontStyles; ABackColour: TColor);
var
  i : Integer;
  iLength : Integer;
begin
  SetLength(FMsg, Length(AMsg));
  iLength := 0;
  FFontSize := 10;

  for i := 1 To Length(AMsg) Do
  begin
    if (AMsg[i] in C_ValidChars) then
    begin
      FMsg[iLength + 1] := AMsg[i];
      Inc(iLength);
    end;
  end;
  SetLength(FMsg, iLength);
  FFontName := AFontName;
  FForeColour := AForeColour;
  FStyle := AStyle;
  FBackColour := ABackColour;
  FMessagePtr := nil;
end;

function TBuildEventMessage.CalcRect(ACanvas: TCanvas; AMaxWidth: Integer;
  AWrap: Boolean): TRect;
begin
  ACanvas.Font.Name := FFontName;
  ACanvas.Font.Style := FStyle;
  ACanvas.Font.Size := FFontSize;
  Result := ACanvas.ClipRect;
  Result.Bottom := Result.Top + ACanvas.TextHeight('Wp');
  Result.Right := Result.Left + ACanvas.TextWidth(FMsg);
  {
  Wrap Not Implemented: kuraki
  Note that I do not use the wrap parameter. You could wrap your messages to fit in the window width but to do
  this you would then have to change the CalcRect() method and the Draw() method to first calculate the height
  of the wrapped message with the Win32 API DrawText() method and then draw the message with the same API call.
  }
end;

procedure TBuildEventMessage.Draw(ACanvas: TCanvas; const ARect: TRect;
  AWrap: Boolean);
begin
  if (ACanvas.Brush.Color = clWindow) then
  begin
    ACanvas.Font.Color := FForeColour;
    ACanvas.Brush.Color := FBackColour;
    ACanvas.FillRect(ARect);
  end;
  ACanvas.Font.Name := FFontName;
  ACanvas.Font.Style := FStyle;
  ACanvas.Font.Size := FFontSize;
  ACanvas.TextOut(ARect.Left, ARect.Top, FMsg);
end;

function TBuildEventMessage.GetColumnNumber: Integer;
begin
  Result := 0;
end;

function TBuildEventMessage.GetFileName: string;
begin
  Result := '';
end;

function TBuildEventMessage.GetLineNumber: Integer;
begin
  Result := 0;
end;

function TBuildEventMessage.GetLineText: string;
begin
  Result := FMsg;
end;

procedure TBuildEventMessage.SetForeColour(AColour: TColor);
begin
  FForeColour := AColour;
end;

procedure TBuildEventMessage.ShowHelp;
begin
 //
end;

procedure TBuildEventMessage.SetFontSize(const Value: Integer);
begin
  FFontSize := Value;
end;

end.
