unit FunctionTreeParsers;

interface

uses
    System.Generics.Collections
  , ClassTreeNodes
  , FunctionTreeNodes
  , DelphiAST.Classes
  , DelphiAST.Consts
  , DelphiAST.ProjectIndexer
  ;

type

  TFunctionTreeParser = class(TObject)
  private
    FIDKeyCount: Integer;
    FInFileClassList: TObjectList<TClassTreeNode>;
    FIsLoaded: Boolean;

    // Class definition from Delphi AST
    FRootSyntaxNode: TSyntaxNode;

    FSyntaxNodeDict: TDictionary<String, TSyntaxNode>;

    FClassNodes: TObjectList<TClassTreeNode>;

    FUncateredMethods: TList<TSyntaxNode>;

    function CreateClassTreeNode(
      ClassName: String;
      ClassType: TClassNodeTypeEnum;
      DeclarationLine: Integer;
      OwnerClassNode: TClassTreeNode
    ): TClassTreeNode;
    function CreateFunctionTreeNode(
      FunctionName: String;
      FunctionType: TFunctionTypeEnum;
      Visibility: TVisibilityEnum;
      DeclarationLine: Integer = 1;
      ImplementationLine: Integer = 1): TMethodTreeNode;

    procedure PopulateClassAndMethodList;
    function ProcessTypeDeclaration(
      TypeDeclarationNode: TSyntaxNode;
      OwnerClassNode: TClassTreeNode
    ): TClassTreeNode;
    procedure ProcessClassMethodListByVisibility(
      ClassTreeNode: TClassTreeNode;
      SyntaxNode: TSyntaxNode);

    procedure PopulateMethodImplementation;
    function GetClassNode(ClassHierarchy: TList<String>): TClassTreeNode;
    procedure ProcessMethod(
      ClassNode: TClassTreeNode;
      MethodNode: TMethodTreeNode;
      SyntaxNode: TSyntaxNode);
    procedure RecurseAddCallMethod(
      ClassNode: TClassTreeNode;
      SelectedMethodNode: TMethodTreeNode;
      SyntaxNode: TSyntaxNode);

    // More Delphi AST specific implementation
    class function GetFunctionTreeVisibility(SyntaxNodeType: TSyntaxNodeType): TVisibilityEnum;
    class function GetMethodType(SyntaxNode: TSyntaxNode): TFunctionTypeEnum;

    public
      constructor Create;
      destructor Destroy; override;

      procedure ParseFromProjectIndex(ProjectIndex: TProjectIndexer);
      procedure ParseFromDelphiAST(SyntaxNode: TSyntaxNode);
      procedure ClearTree;

      function GetUnusedPrivateMethods: TList<TMethodTreeNode>;

      property InFileClassList: TObjectList<TClassTreeNode> read FInFileClassList;
      property IsLoaded: Boolean read FIsLoaded;
  end;

implementation

uses
    Classes
  , SysUtils
  , StrUtils
  , System.RegularExpressions
  , NodeUtils
  ;

{ TFunctionTreeParser }

constructor TFunctionTreeParser.Create;
begin
  FIDKeyCount := 0;
  FInFileClassList := TObjectList<TClassTreeNode>.Create(True);
  FIsLoaded := False;

  FUncateredMethods := TList<TSyntaxNode>.Create;

  FClassNodes := TObjectList<TClassTreeNode>.Create(False);
end;

destructor TFunctionTreeParser.Destroy;
begin
  ClearTree;
  FreeAndNil(FUncateredMethods);
  FreeAndNil(FInFileClassList);
  FreeAndNil(FClassNodes);
  inherited;
end;

function TFunctionTreeParser.CreateClassTreeNode(
  ClassName: String;
  ClassType: TClassNodeTypeEnum;
  DeclarationLine: Integer;
  OwnerClassNode: TClassTreeNode
): TClassTreeNode;
begin
  Result := TClassTreeNode.Create(
    FIDKeyCount,
    ClassName,
    ClassType,
    DeclarationLine,
    OwnerClassNode
  );

  Inc(FIDKeyCount);
  FClassNodes.Add(Result);
