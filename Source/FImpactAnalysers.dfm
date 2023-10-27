object ImpactAnalyserForm: TImpactAnalyserForm
  Left = 0
  Top = 0
  Caption = 'Impact Analyser'
  ClientHeight = 718
  ClientWidth = 1233
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OnClose = FormClose
  OnCreate = DefaultHiding
  OnMouseEnter = MenuItemOpenDirectoryClick
  OnShow = FormShow
  TextHeight = 13
  object SplitterMain: TSplitter
    Left = 617
    Top = 0
    Height = 699
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 699
    Width = 1233
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object PanelCodeAnalysisContainer: TPanel
    Left = 620
    Top = 0
    Width = 613
    Height = 699
    Align = alClient
    Caption = 'PanelCodeAnalysisContainer'
    TabOrder = 1
    object SplitterAnalysis: TSplitter
      Left = 1
      Top = 336
      Width = 615
      Height = 3
      Cursor = crVSplit
      Align = alBottom
    end
    object PanelNodeAttributesContainer: TPanel
      Left = 1
      Top = 339
      Width = 615
      Height = 360
      Align = alBottom
      TabOrder = 0
      DesignSize = (
        611
        360)
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
        Left = 429
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
        Left = 506
        Top = 25
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'File'
        TabOrder = 0
        OnClick = ButtonReloadFrom
      end
      object ButtonReloadEditArea: TButton
        Left = 425
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
      Left = 1
      Top = 1
      Width = 611
      Height = 334
      Align = alClient
      TabOrder = 1
      object TreeViewClassTree: TTreeView
        Left = 1
        Top = 25
        Width = 613
        Height = 309
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
        OnHint = TreeViewClassTreeHint
        OnKeyPress = EditSearchKeyPress
      end
      object PanelSeachContainer: TPanel
        Left = 1
        Top = 1
        Width = 609
        Height = 24
        Align = alTop
        ParentBackground = False
        TabOrder = 1
        object EditSearch: TEdit
          Left = 1
          Top = 1
          Width = 511
          Height = 22
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
          Left = 512
          Top = 1
          Width = 100
          Height = 22
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
  object PanelCodeContentContainer: TPanel
    Left = 0
    Top = 0
    Width = 617
    Height = 699
    Align = alLeft
    Caption = 'PanelCodeContentContainer'
    TabOrder = 2
    object MemoEditor: TRichEdit
      Left = 1
      Top = 1
      Width = 615
      Height = 698
      Align = alClient
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      HideSelection = False
      HideScrollBars = False
      Lines.Strings = (
        'MemoEditor')
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
    end
  end
  object MainMenu: TMainMenu
    Left = 64
    Top = 616
    object MenuItemFile: TMenuItem
      Caption = 'File'
      object MenuItemOpen: TMenuItem
        Caption = 'Open...'
        OnClick = MenuItemOpenClick
      end
      object MenuItemOpenDirectory: TMenuItem
        Caption = 'Open Directory...'
        OnClick = MenuItemOpenDirectoryClick
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
      object HideMemo1: TMenuItem
        Caption = 'Hide Memo'
        Checked = True
        OnClick = HideMemoClick
      end
      object HideMemo2: TMenuItem
        Caption = 'Hide Detailed Panel'
        Checked = True
        OnClick = HideDetailClick
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
    object TMenuItem
    end
  end
  object OpenDialog: TOpenDialog
    Left = 176
    Top = 616
  end
end
