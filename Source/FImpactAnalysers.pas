unit FImpactAnalysers;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Menus
  , FunctionTreeParsers
  , FunctionTreeNodes, Vcl.ExtCtrls
  , ClassTreeNodes, Vcl.Grids
  , DelphiAST.ProjectIndexer
  ;

type
  TReloadFrom = (rfFromEditArea, rfFromFile);

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
    procedure SearchInTree(Sender: TObject);
    procedure EditSearchKeyPress(Sender: TObject; var Key: Char);
    procedure MenuItemGenerateASTXMLClick(Sender: TObject);
    procedure MenuItemUnusedPrivateMethodsClick(Sender: TObject);
    procedure MenuItemOpenDirectoryClick(Sender: TObject);

  private
    FOnlyShowPublicMethod: Boolean;
    FGenerateASTXML: Boolean;
    FFileName: String;
    FFunctionTreeParser: TFunctionTreeParser;

    FIndexer: TProjectIndexer;

    procedure DisplayCursorPositionInStatus;
    procedure UpdateCursorPosition(LineNumber: Integer);

    procedure Parse(ReloadFrom: TReloadFrom);

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
  IOUtils
  , DelphiAST
  , DelphiAST.Classes
  , DelphiAST.Writer
  , SimpleParser.Lexer.Types
  , DelphiAST.SimpleParserEx
  , StrUtils
  , System.Generics.Collections
  , Vcl.FileCtrl
  , DelphiAST.Consts
  ;

{$R *.dfm}

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
    MemoEditor.Lines.Text := TFile.ReadAllText(OpenDialog.FileName);
    FFileName := OpenDialog.FileName;
    Parse(rfFromFile);
  end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.MenuItemOpenDirectoryClick(Sender: TObject);
var
  FoundDirectory: Boolean;
  FileSelector: TFileOpenDialog;
  Index: Integer;
begin
  MemoEditor.Lines.Text := '';
  FFunctionTreeParser.ClearTree;

  FIndexer := TProjectIndexer.Create;
  FileSelector := TFileOpenDialog.Create(Self);

  if FileSelector.Execute then begin
    FIndexer.SearchPath := '../';

    FIndexer.Index(FileSelector.FileName);
  end;

  for Index := 0 to FIndexer.ParsedUnits.Count - 1 do begin
    MemoEditor.Lines.Text := MemoEditor.Lines.Text +
      (FIndexer.ParsedUnits[Index].Name + ' in ' + FIndexer.ParsedUnits[Index].Path);

    MemoEditor.Lines.Text := MemoEditor.Lines.Text +
      ' First child node type: ' + SyntaxNodeNames[FIndexer.ParsedUnits[Index].SyntaxTree.ChildNodes[0].Typ] +
      ' Node Type: ' +  SyntaxNodeNames[FIndexer.ParsedUnits[Index].SyntaxTree.Typ];
  end;

  FFunctionTreeParser.ParseFromProjectIndex(FIndexer);

  DisplayTree;

  FreeAndNil(FileSelector);
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.MenuItemUnusedPrivateMethodsClick(Sender: TObject);
var
  UnusedPrivateMethods: TList<TMethodTreeNode>;
  MethodNode: TMethodTreeNode;
  OutputMessage: String;
begin
  UnusedPrivateMethods := FFunctionTreeParser.GetUnusedPrivateMethods;
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
  try
    Stream := TStringStream.Create;
    try
      if ReloadFrom = rfFromFile then begin
        if FFileName = '' then begin
          Exit;
        end;

        Stream.LoadFromFile(FFileName);
      end
      else begin
        MemoEditor.Lines.SaveToStream(Stream);
      end;
      Builder := TPasSyntaxTreeBuilder.Create;
      Builder.InterfaceOnly := False;
      Builder.OnHandleString := nil;
      Builder.InitDefinesDefinedByCompiler;
      Builder.IncludeHandler := nil;

      SyntaxTree := Builder.Run(Stream);

//      SyntaxTree.Create();

      if FGenerateASTXML then begin
        MemoEditor.Text := TSyntaxTreeWriter.ToXML(SyntaxTree, True);
      end;

      FFunctionTreeParser.ParseFromDelphiAST(SyntaxTree);
      DisplayTree;
    except
      on E: Exception do begin
        ShowMessage(E.Message);
        TreeViewClassTree.Items.Clear;
        MemoEditor.Lines.Text := TSyntaxTreeWriter.ToXML(SyntaxTree, True);
      end;
    end;
  finally
    Stream.Free;
  end;

  FreeAndNil(SyntaxTree);
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.DisplayTree;
var
  Iteration: TClassTreeNode;
begin
  TreeViewClassTree.Items.Clear;
  if not FFunctionTreeParser.IsLoaded then begin
    Exit;
  end;
  for Iteration in FFunctionTreeParser.InFileClassList do begin
    DisplayClassNodeOnTree(Iteration);
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
  Iteration: TMethodTreeNode;
  MethodVisibilitySet: TVisibilityEnumSet;
begin
  if FOnlyShowPublicMethod then begin
    MethodVisibilitySet := [vPublic, vPublished];
  end
  else begin
    MethodVisibilitySet := [Low(TVisibilityEnum)..High(TVisibilityEnum)];
  end;

  FormClassTreeNode := TreeViewClassTree.Items.AddObject(nil, ClassNode.ClassNodeName, ClassNode);
  for Iteration in ClassNode.GetMethodNodeByVisibility(MethodVisibilitySet) do begin
    DisplayMethodNodeOnTreeRecursive(FormClassTreeNode, Iteration);
  end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.DisplayMethodNodeOnTreeRecursive(
  ParentTreeNode: TTreeNode;
  MethodNode: TMethodTreeNode);