end;

function TFunctionTreeParser.CreateFunctionTreeNode(
  FunctionName: String;
  FunctionType: TFunctionTypeEnum;
  Visibility: TVisibilityEnum;
  DeclarationLine: Integer = 1;
  ImplementationLine: Integer = 1): TMethodTreeNode;
begin
  Result := TMethodTreeNode.Create;
  Result.ID := FIDKeyCount;
  Result.FunctionName := FunctionName;
  Result.FunctionType := FunctionType;
  Result.Visibility := Visibility;
  Result.DeclarationLine := DeclarationLine;
  Result.ImplementationLine := ImplementationLine;

  Inc(FIDKeyCount);
end;

class function TFunctionTreeParser.GetFunctionTreeVisibility(
  SyntaxNodeType: TSyntaxNodeType): TVisibilityEnum;
begin
  case SyntaxNodeType of
    ntStrictPrivate: Result := vStrictPrivate;
    ntPrivate: Result := vPrivate;
    ntStrictProtected: Result := vStrictProtected;
    ntProtected: Result := vProtected;
    ntPublic: Result := vPublic;
    ntPublished: Result := vPublished;
    else raise Exception.Create(
      'Cannot convert syntax node type to visibility. Shouldnt be able to trigger this');
  end;
end;

class function TFunctionTreeParser.GetMethodType(SyntaxNode: TSyntaxNode): TFunctionTypeEnum;
var
  Kind: String;
  IsClass: String;
begin
  Kind := SyntaxNode.GetAttribute(anKind);
  IsClass := SyntaxNode.GetAttribute(anClass);

  if SameText(Kind, 'function') and SameText(IsClass, 'true') then begin
    Result := ftClassFunction;
  end
  else if SameText(Kind, 'procedure') and SameText(IsClass, 'true') then begin
    Result := ftClassProcedure;
  end
  else if SameText(Kind, 'function') then begin
    Result := ftFunction;
  end
  else if SameText(Kind, 'procedure') then begin
    Result := ftProcedure;
  end
  else if SameText(Kind, 'constructor') then begin
    Result := ftConstructor;
  end
  else if SameText(Kind, 'destructor') then begin
    Result := ftDestructor;
  end
  else begin
    raise Exception.Create('Cannot convert method type');
  end;
end;

procedure TFunctionTreeParser.ParseFromDelphiAST(SyntaxNode: TSyntaxNode);
begin
  FRootSyntaxNode := SyntaxNode;
  PopulateClassAndMethodList;
  PopulateMethodImplementation;
  FIsLoaded := True;
end;

procedure TFunctionTreeParser.ParseFromProjectIndex(ProjectIndex: TProjectIndexer);
var
  Index: Integer;
begin
  for Index := 0 to ProjectIndex.ParsedUnits.Count - 1 do begin
    if TRegEx.IsMatch(ProjectIndex.ParsedUnits[Index].Path, '\.pas$') then begin
      ParseFromDelphiAST(ProjectIndex.ParsedUnits[Index].SyntaxTree);
    end;
  end;
end;

procedure TFunctionTreeParser.PopulateClassAndMethodList;
var
  InterfaceNode: TSyntaxNode;
  ChildNode: TSyntaxNode;
  TypeChildNode: TSyntaxNode;
  TopClassNode: TClassTreeNode;
begin
  InterfaceNode := FRootSyntaxNode.FindNode(ntInterface);
  Assert(Assigned(InterfaceNode), 'Interface node is not found, something must be wrong');

  for ChildNode in InterfaceNode.ChildNodes do begin
    if ChildNode.Typ = ntTypeSection then begin
      for TypeChildNode in ChildNode.ChildNodes do begin
        if TypeChildNode.Typ = ntTypeDecl then begin
          TopClassNode := ProcessTypeDeclaration(TypeChildNode, nil);

          if Assigned(TopClassNode) then begin
            FInFileClassList.Add(TopClassNode)
          end;
        end;
      end;
    end;
  end;
end;

