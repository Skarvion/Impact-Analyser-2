﻿unit FImpactAnalysers;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Menus
  , TreeParsers
  , Vcl.ExtCtrls
  , Vcl.Grids
  , SymbolTreeDataObjects
  , DelphiAST.ProjectIndexer
  , Character
  , DelphiAST.Classes
  , StatusModals
  ;

type
  TReloadFrom = (rfFromEditArea, rfFromFile);

  TProjectIndexerThread = class(TThread)
  strict private
    FDprFileName: String;
    FParsedUnitCount: Integer;
    FStatusModal: TStatusFormModal;
    FProjectIndexerResult: TProjectIndexer;
    FTreeParserResult: TTreeParser;

    procedure OnUnitParsedEvent(
      Sender: TObject;
      const UnitName: String;
      const FileName: string;
      var SyntaxTree: TSyntaxNode; SyntaxTreeFromParser: Boolean;
      var doAbort: Boolean
    );

  strict protected
    procedure Execute; override;

  public
    constructor Create(CreateSuspended: Boolean);

    property DprFileName: String write FDprFileName;
    property StatusModal: TStatusFormModal write FStatusModal;
    property ProjectIndexerResult: TProjectIndexer read FProjectIndexerResult;
    property TreeParserResult: TTreeParser read FTreeParserResult;
  end;

  TImpactAnalyserForm = class(TForm)
    StatusBar: TStatusBar;
    MainMenu: TMainMenu;
    MenuItemFile: TMenuItem;
    MenuItemOpen: TMenuItem;
    OpenDialog: TOpenDialog;
    LabelIDCaption: TLabel;
    PanelNodeAttributesContainer: TPanel;
    LabelNameCaption: TLabel;
    LabelTypeCaption: TLabel;
    LabelID: TLabel;
    LabelName: TLabel;
    LabelType: TLabel;
    LabelDeclarationLineCaption: TLabel;
    LabelNodeType: TLabel;
    LabelDeclarationLine: TLabel;
    LabelExtraCaption1: TLabel;
    LabelExtraCaption2: TLabel;
    LabelExtraData1: TLabel;
    LabelExtraData2: TLabel;
    LabelExtraCaption3: TLabel;
    LabelExtraData3: TLabel;
    MenuItemView: TMenuItem;
    MenuItemOnlyShowPublicMethods: TMenuItem;
    ButtonReloadFile: TButton;
    ButtonReloadEditArea: TButton;
    Label1: TLabel;
    PanelTreeViewContainer: TPanel;
    TreeViewClassTree: TTreeView;
    PanelSeachContainer: TPanel;
    EditSearch: TEdit;
    ButtonSearch: TButton;
    MenuItemGenerateASTXML: TMenuItem;
    MenuItemAnalyse: TMenuItem;
    MenuItemUnusedPrivateMethods: TMenuItem;
    MenuItemUncalledPublicMethods: TMenuItem;
    PanelCodeContentContainer: TPanel;
    PanelCodeAnalysisContainer: TPanel;
    SplitterMain: TSplitter;
    SplitterAnalysis: TSplitter;
    MemoEditor: TRichEdit;
    MenuItemOpenDirectory: TMenuItem;
    HideMemo1: TMenuItem;
    HideMemo2: TMenuItem;
    ExportAstAsXmlMenuItem: TMenuItem;

    procedure MemoEditorKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MemoEditorClick(Sender: TObject);
    procedure MenuItemOpenClick(Sender: TObject);
    procedure TreeViewClassTreeCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure TreeViewClassTreeChange(Sender: TObject; Node: TTreeNode);
    procedure FormShow(Sender: TObject);
    procedure MenuItemOnlyShowPublicMethodsClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ButtonReloadFrom(Sender: TObject);
    procedure SearchByClick(Sender: TObject);
    procedure SearchInTree(Sender: TObject);
    procedure EditSearchKeyPress(Sender: TObject; var Key: Char);
    procedure MenuItemGenerateASTXMLClick(Sender: TObject);
    procedure MenuItemUnusedPrivateMethodsClick(Sender: TObject);
    procedure MenuItemOpenDirectoryClick(Sender: TObject);
    procedure TreeViewClassTreeHint(Sender: TObject; const Node: TTreeNode; var Hint: string);
    procedure UpdateNodeText(TreeNode: TTreeNode; TextToAppend: String);
    procedure HideMemoClick(Sender: TObject);
    procedure HideDetailClick(Sender: TObject);
    procedure DefaultHiding(Sender: TObject);
    procedure MenuItemExportAstAsXmlClick(Sender: TObject);


  private
    FOnlyShowPublicMethod: Boolean;
    FGenerateASTXML: Boolean;
    FFileName: String;
    FTreeParser: TTreeParser;

    FIndexer: TProjectIndexer;

    FSyntaxTree: TSyntaxNode;

    FProjectIndexingStatusModal: TStatusFormModal;
    FProjectIndexerThread: TProjectIndexerThread;

    procedure DisplayCursorPositionInStatus;
    procedure UpdateCursorPosition(LineNumber: Integer);

    procedure Parse(ReloadFrom: TReloadFrom);

    procedure OnProjectIndexerThreadDone(Sender: TObject);

    procedure DisplayTree;
    procedure DisplayClassNodeOnTree(
      ClassNode: TClassTreeNode);
    procedure DisplayMethodNodeOnTreeRecursive(
      ParentTreeNode: TTreeNode;
      MethodNode: TMethodTreeNode);

    procedure DisplayClassNodeInformation(ClassNode: TClassTreeNode);
    procedure DisplayMethodNodeInformation(MethodNode: TMethodTreeNode);

    procedure HideDisplay;
  public
    { Public declarations }
  end;