var
  FormMethodTreeNode: TTreeNode;
  Iteration: TMethodTreeNode;
begin
  FormMethodTreeNode := TreeViewClassTree.Items.AddChildObject(
    ParentTreeNode, MethodNode.FunctionName, MethodNode);
  for Iteration in MethodNode.MethodCallList do begin
    DisplayMethodNodeOnTreeRecursive(FormMethodTreeNode, Iteration);
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
  CursorCoordinate := MemoEditor.CaretPos;
  StatusBar.SimpleText := IntToStr(CursorCoordinate.Y + 1) + ' : ' + IntToStr(CursorCoordinate.X + 1);
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.UpdateCursorPosition(LineNumber: Integer);
var
  CursorCoordinate: TPoint;
begin
  CursorCoordinate.X := 0;
  CursorCoordinate.Y := LineNumber - 1;
  MemoEditor.CaretPos := CursorCoordinate;
  MemoEditor.SelLength := Length(MemoEditor.Lines[LineNumber - 1]);

  DisplayCursorPositionInStatus;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.TreeViewClassTreeChange(Sender: TObject; Node: TTreeNode);
var
  DataObject: TObject;
begin
  if (not FFunctionTreeParser.IsLoaded) or (not Assigned(Node)) then begin
    HideDisplay;
  end;

  // Expand a node like this:
  // Node.Expanded := True;

  DataObject := TObject(Node.Data);

  if DataObject is TClassTreeNode then begin
    MemoEditor.Text := (DataObject as TClassTreeNode).ClassNodeName;
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

//@TODO: I'm not proud of this method
procedure TImpactAnalyserForm.SearchInTree(Sender: TObject);
var
  SearchNames: TStringList;
  ClassName: String;
  MethodName: String;
  InitialSelectedTreeNode: TTreeNode;
  SelectedTreeNode: TTreeNode;
  IsFromStart: Boolean;
begin
  TreeViewClassTree.SetFocus;
  if TreeViewClassTree.Items.Count = 0 then begin
    Exit;
  end;

  //@TODO: I'm VERY not proud of this method
  SearchNames := TStringList.Create;
  SearchNames.Delimiter := '.';
  SearchNames.DelimitedText := EditSearch.Text;
  if SearchNames.Count = 1 then begin
    MethodName := SearchNames[0];
    ClassName := '';
  end
  else if SearchNames.Count = 2 then begin
    ClassName := SearchNames[0];
    MethodName := SearchNames[1];
    SearchNames.Free;
    // @TODO: Cater class and method search
    Exit;
  end
  else begin
    SearchNames.Free;
    Exit;
  end;
  SearchNames.Free;

  InitialSelectedTreeNode := TreeViewClassTree.Selected;
  IsFromStart := True;
  if Assigned(InitialSelectedTreeNode) then begin
    SelectedTreeNode := InitialSelectedTreeNode.GetNext;
    IsFromStart := False;
  end
  else begin
    SelectedTreeNode := TreeViewClassTree.Items.GetFirstNode;
  end;

  while Assigned(SelectedTreeNode) do begin
    if ContainsStr(SelectedTreeNode.Text.ToUpper, MethodName.ToUpper) then begin
      SelectedTreeNode.Selected := True;
      TreeViewClassTree.Refresh;
      Exit;
    end;
    SelectedTreeNode := SelectedTreeNode.GetNext;
  end;

  if IsFromStart then begin
    Exit;
  end;

  SelectedTreeNode := TreeViewClassTree.Items.GetFirstNode;
  while SelectedTreeNode <> InitialSelectedTreeNode do begin
    if ContainsStr(SelectedTreeNode.Text.ToUpper, MethodName.ToUpper) then begin
      SelectedTreeNode.Selected := True;
      TreeViewClassTree.Refresh;
      Exit;
    end;
    SelectedTreeNode := SelectedTreeNode.GetNext;
  end;
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

procedure TImpactAnalyserForm.TreeViewClassTreeCustomDrawItem(
  Sender: TCustomTreeView;
  Node: TTreeNode;
  State: TCustomDrawState;
  var DefaultDraw: Boolean);
var
  DataObject: TObject;
  MethodNode: TMethodTreeNode;
  SelectedColor: TColor;
begin
  DataObject := TObject(Node.Data);
  SelectedColor := clBlack;
  if DataObject is TClassTreeNode then begin
    Sender.Canvas.Font.Style := [fsBold];
  end
  else if DataObject is TMethodTreeNode then begin
    MethodNode := DataObject as TMethodTreeNode;

    case MethodNode.Visibility of
      vStrictPrivate: SelectedColor := clRed;
      vPrivate: SelectedColor := clRed;
      vStrictProtected: SelectedColor := clBlue;
      vProtected: SelectedColor := clBlue;
      vPublic: SelectedColor := clGreen;
      vPublished: SelectedColor := clPurple;
    end;
    Sender.Canvas.Font.Color := SelectedColor;

    if MethodNode.FunctionType in [ftClassFunction, ftClassProcedure] then begin
      Sender.Canvas.Font.Style := [fsUnderline];
    end;
  end;
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FreeAndNil(FFunctionTreeParser);
end;

//______________________________________________________________________________________________________________________

procedure TImpactAnalyserForm.FormShow(Sender: TObject);
begin
  FFunctionTreeParser := TFunctionTreeParser.Create;
  HideDisplay;
  FFileName := '';
  FGenerateASTXML := False;
  FOnlyShowPublicMethod := False;
  MemoEditor.Lines.Text := '';
end;

end.