function TFunctionTreeParser.ProcessTypeDeclaration(
  TypeDeclarationNode: TSyntaxNode;
  OwnerClassNode: TClassTreeNode
): TClassTreeNode;
var
  TypeNode: TSyntaxNode;
  ClassType: TClassNodeTypeEnum;
  Iteration: TSyntaxNode;
  ChildTypeDeclarationNodes: TArray<TSyntaxNode>;
  ChildTypeDeclarationNode: TSyntaxNode;
  NestedClassNode: TClassTreeNode;
begin
  Result := nil;

  if SameText(TypeDeclarationNode.GetAttribute(anForwarded), 'true') then begin
    Exit;
  end;

  TypeNode := TypeDeclarationNode.FindNode(ntType);
  if not Assigned(TypeNode) then begin
    // If TYPE is not a child node, likely to be a callback function
    Exit;
  end;

  if SameText(TypeNode.GetAttribute(anType), 'class') then begin
    ClassType := ctClass;
  end
  else if SameText(TypeNode.GetAttribute(anType), 'record') then begin
    ClassType := ctRecord;
  end
  else begin
    Exit;
  end;

  Result := CreateClassTreeNode(
    TypeDeclarationNode.GetAttribute(anName),
    ClassType,
    TypeDeclarationNode.Line,
    OwnerClassNode
  );

  ProcessClassMethodListByVisibility(Result, TypeNode);

  for Iteration in TypeNode.ChildNodes do begin
    if Iteration.Typ in [ntStrictPrivate, ntPrivate, ntStrictProtected, ntProtected, ntPublic, ntPublished] then begin
      ProcessClassMethodListByVisibility(Result, Iteration);
    end;
  end;

  ChildTypeDeclarationNodes := FindAllNodesOfType(TypeDeclarationNode, ntTypeDecl, fmNoSelfRecurse);
  for ChildTypeDeclarationNode in ChildTypeDeclarationNodes do begin
    NestedClassNode := ProcessTypeDeclaration(ChildTypeDeclarationNode, Result);
    if Assigned(NestedClassNode) then begin
      Result.NestedClassNodes.Add(NestedClassNode);
    end;
  end;
end;

procedure TFunctionTreeParser.ProcessClassMethodListByVisibility(
  ClassTreeNode: TClassTreeNode;
  SyntaxNode: TSyntaxNode);
var
  Iteration: TSyntaxNode;
  Visibility: TVisibilityEnum;
  FunctionTreeNode: TMethodTreeNode;
begin
  if not (SyntaxNode.Typ in [ntStrictPrivate, ntPrivate, ntStrictProtected, ntProtected, ntPublic, ntPublished]) then begin
    Visibility := vPrivate;
  end
  else begin
    Visibility := GetFunctionTreeVisibility(SyntaxNode.Typ);
  end;

  for Iteration in SyntaxNode.ChildNodes do begin
    if Iteration.Typ <> ntMethod then begin
      Continue;
    end;

    FunctionTreeNode := CreateFunctionTreeNode(
      Iteration.GetAttribute(anName),
      GetMethodType(Iteration),
      Visibility,
      Iteration.Line);

    // @TODO: maybe add parameter here later if we have more time
    ClassTreeNode.AddFunctionTreeNode(FunctionTreeNode);
  end;
end;

procedure TFunctionTreeParser.PopulateMethodImplementation;
var
  ImplementationNode: TSyntaxNode;
  MethodIteration: TSyntaxNode;
  MethodNameList: TStringList;
  MethodName: String;
  ClassHierarchy: TList<String>;
  SelectedClassNode: TClassTreeNode;
  SelectedMethodNode: TMethodTreeNode;