var
  ImpactAnalyserForm: TImpactAnalyserForm;

//______________________________________________________________________________________________________________________

implementation

uses

    DelphiAST.Consts
  , DelphiAST.Writer
  , SimpleParser.Lexer.Types
  , DelphiAST.SimpleParserEx
  , StrUtils
  , System.Generics.Collections
  , Vcl.FileCtrl
  , IOUtils
  , DelphiAST
  , System.UITypes
  ;

{$R *.dfm}


constructor TProjectIndexerThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FDprFileName := '';
  FParsedUnitCount := 0;
  FStatusModal := nil;
  FProjectIndexerResult := nil;
  FTreeParserResult := nil;
end;

procedure TProjectIndexerThread.Execute;
begin
  FProjectIndexerResult := TProjectIndexer.Create;
  FProjectIndexerResult.OnUnitParsed := OnUnitParsedEvent;
  FProjectIndexerResult.SearchPath := // '../';
    '..\..\..\..\..\Transact\Delphi\Common\DatabaseObjects\Source;' +
    '..\..\..\..\..\Transact\Delphi\Common\BusinessHelpers\Source;' +
    '..\..\..\..\..\Mastersystem_V\Delphi\AppMastery\Common\Source;' +
    '..\..\..\..\..\MasterSystem_V\Delphi\WorkspaceFramework\TestHarness\BusinessObjects\Generated;' +
    '..\..\..\..\..\MasterSystem_V\Delphi\WorkspaceFramework\TestHarness;' +
    '..\..\..\..\..\MasterSystem_V\Delphi\Common\Source;..\..\..\..\..\WebMastery\Common\Source';
  FProjectIndexerResult.Index(FDprFileName);

  FStatusModal.SetStatus('Building impact tree');
  FTreeParserResult := TTreeParser.Create;
  FTreeParserResult.ParseFromProjectIndex(FProjectIndexerResult);
end;

procedure TProjectIndexerThread.OnUnitParsedEvent(
  Sender: TObject;
  const UnitName: String;
  const FileName: string;
  var SyntaxTree: TSyntaxNode; SyntaxTreeFromParser: Boolean;
  var doAbort: Boolean
);
begin
  Inc(FParsedUnitCount);
  FStatusModal.SetStatus('Parsed ' + IntToStr(FParsedUnitCount) + ' files');
end;

procedure TImpactAnalyserForm.MenuItemGenerateASTXMLClick(Sender: TObject);
var
  MenuItem: TMenuItem;
begin
  MenuItem := (Sender as TMenuItem);
  MenuItem.Checked := not MenuItem.Checked;

  FGenerateASTXML := MenuItem.Checked;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.MenuItemOnlyShowPublicMethodsClick(Sender: TObject);
var
  MenuItem: TMenuItem;
begin
  MenuItem := (Sender as TMenuItem);
  MenuItem.Checked := not MenuItem.Checked;

  FOnlyShowPublicMethod := MenuItem.Checked;
  DisplayTree;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.MenuItemOpenClick(Sender: TObject);
