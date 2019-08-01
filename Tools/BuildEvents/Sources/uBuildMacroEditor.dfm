object MacroEditor: TMacroEditor
  Left = 289
  Top = 233
  BorderStyle = bsDialog
  Caption = 'Macro Editor'
  ClientHeight = 120
  ClientWidth = 466
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 8
    Top = 8
    Width = 451
    Height = 102
    Anchors = [akLeft, akTop, akRight, akBottom]
    Shape = bsFrame
  end
  object Label1: TLabel
    Left = 16
    Top = 20
    Width = 63
    Height = 13
    Caption = 'Macro Name:'
  end
  object Label2: TLabel
    Left = 22
    Top = 46
    Width = 58
    Height = 13
    Caption = 'Macro Path:'
  end
  object ButtonOK: TButton
    Left = 157
    Top = 76
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Caption = 'OK'
    Default = True
    Enabled = False
    ModalResult = 1
    TabOrder = 2
  end
  object ButtonCancel: TButton
    Left = 237
    Top = 76
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object edMacroName: TEdit
    Left = 84
    Top = 16
    Width = 365
    Height = 21
    TabOrder = 0
    OnChange = edMacroNameChange
  end
  object edMacroPath: TEdit
    Left = 84
    Top = 44
    Width = 365
    Height = 21
    TabOrder = 1
    OnChange = edMacroNameChange
  end
end