begin
  ImplementationNode := FRootSyntaxNode.FindNode(ntImplementation);
  if not Assigned(ImplementationNode) then begin
    raise Exception.Create('Type section is empty, something must be wrong');
  end;

  MethodNameList := TStringList.Create;
  MethodNameList.Delimiter := '.';

  for MethodIteration in ImplementationNode.ChildNodes do begin
    if MethodIteration.Typ <> ntMethod then begin
      Continue;
    end;

    MethodNameList.DelimitedText := MethodIteration.GetAttribute(anName);

    // Top Level function
    if MethodNameList.Count = 1 then begin
      FUncateredMethods.Add(MethodIteration);
    end

    // Class member function
    else begin
      MethodName := MethodNameList[MethodNameList.Count - 1];
      ClassHierarchy := TList<String>.Create;
      ClassHierarchy.AddRange(MethodNameList.ToStringArray);
      ClassHierarchy.Delete(ClassHierarchy.Count - 1);


      // Get small tree class node
      SelectedClassNode := GetClassNode(ClassHierarchy);

      if not Assigned(SelectedClassNode) then begin
        raise Exception.Create('Class name is not found: ' + MethodNameList.DelimitedText);
      end;


      // Get small tree method node
      SelectedMethodNode := SelectedClassNode.GetMethodNode(
        MethodName,
        GetMethodType(MethodIteration)
      );

      // Checks that current implementation exists in the interface
      if not Assigned(SelectedMethodNode) then begin
        raise Exception.Create('Method of class ' + SelectedClassNode.ClassNodeName +
          ' is not found: ' + MethodName);
      end;

      ProcessMethod(SelectedClassNode, SelectedMethodNode, MethodIteration);

      FreeAndNil(ClassHierarchy);
    end
  end;

  FreeAndNil(MethodNameList);
end;

function TFunctionTreeParser.GetClassNode(ClassHierarchy: TList<String>): TClassTreeNode;

  function GetClassNodeRecursively(
    CurrentClassNode: TClassTreeNode;
    CurrentClassHierarchy: TList<String>
  ): TClassTreeNode;
  var
    NestedClassNode: TClassTreeNode;
    ClassToSearch: String;
    PrunedClassHierarchy: TList<String>;
  begin
    Assert(CurrentClassHierarchy.Count > 0, 'Class hierarchy cannot be empty');

    Result := nil;

    ClassToSearch := CurrentClassHierarchy[0];
    if SameStr(CurrentClassNode.ClassNodeName, ClassToSearch) then begin
      Result := CurrentClassNode;
      Exit;
    end;

    PrunedClassHierarchy := TList<String>.Create;
    PrunedClassHierarchy.AddRange(CurrentClassHierarchy);
    PrunedClassHierarchy.Delete(0);
    for NestedClassNode in CurrentClassNode.NestedClassNodes do begin
      if SameStr(NestedClassNode.ClassNodeName, ClassToSearch) then begin
        if PrunedClassHierarchy.Count = 0 then begin
          Result := NestedClassNode;
          Break;
        end
        else begin
          GetClassNodeRecursively(NestedClassNode, PrunedClassHierarchy);
        end;
      end;
    end;

    FreeAndNil(PrunedClassHierarchy);
  end;

var
  TopClassNode: TClassTreeNode;
begin
  Result := nil;
  for TopClassNode in FInFileClassList do begin
    Result := GetClassNodeRecursively(TopClassNode, ClassHierarchy);
    if Assigned(Result) then begin
      Break;
    end;
  end;
end;

procedure TFunctionTreeParser.ProcessMethod(
  ClassNode: TClassTreeNode;

  // small tree method node
  MethodNode: TMethodTreeNode;

  // Big tree method node
  SyntaxNode: TSyntaxNode);
var
  StatementsSyntaxNode: TSyntaxNode;
begin
  MethodNode.ImplementationLine := SyntaxNode.Line;

  // Actual content of the method:
  StatementsSyntaxNode := SyntaxNode.FindNode(ntStatements);

  if not Assigned(StatementsSyntaxNode) then begin
    raise Exception.Create('Statements node not found');
  end;

  RecurseAddCallMethod(ClassNode, MethodNode, StatementsSyntaxNode);
end;