begin
  if OpenDialog.Execute then begin
//    MemoEditor.Lines.Text := TFile.ReadAllText(OpenDialog.FileName);
    FFileName := OpenDialog.FileName;
    Parse(rfFromFile);
  end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.MenuItemOpenDirectoryClick(Sender: TObject);
var
  FileSelector: TFileOpenDialog;
  FileName: String;
begin
  FileSelector := TFileOpenDialog.Create(Self);
  if FileSelector.Execute then begin
    FileName := FileSelector.FileName;
    FreeAndNil(FileSelector);
  end
  else begin
    FreeAndNil(FileSelector);
    Exit;
  end;

  FreeAndNil(FTreeParser);
  FreeAndNil(FIndexer);

  FProjectIndexingStatusModal := TStatusFormModal.Create(Application);

  FProjectIndexerThread := TProjectIndexerThread.Create(True);
  FProjectIndexerThread.FreeOnTerminate := True;
  FProjectIndexerThread.DprFileName := FileName;
  FProjectIndexerThread.StatusModal := FProjectIndexingStatusModal;
  FProjectIndexerThread.OnTerminate := OnProjectIndexerThreadDone;
  FProjectIndexerThread.Start;

  try
    FProjectIndexingStatusModal.ShowModal;
  finally
    FreeAndNil(FProjectIndexingStatusModal);
  end;

  DisplayTree;
end;

procedure TImpactAnalyserForm.OnProjectIndexerThreadDone(Sender: TObject);
begin
  FIndexer := FProjectIndexerThread.ProjectIndexerResult;
  FTreeParser := FProjectIndexerThread.TreeParserResult;
  FProjectIndexingStatusModal.Close;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.MenuItemUnusedPrivateMethodsClick(Sender: TObject);
var
  UnusedPrivateMethods: TList<TMethodTreeNode>;
  MethodNode: TMethodTreeNode;
  OutputMessage: String;
begin
  UnusedPrivateMethods := FTreeParser.GetUnusedPrivateMethods;
  OutputMessage := '';
  for MethodNode in UnusedPrivateMethods do begin
    OutputMessage := OutputMessage + '- ' + MethodNode.FunctionName + sLineBreak;
  end;

  if OutputMessage = '' then begin
    ShowMessage('All methods are being used');
  end
  else begin
    ShowMessage(OutputMessage);
  end;
end;

//______________________________________________________________________________________________________________________



procedure TImpactAnalyserForm.Parse(ReloadFrom: TReloadFrom);
var
  Stream: TStringStream;
  Builder: TPasSyntaxTreeBuilder;
  SyntaxTree: TSyntaxNode;
begin
  Stream := nil;

  try
    // read from code file
    Stream := TStringStream.Create;
    try
      if ReloadFrom = rfFromFile then begin
        if FFileName = '' then begin
          Exit;
        end;

        Stream.LoadFromFile(FFileName);
      end
      else begin
//        MemoEditor.Lines.SaveToStream(Stream);
      end;

      // Init the AST syntax tree builder (big tree builder)
      Builder := TPasSyntaxTreeBuilder.Create;
      Builder.InterfaceOnly := False;
      Builder.OnHandleString := nil;
      Builder.InitDefinesDefinedByCompiler;
      Builder.IncludeHandler := nil;

      // Build big tree
      SyntaxTree := Builder.Run(Stream);
      FSyntaxTree := SyntaxTree;

      if FGenerateASTXML then begin
//        MemoEditor.Text := TSyntaxTreeWriter.ToXML(SyntaxTree, True);
      end;

      // Build small tree
      FTreeParser.ParseFromDelphiAST(SyntaxTree);

      DisplayTree;
    except
      on E: Exception do begin
        ShowMessage(E.Message);
        TreeViewClassTree.Items.Clear;
//        MemoEditor.Lines.Text := TSyntaxTreeWriter.ToXML(SyntaxTree, True);
      end;
    end;
  finally
    FreeAndNil(Stream);
  end;

  //FreeAndNil(SyntaxTree);
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.DisplayTree;
var
  ClassNodes: TObjectList<TClassTreeNode>;
  ClassNode: TClassTreeNode;
