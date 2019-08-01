object BuildOptionsForm: TBuildOptionsForm
  Left = 527
  Top = 274
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Build Events'
  ClientHeight = 436
  ClientWidth = 600
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pgcOptions: TPageControl
    Left = 0
    Top = 0
    Width = 600
    Height = 436
    ActivePage = tsOptions
    Align = alClient
    TabOrder = 0
    object tsOptions: TTabSheet
      Caption = '&Build Options'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      object Label12: TLabel
        Left = 10
        Top = 378
        Width = 90
        Height = 14
        Anchors = [akLeft, akBottom]
        Caption = 'Assign &Shortcut:'
        FocusControl = hkShortcut
      end
      object gbBuildEvents: TGroupBox
        Left = 6
        Top = 2
        Width = 579
        Height = 363
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = 'Pre / Post Build Events'
        TabOrder = 0
        object Label14: TLabel
          Left = 12
          Top = 280
          Width = 118
          Height = 14
          Caption = '&Run post-build event:'
          FocusControl = cbPostBuildEvents
        end
        object lblFontName: TLabel
          Left = 12
          Top = 308
          Width = 112
          Height = 14
          Caption = 'Build messages &font:'
          FocusControl = cbFontNames
        end
        object lblSize: TLabel
          Left = 388
          Top = 308
          Width = 29
          Height = 14
          Caption = 'Si&ze :'
          FocusControl = SpinEditSize
        end
        object mPreBuildEvent: TMemo
          Left = 10
          Top = 38
          Width = 556
          Height = 100
          Anchors = [akLeft, akTop, akRight]
          ScrollBars = ssBoth
          TabOrder = 1
          OnDblClick = mPreBuildEventDblClick
        end
        object mPostBuildEvent: TMemo
          Left = 10
          Top = 164
          Width = 556
          Height = 100
          Anchors = [akLeft, akTop, akRight]
          ScrollBars = ssBoth
          TabOrder = 3
          OnDblClick = mPostBuildEventDblClick
        end
        object cbPostBuildEvents: TComboBox
          Left = 136
          Top = 278
          Width = 250
          Height = 22
          Style = csOwnerDrawFixed
          ItemHeight = 16
          TabOrder = 4
          Items.Strings = (
            'Always'
            'On Successfull'
            'On Failure'
            'None')
        end
        object ChkShowMessages: TCheckBox
          Left = 420
          Top = 279
          Width = 140
          Height = 17
          Caption = 'Show build &messages'
          TabOrder = 5
        end
        object SpinEditSize: TSpinEdit
          Left = 420
          Top = 304
          Width = 50
          Height = 23
          Hint = 'Font Size'
          MaxLength = 2
          MaxValue = 20
          MinValue = 8
          TabOrder = 7
          Value = 10
        end
        object cbFontNames: TComboBox
          Left = 136
          Top = 306
          Width = 250
          Height = 22
          Style = csOwnerDrawFixed
          ItemHeight = 16
          TabOrder = 6
          OnDrawItem = cbFontNamesDrawItem
        end
        object PreBuildCheck: TCheckBox
          Left = 10
          Top = 19
          Width = 193
          Height = 17
          Caption = 'Pr&e-build events:'
          TabOrder = 0
          OnClick = PreBuildCheckClick
        end
        object PostBuildCheck: TCheckBox
          Left = 10
          Top = 145
          Width = 209
          Height = 17
          Caption = 'P&ost-build events:'
          TabOrder = 2
          OnClick = PostBuildCheckClick
        end
        object CheckAutoSaveProject: TCheckBox
          Left = 12
          Top = 334
          Width = 279
          Height = 17
          Caption = 'Auto Save project in every               minutes'
          TabOrder = 8
        end
        object SpinInterval: TSpinEdit
          Left = 180
          Top = 332
          Width = 50
          Height = 23
          Hint = 'Font Size'
          MaxLength = 2
          MaxValue = 99
          MinValue = 2
          TabOrder = 9
          Value = 5
        end
      end
      object hkShortcut: THotKey
        Left = 107
        Top = 374
        Width = 200
        Height = 23
        Anchors = [akLeft, akBottom]
        HotKey = 0
        InvalidKeys = [hcNone, hcShift]
        Modifiers = []
        TabOrder = 1
      end
      object btnLoad: TButton
        Left = 351
        Top = 372
        Width = 75
        Height = 25
        Anchors = [akRight, akBottom]
        Caption = '&Load'
        TabOrder = 2
        OnClick = btnLoadClick
      end
      object btnOK: TButton
        Left = 431
        Top = 372
        Width = 75
        Height = 25
        Anchors = [akRight, akBottom]
        Caption = 'O&K'
        Default = True
        ModalResult = 1
        TabOrder = 3
      end
      object btnCancel: TButton
        Left = 510
        Top = 372
        Width = 75
        Height = 25
        Anchors = [akRight, akBottom]
        Cancel = True
        Caption = '&Cancel'
        ModalResult = 2
        TabOrder = 4
      end
    end
    object tsAbout: TTabSheet
      Caption = '&About'
      ImageIndex = 2
      object LabelProduct: TLabel
        Left = 73
        Top = 66
        Width = 446
        Height = 52
        Caption = 'Delphi IDE Build Events'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBtnText
        Font.Height = -43
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        Transparent = True
      end
      object lblDescription: TLabel
        Left = 124
        Top = 130
        Width = 227
        Height = 19
        Caption = 'Conceptualised and designed by'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelAuthor: TLabel
        Left = 362
        Top = 130
        Width = 103
        Height = 19
        Caption = 'Kiran Kurapaty'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsUnderline]
        ParentFont = False
        Transparent = True
        OnClick = LabelAuthorClick
      end
      object lblFileName: TLabel
        Left = 12
        Top = 192
        Width = 105
        Height = 16
        Caption = 'Configuration File:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object edFileName: TEdit
        Left = 12
        Top = 212
        Width = 569
        Height = 21
        BorderStyle = bsNone
        Color = clBtnFace
        ReadOnly = True
        TabOrder = 0
      end
    end
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = '.ini'
    Filter = 'Configuration files|*.ini|Text Files|*.txt|All Files|*.*'
    Left = 292
    Top = 200
  end
end
