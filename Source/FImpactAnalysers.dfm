object ImpactAnalyserForm: TImpactAnalyserForm
  Left = 0
  Top = 0
  Caption = 'Impact Analyser'
  ClientHeight = 757
  ClientWidth = 1245
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label10: TLabel
    Left = 182
    Top = 142
    Width = 160
    Height = 19
    Caption = '#DECLARATION LINE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label11: TLabel
    Left = 22
    Top = 142
    Width = 113
    Height = 19
    Caption = 'Declaration Line'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 738
    Width = 1245
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object GridPanel1: TGridPanel
    Left = 0
    Top = 0
    Width = 1245
    Height = 738
    Align = alClient
    Caption = 'GridPanel1'
    ColumnCollection = <
      item
        Value = 58.333333333333340000
      end
      item
        Value = 41.666666666666660000
      end>
    ControlCollection = <
      item
        Column = 0
        Control = MemoEditor
        Row = 0
        RowSpan = 2
      end
      item
        Column = 1
        Control = Panel1
        Row = 1
      end
      item
        Column = 1
        Control = PanelTreeViewContainer
        Row = 0
      end>
    RowCollection = <
      item
        Value = 100.000000000000000000
      end
      item
        SizeStyle = ssAbsolute
        Value = 200.000000000000000000
      end
      item
        SizeStyle = ssAuto
      end>
    TabOrder = 0
    object MemoEditor: TMemo
      Left = 1
      Top = 1
      Width = 725
      Height = 736
      Align = alClient
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Consolas'
      Font.Style = []
      Lines.Strings = (
        '')
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 0
      OnClick = MemoEditorClick
      OnKeyUp = MemoEditorKeyUp
    end
    object Panel1: TPanel
      Left = 726
      Top = 537
      Width = 518
      Height = 200
      Align = alClient
      Alignment = taLeftJustify
      Anchors = []
      TabOrder = 2
      DesignSize = (
        518
        200)
      object LabelIDCaption: TLabel
        Left = 14
        Top = 28
        Width = 12
        Height = 16
        Caption = 'ID'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelNameCaption: TLabel
        Left = 14
        Top = 50
        Width = 33
        Height = 16
        Caption = 'NAME'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelTypeCaption: TLabel
        Left = 14
        Top = 72
        Width = 29
        Height = 16
        Caption = 'TYPE'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelID: TLabel
        Left = 206
        Top = 30
        Width = 21
        Height = 16
        Caption = '#ID'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelName: TLabel
        Left = 206
        Top = 50
        Width = 42
        Height = 16
        Caption = '#NAME'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelType: TLabel
        Left = 206
        Top = 72
        Width = 38
        Height = 16
        Caption = '#TYPE'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelDeclarationLineCaption: TLabel
        Left = 14
        Top = 94
        Width = 111
        Height = 16
        Caption = 'DECLARATION LINE'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelNodeType: TLabel
        Left = 14
        Top = 6
        Width = 68
        Height = 16
        Caption = 'NODE TYPE'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object LabelDeclarationLine: TLabel
        Left = 206
        Top = 94
        Width = 120
        Height = 16
        Caption = '#DECLARATION LINE'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelExtraCaption1: TLabel
        Left = 14
        Top = 116
        Width = 34
        Height = 16
        Caption = 'LABEL'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelExtraCaption2: TLabel
        Left = 14
        Top = 138
        Width = 34
        Height = 16
        Caption = 'LABEL'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelExtraData1: TLabel
        Left = 206
        Top = 116
        Width = 43
        Height = 16
        Caption = '#LABEL'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelExtraData2: TLabel
        Left = 206
        Top = 138
        Width = 43
        Height = 16
        Caption = '#LABEL'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelExtraCaption3: TLabel
        Left = 14
        Top = 160
        Width = 34
        Height = 16
        Caption = 'LABEL'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object LabelExtraData3: TLabel
        Left = 206
        Top = 160
        Width = 43
        Height = 16
        Caption = '#LABEL'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Label1: TLabel
        Left = 350
        Top = 6
        Width = 75
        Height = 16
        Anchors = [akTop, akRight]
        Caption = 'Reload from:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object ButtonReloadFile: TButton
        Left = 427
        Top = 25
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'File'
        TabOrder = 0
        OnClick = ButtonReloadFrom
      end
      object ButtonReloadEditArea: TButton
        Left = 346
        Top = 25
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Edit Area'
        TabOrder = 1
        OnClick = ButtonReloadFrom
      end
    end
    object PanelTreeViewContainer: TPanel
      Left = 726
      Top = 1
      Width = 518
      Height = 536
      Align = alClient
      Alignment = taLeftJustify
      TabOrder = 1
      object TreeViewClassTree: TTreeView
        Left = 1
        Top = 21
        Width = 516
        Height = 514
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = []
        Indent = 19
        ParentFont = False
        TabOrder = 0
        OnChange = TreeViewClassTreeChange
        OnCustomDrawItem = TreeViewClassTreeCustomDrawItem
        OnKeyPress = EditSearchKeyPress
      end
      object PanelFlowPanelPanel2: TPanel
        Left = 1
        Top = 1
        Width = 516
        Height = 20
        Align = alTop
        Caption = 'PanelFlowPanelPanel2'
        ParentBackground = False
        TabOrder = 1
        object EditSearch: TEdit
          Left = 1
          Top = 1
          Width = 414
          Height = 18
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          TextHint = 'Search'
          OnKeyPress = EditSearchKeyPress
        end
        object ButtonSearch: TButton
          Left = 415
          Top = 1
          Width = 100
          Height = 18
          Align = alRight
          Caption = 'Search'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          OnClick = SearchInTree
        end
      end
    end
  end
  object MainMenu: TMainMenu
    Left = 16
    Top = 16
    object MenuItemFile: TMenuItem
      Caption = 'File'
      object MenuItemOpen: TMenuItem
        Caption = 'Open...'
        OnClick = MenuItemOpenClick
      end
    end
    object MenuItemView: TMenuItem
      Caption = 'View'
      object MenuItemOnlyShowPublicMethods: TMenuItem
        Caption = 'Only show public methods'
        OnClick = MenuItemOnlyShowPublicMethodsClick
      end
      object MenuItemGenerateASTXML: TMenuItem
        Caption = 'Generate AST XML'
        OnClick = MenuItemGenerateASTXMLClick
      end
    end
    object MenuItemAnalyse: TMenuItem
      Caption = 'Analyse'
      object MenuItemUnusedPrivateMethods: TMenuItem
        Caption = 'List unused private methods'
        OnClick = MenuItemUnusedPrivateMethodsClick
      end
      object MenuItemUncalledPublicMethods: TMenuItem
        Caption = 'List uncalled public methods (WIP)'
      end
    end
  end
  object OpenDialog: TOpenDialog
    Left = 64
    Top = 16
  end
end