begin
  TreeViewClassTree.Items.Clear;
  if not FTreeParser.IsLoaded then begin
    Exit;
  end;

  // Use FunctionTreeParser's InFileClass List to display each node on tree
  for ClassNodes in FTreeParser.ClassNodesDictionary.Values do begin
    for ClassNode in ClassNodes do begin
      DisplayClassNodeOnTree(ClassNode);
    end;
  end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.EditSearchKeyPress(Sender: TObject; var Key: Char);
begin
  if Ord(Key) = VK_RETURN then begin
    Key := #0; // prevent beeping
    SearchInTree(nil);
  end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.DisplayClassNodeOnTree(
  ClassNode: TClassTreeNode);
var
  FormClassTreeNode: TTreeNode;
  MethodNode: TMethodTreeNode;
  MethodVisibilitySet: TVisibilityEnumSet;
begin
  if FOnlyShowPublicMethod then begin
    MethodVisibilitySet := [vPublic, vPublished];
  end
  else begin
    MethodVisibilitySet := [Low(TVisibilityEnum)..High(TVisibilityEnum)];
  end;

  // Add this ClassNode to the TTreeView tree
  FormClassTreeNode := TreeViewClassTree.Items.AddObject(nil, ClassNode.ClassNodeName, ClassNode);


  // Add each Method Node for this Class Node to the TTreeView recursively
  for MethodNode in ClassNode.GetMethodNodeByVisibility(MethodVisibilitySet) do begin
    DisplayMethodNodeOnTreeRecursive(FormClassTreeNode, MethodNode);
  end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.DisplayMethodNodeOnTreeRecursive(
  ParentTreeNode: TTreeNode;
  MethodNode: TMethodTreeNode);
var
  FormMethodTreeNode: TTreeNode;
  MethodNodeCalledWithinThisMethodNode: TMethodTreeNode;
  ColonReturn: String;
begin
  // Add this method as a child of the TTree class node
  ColonReturn := '';

  if not (MethodNode.Return = '') then begin
    ColonReturn := ': '
  end;
  FormMethodTreeNode := TreeViewClassTree.Items.AddChildObject(
    ParentTreeNode,
    MethodNode.OwnerClassNode.ClassNodeName + '.' + MethodNode.FunctionName + ColonReturn + MethodNode.Return,
    MethodNode
  );

  for MethodNodeCalledWithinThisMethodNode in MethodNode.MethodsCalledWithinThisMethod do begin
    DisplayMethodNodeOnTreeRecursive(FormMethodTreeNode, MethodNodeCalledWithinThisMethodNode);
  end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.MemoEditorClick(Sender: TObject);
begin
  DisplayCursorPositionInStatus;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.MemoEditorKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  DisplayCursorPositionInStatus;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.DisplayCursorPositionInStatus;
var
  CursorCoordinate: TPoint;
begin
//  CursorCoordinate := MemoEditor.CaretPos;
  StatusBar.SimpleText := IntToStr(CursorCoordinate.Y + 1) + ' : ' + IntToStr(CursorCoordinate.X + 1);
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.UpdateCursorPosition(LineNumber: Integer);
var
  CursorCoordinate: TPoint;
begin
  CursorCoordinate.X := 0;
  CursorCoordinate.Y := LineNumber - 1;
//  MemoEditor.CaretPos := CursorCoordinate;
//  MemoEditor.SelLength := Length(MemoEditor.Lines[LineNumber - 1]);

  DisplayCursorPositionInStatus;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.TreeViewClassTreeChange(Sender: TObject; Node: TTreeNode);
var
  DataObject: TObject;
begin
  if (not FTreeParser.IsLoaded) or (not Assigned(Node)) then begin
    HideDisplay;
  end;

  // Expand a node like this:
  // Node.Expanded := True;

  DataObject := TObject(Node.Data);

  if DataObject is TClassTreeNode then begin
//    MemoEditor.Text := (DataObject as TClassTreeNode).ClassNodeName;
    DisplayClassNodeInformation(DataObject as TClassTreeNode);
  end
  else if DataObject is TMethodTreeNode then begin
    DisplayMethodNodeInformation(DataObject as TMethodTreeNode);
  end
  else begin
    HideDisplay;
  end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.ButtonReloadFrom(Sender: TObject);
var
  ReloadFrom: TReloadFrom;
