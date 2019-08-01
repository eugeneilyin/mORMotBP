object BuildCommandEditorDlg: TBuildCommandEditorDlg
  Left = 649
  Top = 402
  Width = 676
  Height = 501
  Caption = 'Macro Editor'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  object ButtonOK: TButton
    Left = 504
    Top = 436
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 3
  end
  object ButtonCancel: TButton
    Left = 584
    Top = 436
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
  object ButtonInsert: TButton
    Left = 425
    Top = 436
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Insert'
    Enabled = False
    TabOrder = 2
    OnClick = ButtonInsertClick
  end
  object PanelBase: TPanel
    Left = 8
    Top = 10
    Width = 650
    Height = 418
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object Splitter1: TSplitter
      Left = 1
      Top = 237
      Width = 648
      Height = 3
      Cursor = crVSplit
      Align = alTop
    end
    object Editor: TMemo
      Left = 1
      Top = 1
      Width = 648
      Height = 236
      Align = alTop
      TabOrder = 0
    end
    object MacroValues: TListView
      Left = 1
      Top = 240
      Width = 648
      Height = 177
      Align = alClient
      Columns = <
        item
          Caption = 'Macro'
          Width = 225
        end
        item
          Caption = 'Value'
          Width = 400
        end>
      FlatScrollBars = True
      ReadOnly = True
      RowSelect = True
      PopupMenu = pmMacro
      SortType = stBoth
      TabOrder = 1
      ViewStyle = vsReport
      OnDblClick = ButtonInsertClick
    end
  end
  object ButtonToggle: TButton
    Left = 8
    Top = 436
    Width = 100
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = '<< Macros'
    TabOrder = 1
    OnClick = ButtonToggleClick
  end
  object pmMacro: TPopupMenu
    OnPopup = pmMacroPopup
    Left = 286
    Top = 316
    object mniAddMacro: TMenuItem
      Caption = 'Add'
      OnClick = mniAddMacroClick
    end
    object mniEditMacro: TMenuItem
      Caption = 'Edit'
      OnClick = mniEditMacroClick
    end
    object mniDeleteMacro: TMenuItem
      Caption = 'Delete'
      OnClick = mniDeleteMacroClick
    end
  end
end