procedure TFunctionTreeParser.RecurseAddCallMethod(
  ClassNode: TClassTreeNode;
  SelectedMethodNode: TMethodTreeNode;
  // Method content (big tree statements node)
  SyntaxNode: TSyntaxNode);

  procedure AddFoundMethodToSelectedMethod(
    Iteration: TSyntaxNode
  );
  var
    IdentifierSyntaxNode: TSyntaxNode;
    CalledMethodName: String;
    FoundMethodNode: TMethodTreeNode;
    ResultMethodVal: TMethodTreeNode;
    ClassNodeItem: TClassTreeNode;
  begin
      IdentifierSyntaxNode := Iteration.FindNode(ntIdentifier);

      FoundMethodNode := nil;

      // We did not go into the dot

      if Assigned(IdentifierSyntaxNode) then begin

        // MyFunc
        if Length(Iteration.ChildNodes) = 1 then begin
          CalledMethodName := Iteration.ChildNodes[0].GetAttribute(anName);
          FoundMethodNode := ClassNode.GetMethodNode(CalledMethodName);
        end

        // MyClass.MyFunc
        else if Length(Iteration.ChildNodes) = 2 then begin


          if (SameText(Iteration.ChildNodes[0].GetAttribute(anName), 'self')
           or SameText(Iteration.ChildNodes[0].GetAttribute(anName), ClassNode.ClassNodeName)) then
          begin
            CalledMethodName := Iteration.ChildNodes[1].GetAttribute(anName);
            FoundMethodNode := ClassNode.GetMethodNode(CalledMethodName); // Search only in current class
          end
          else begin
            CalledMethodName :=  Iteration.ChildNodes[1].GetAttribute(anName);

            // Search all classes, except current class
            for ClassNodeItem in FClassNodes do begin
              if ClassNodeItem.ClassNodeName = ClassNode.ClassNodeName then Continue;

              ResultMethodVal := ClassNodeItem.GetMethodNode(CalledMethodName);

              if Assigned(ResultMethodVal) then begin
                FoundMethodNode := ResultMethodVal;
                Break;
              end;
            end;
          end;

        end

        // Error
        else begin
          raise Exception.Create('Called method name is invalid:');
        end;

        // TODO: instead of checking THIS class only, we need to check ALL classes
        // FoundMethodNode := ClassNode.GetMethodNode(CalledMethodName);

        if Assigned(FoundMethodNode) then begin
          // SelectedMethodNode has a call to FoundMethodNode in it's implementation.
          SelectedMethodNode.AddMethodCall(FoundMethodNode);
        end;
      end;
  end;

var
  Iteration: TSyntaxNode;
begin
  // For ALL children of STATEMENTS node
  for Iteration in SyntaxNode.ChildNodes do begin

    // Only if the node is a CALL node:

    if Iteration.Typ = ntCall then begin
      AddFoundMethodToSelectedMethod(Iteration);
    end

    // This is never reached beacuse parent no child of statment is dot
    // Call must come first, then have dot inside.
    else if Iteration.Typ = ntDot then begin
       AddFoundMethodToSelectedMethod(Iteration);
    end;

    RecurseAddCallMethod(ClassNode, SelectedMethodNode, Iteration);
  end;
end;

procedure TFunctionTreeParser.ClearTree;
var
  IterationUncatered: TSyntaxNode;
begin
  FIsLoaded := False;
  for IterationUncatered in FUncateredMethods do begin
    IterationUncatered.Free;
  end;

  FUncateredMethods.Clear;
  FInFileClassList.Clear;
end;

function TFunctionTreeParser.GetUnusedPrivateMethods: TList<TMethodTreeNode>;
var
  SelectedClassTreeNode: TClassTreeNode;
  SelectedMethodTreeNode: TMethodTreeNode;
begin
  Result := TList<TMethodTreeNode>.Create;
  for SelectedClassTreeNode in FInFileClassList do begin
    for SelectedMethodTreeNode in SelectedClassTreeNode.GetMethodNodeByVisibility([vStrictPrivate, vPrivate]) do
    begin
      if SelectedMethodTreeNode.CallerList.Count = 0 then begin
        Result.Add(SelectedMethodTreeNode);
      end;
    end;
  end
end;

end.