begin
  if Sender = ButtonReloadEditArea then begin
    ReloadFrom := rfFromEditArea;
  end
  else begin
    ReloadFrom := rfFromFile;
  end;

  Parse(ReloadFrom);
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.SearchByClick(Sender: TObject);
var
  SearchNames: TStringList;
  ClassName: String;
  MethodName: String;
  InitialSelectedTreeNode: TTreeNode;
  SelectedTreeNode: TTreeNode;
  IsFromStart: Boolean;
  Iteration: TSyntaxNode;
begin

  SearchNames := TStringList.Create;
  SearchNames.Delimiter := '.';
  SearchNames.DelimitedText := EditSearch.Text;
  LabelNameCaption.Caption := 'aaaaaa';


//  for Iteration in FSyntaxTree.ChildNodes do begin
//     LabelNameCaption.Caption := Iteration.Typ;
//
//  end;

  //FSyntaxTree.ChildNodes




  //SearchNames.Free;

end;

//______________________________________________________________________________________________________________________

//@TODO: I'm not proud of this method
procedure TImpactAnalyserForm.SearchInTree(Sender: TObject);
var
  SearchNames: TStringList;
  ClassName: String;
  MethodName: String;
  InitialSelectedTreeNode: TTreeNode;
  SelectedTreeNode: TTreeNode;
  IsFromStart: Boolean;
  aNode: TTreeNode;
begin
  TreeViewClassTree.SetFocus;
  if TreeViewClassTree.Items.Count = 0 then begin
    Exit;
  end;
//  //@TODO: I'm VERY not proud of this method
//  SearchNames := TStringList.Create;
//  SearchNames.Delimiter := '.';
//  SearchNames.DelimitedText := EditSearch.Text;
//  if SearchNames.Count = 1 then begin
//    MethodName := SearchNames[0];
//    ClassName := '';
//  end
//  else if SearchNames.Count = 2 then begin
//    ClassName := SearchNames[0];
//    MethodName := SearchNames[1];
//    SearchNames.Free;
//    // @TODO: Cater class and method search
//    Exit;
//  end
//  else begin
//    SearchNames.Free;
//    Exit;
//  end;
//  SearchNames.Free;
  MethodName := EditSearch.Text;
  InitialSelectedTreeNode := TreeViewClassTree.TopItem;
  while Assigned(InitialSelectedTreeNode) do begin
    if TObject(InitialSelectedTreeNode.Data) is TClassTreeNode then begin
      (TObject(InitialSelectedTreeNode.Data) as TClassTreeNode).Selected := False;
    end
    else begin
      (TObject(InitialSelectedTreeNode.Data) as TMethodTreeNode).Selected := False;
    end;
    if ContainsStr(InitialSelectedTreeNode.Text.ToUpper, MethodName.ToUpper) then begin
      if TObject(InitialSelectedTreeNode.Data) is TClassTreeNode then begin
        (TObject(InitialSelectedTreeNode.Data) as TClassTreeNode).Selected := True;
      end
      else begin
        (TObject(InitialSelectedTreeNode.Data) as TMethodTreeNode).Selected := True;
      end;
      InitialSelectedTreeNode.Expanded := true;
      aNode := InitialSelectedTreeNode.Parent;
      while aNode <> nil do begin
        aNode.Expanded := True;
        aNode := aNode.Parent;
      end;
    end;
    InitialSelectedTreeNode := InitialSelectedTreeNode.GetNext;
  end;
  TreeViewClassTree.Refresh;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.DisplayClassNodeInformation(ClassNode: TClassTreeNode);
begin
  LabelNodeType.Caption := 'CLASS NODE';
  LabelID.Caption := IntToStr(ClassNode.ID);
  LabelName.Caption := ClassNode.ClassNodeName;
  LabelType.Caption := TClassTreeNode.C_ClassNodeTypeString[ClassNode.ClassNodeType];
  LabelDeclarationLine.Caption := IntToStr(ClassNode.DeclarationLine);

  LabelExtraCaption1.Caption := 'METHOD COUNT';
  LabelExtraCaption1.Visible := True;
  LabelExtraCaption2.Visible := False;
  LabelExtraCaption3.Visible := False;
  LabelExtraData1.Caption := IntToStr(ClassNode.MethodList.Count);
  LabelExtraData1.Visible := True;
  LabelExtraData2.Visible := False;
  LabelExtraData3.Visible := False;

  UpdateCursorPosition(ClassNode.DeclarationLine);
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.DisplayMethodNodeInformation(MethodNode: TMethodTreeNode);
begin
  LabelNodeType.Caption := 'METHOD NODE';
  LabelID.Caption := IntToStr(MethodNode.ID);
  LabelName.Caption := MethodNode.FunctionName;
  LabelType.Caption := TMethodTreeNode.C_FunctionTypeString[MethodNode.FunctionType];
  LabelDeclarationLine.Caption := IntToStr(MethodNode.DeclarationLine);

  LabelExtraCaption1.Caption := 'VISIBILITY';
  LabelExtraCaption1.Visible := True;
  LabelExtraCaption2.Caption := 'IMPLEMENTATION LINE';
  LabelExtraCaption2.Visible := True;
  LabelExtraCaption3.Caption := 'HAS RECURSION';
  LabelExtraCaption3.Visible := True;
  LabelExtraData1.Caption := TMethodTreeNode.C_VisibilityTypeString[MethodNode.Visibility];
  LabelExtraData1.Visible := True;
  LabelExtraData2.Caption := IntToStr(MethodNode.ImplementationLine);
  LabelExtraData2.Visible := True;
  LabelExtraData3.Caption := IfThen(MethodNode.HasRecursion, 'YES', 'NO');
  LabelExtraData3.Visible := True;

  UpdateCursorPosition(MethodNode.ImplementationLine);
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.HideDisplay;
begin
  LabelNodeType.Caption := 'NO SELECTED NODE';
  LabelID.Caption := '-';
  LabelName.Caption := '-';
  LabelType.Caption := '-';
  LabelDeclarationLine.Caption := '-';

  LabelExtraCaption1.Visible := False;
  LabelExtraCaption2.Visible := False;
  LabelExtraCaption3.Visible := False;
  LabelExtraData1.Visible := False;
  LabelExtraData2.Visible := False;
  LabelExtraData3.Visible := False;
end;
//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.DefaultHiding(Sender: TObject);
begin
     MemoEditor.Visible := False;
     PanelCodeContentContainer.Visible := False;
     PanelNodeAttributesContainer.Visible := False;
end;
//______________________________________________________________________________________________________________________
procedure TImpactAnalyserForm.HideMemoClick(Sender: TObject);
begin
     if (Sender as TMenuItem).Checked  then begin
         MemoEditor.Visible := True;
         PanelCodeContentContainer.Visible := True;
        (Sender as TMenuItem).Checked := False;
     end
     else if not (Sender as TMenuItem).Checked  then begin
         MemoEditor.Visible := False;
         PanelCodeContentContainer.Visible := False;
        (Sender as TMenuItem).Checked := True;
     end;
end;
//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.HideDetailClick(Sender: TObject);
begin
        if (Sender as TMenuItem).Checked  then begin
         PanelNodeAttributesContainer.Visible := True;
        (Sender as TMenuItem).Checked := False;
     end
     else if not (Sender as TMenuItem).Checked  then begin
         PanelNodeAttributesContainer.Visible := False;
        (Sender as TMenuItem).Checked := True;
     end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.TreeViewClassTreeCustomDrawItem(
  Sender: TCustomTreeView;
  Node: TTreeNode;
  State: TCustomDrawState;
  var DefaultDraw: Boolean);
var
  DataObject: TObject;
  MethodNode: TMethodTreeNode;
  SelectedColor: TColor;
  aNode : TTreeNode;
begin
  DataObject := TObject(Node.Data);
  SelectedColor := clBlack;

  if DataObject is TClassTreeNode then begin
    Sender.Canvas.Font.Style := [fsBold];
    UpdateNodeText(Node,'📁 ');
  end
  else if DataObject is TMethodTreeNode then begin
    MethodNode := DataObject as TMethodTreeNode;

    case MethodNode.Visibility of
      vStrictPrivate:
      begin
        SelectedColor := clRed;
        UpdateNodeText(Node, '🔒 ');
      end;
      vPrivate:
      begin
        SelectedColor := clRed;
        UpdateNodeText(Node, '🔒 ');
      end;
      vStrictProtected:
      begin
        SelectedColor := clBlue;
        UpdateNodeText(Node, '🛡 ');
      end;
      vProtected:
      begin
        SelectedColor := clBlue;
        UpdateNodeText(Node, '🛡 ');
      end;
      vPublic:
      begin
        SelectedColor := clGreen;
        UpdateNodeText(Node, '🌎 ');
      end;
      vPublished:
      begin
        SelectedColor := clPurple;
        UpdateNodeText(Node, '📖 ');
      end;
    end;


    if MethodNode.Selected then begin
       Sender.Canvas.Brush.Color := cl3DLight;
       Sender.Canvas.FillRect(Node.DisplayRect(True));
    end;


    Sender.Canvas.Font.Color := SelectedColor;

    if MethodNode.FunctionType in [ftClassFunction, ftClassProcedure] then begin
      Sender.Canvas.Font.Style := [fsUnderline];
    end;



  end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.UpdateNodeText(TreeNode: TTreeNode; TextToAppend: String);
begin
  if TreeNode.Text[1].IsLetter then
  begin
    TreeNode.Text := TextToAppend + TreeNode.Text;
    TreeNode.TreeView.Invalidate;
  end;
end;
//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.TreeViewClassTreeHint(Sender: TObject; const Node: TTreeNode; var Hint: string);
var
  DataObject: TObject;
  ClassString: String;
  MethodString: String;
  ClassHintString: String;
  MethodHintString: String;
  ClassNode: TClassTreeNode;
  MethodNode: TMethodTreeNode;
begin
  DataObject := TObject(Node.Data);
  // Clear the hint initially
  Hint := '';
  if DataObject is TClassTreeNode then begin
  //show information about class in the statusbar
    ClassNode := (DataObject as TClassTreeNode);
    ClassString := Format('Class: %s | Declared on Line: %d | Has %d methods', [ClassNode.ClassNodeName,
                                                                                ClassNode.DeclarationLine,
                                                                                ClassNode.MethodList.Count]);
    ClassHintString := Format('Line: %d | Has %d methods', [ClassNode.DeclarationLine,
                                                                                ClassNode.MethodList.Count]);
    StatusBar.SimpleText := ClassString;
    Hint :=  ClassHintString;
  end
  else if DataObject is TMethodTreeNode then begin
  //show information about method in the status bar
   MethodNode :=  (DataObject as TMethodTreeNode);
   MethodString := Format('Method: %s | Declared on Line: %d | Type: %s | Visibility: %s | Implemented on Line: %d | Has Recursion: %s', [MethodNode.FunctionName,
                                                                                                                                          MethodNode.DeclarationLine,
                                                                                                                                          TMethodTreeNode.C_FunctionTypeString[MethodNode.FunctionType],
                                                                                                                                          TMethodTreeNode.C_VisibilityTypeString[MethodNode.Visibility],
                                                                                                                                          MethodNode.ImplementationLine,
                                                                                                                                          IfThen(MethodNode.HasRecursion, 'YES', 'NO')]);
    MethodHintString := Format('Declared on Line: %d | Implemented on Line: %d', [MethodNode.DeclarationLine,
                                                                             MethodNode.ImplementationLine]);
    StatusBar.SimpleText := MethodString;
    Hint :=  MethodHintString;
  end
end;



//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FreeAndNil(FIndexer);
  FreeAndNil(FTreeParser);
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.FormShow(Sender: TObject);
begin
  FTreeParser := TTreeParser.Create;
  HideDisplay;
  FFileName := '';
  FGenerateASTXML := False;
  FOnlyShowPublicMethod := False;
//  MemoEditor.Lines.Text := '';
end;

procedure TImpactAnalyserForm.MenuItemExportAstAsXmlClick(Sender: TObject);
var
  FileSaveDialog: TFileSaveDialog;
  FileWriter: TStreamWriter;
begin
  if not Assigned(FTreeParser) then begin
    Exit;
  end
  else if FTreeParser.UnitNodes.Count <> 1 then begin
    MessageDlg('To export as XML, please only load 1 file', mtInformation, [TMsgDlgBtn.mbOK], 0);
    Exit;
  end;

  FileSaveDialog := TFileSaveDialog.Create(Self);
  if not FileSaveDialog.Execute then begin
    Exit;
  end;

  Assert(FTreeParser.UnitNodes.Count = 1, 'Should only have 1 unit loaded at this point');

  FileWriter := nil;
  try
    FileWriter := TStreamWriter.Create(FileSaveDialog.FileName);
    FileWriter.Write(TSyntaxTreeWriter.ToXML(FTreeParser.UnitNodes.Values.ToArray[0].RootSyntaxNode, True));
  finally
    FreeAndNil(FileWriter);
  end;
end;

end.
