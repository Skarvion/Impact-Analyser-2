unit TreeParsers;

interface

uses
    System.Generics.Collections
  , SymbolTreeDataObjects
  , DelphiAST.Classes
  , DelphiAST.Consts
  , DelphiAST.ProjectIndexer
  ;

type

  TTreeParser = class(TObject)
  private
    FUnitNodes: TObjectDictionary<String, TUnitTreeNode>;
    // Keep list of multiple class tree nodes as it's possible to have the same class name in different unit
    FClassNodesDictionary: TObjectDictionary<STring, TObjectList<TClassTreeNode>>;

    FIDKeyCount: Integer;
    FIsLoaded: Boolean;

    FUncateredMethods: TList<TSyntaxNode>;

    // @TODO Later add a TObjectDictionary<TClassTreeNode, TUnitTreeNode> for optimisation
    //      or TObjectDictionary<String, TClassTreeNode>

    function CreateClassTreeNode(
      UnitTreeNode: TUnitTreeNode;
      ClassNodeName: String;
      ClassType: TClassNodeTypeEnum;
      DeclarationLine: Integer;
      OwnerClassNode: TClassTreeNode
    ): TClassTreeNode;
    function CreateFunctionTreeNode(
      ClassNode: TClassTreeNode;
      FunctionName: String;
      FunctionType: TMethodTypeEnum;
      Visibility: TVisibilityEnum;
      DeclarationLine: Integer;
      Return: String): TMethodTreeNode;

    procedure PopulateClassAndMethodList(UnitTreeNode: TUnitTreeNode);
    function ProcessTypeDeclaration(
      UnitTreeNode: TUnitTreeNode;
      TypeDeclarationNode: TSyntaxNode;
      OwnerClassNode: TClassTreeNode
    ): TClassTreeNode;
    procedure ProcessClassMethodListByVisibility(
      ClassTreeNode: TClassTreeNode;
      SyntaxNode: TSyntaxNode);

    procedure PopulateMethodImplementation(UnitTreeNode: TUnitTreeNode);
    function GetClassNode(
      CurrentUnitTreeNode: TUnitTreeNode;
      ClassHierarchy: TList<String>): TClassTreeNode;
    procedure ProcessMethod(
      ClassNode: TClassTreeNode;
      MethodNode: TMethodTreeNode
    );
    procedure RecurseAddCallMethod(
      ThisClassNode: TClassTreeNode;
      SelectedMethodNode: TMethodTreeNode;
      SyntaxNode: TSyntaxNode);

    // More Delphi AST specific implementation
    class function GetFunctionTreeVisibility(SyntaxNodeType: TSyntaxNodeType): TVisibilityEnum;
    class function GetMethodType(SyntaxNode: TSyntaxNode): TMethodTypeEnum;

    public
      constructor Create;
      destructor Destroy; override;

      procedure ParseFromProjectIndex(ProjectIndex: TProjectIndexer);
      procedure ParseFromDelphiAST(SyntaxNode: TSyntaxNode);
      procedure ClearTree;

      function GetUnusedPrivateMethods: TList<TMethodTreeNode>;

      property IsLoaded: Boolean read FIsLoaded;

      property UnitNodes: TObjectDictionary<String, TUnitTreeNode> read FUnitNodes;
      property ClassNodesDictionary: TObjectDictionary<STring, TObjectList<TClassTreeNode>> read FClassNodesDictionary;
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

constructor TTreeParser.Create;
begin
  FIDKeyCount := 0;
  FIsLoaded := False;

  FUncateredMethods := TList<TSyntaxNode>.Create;

  FUnitNodes := TObjectDictionary<String, TUnitTreeNode>.Create([doOwnsValues]);
  FClassNodesDictionary := TObjectDictionary<String, TObjectList<TClassTreeNode>>.Create([doOwnsValues]);
end;

destructor TTreeParser.Destroy;
begin
  ClearTree;
  FreeAndNil(FClassNodesDictionary);
  FreeAndNil(FUnitNodes);
  FreeAndNil(FUncateredMethods);
  inherited;
end;

function TTreeParser.CreateClassTreeNode(
  UnitTreeNode: TUnitTreeNode;
  ClassNodeName: String;
  ClassType: TClassNodeTypeEnum;
  DeclarationLine: Integer;
  OwnerClassNode: TClassTreeNode
): TClassTreeNode;
begin
  Result := TClassTreeNode.Create(
    UnitTreeNode,
    FIDKeyCount,
    ClassNodeName,
    ClassType,
    DeclarationLine,
    OwnerClassNode
  );

  Inc(FIDKeyCount);

  if not FClassNodesDictionary.ContainsKey(ClassNodeName) then begin
    FClassNodesDictionary.Add(ClassNodeName, TObjectList<TClassTreeNode>.Create(False));
  end;

  FClassNodesDictionary[ClassNodeName].Add(Result);
end;

function TTreeParser.CreateFunctionTreeNode(
  ClassNode: TClassTreeNode;
  FunctionName: String;
  FunctionType: TMethodTypeEnum;
  Visibility: TVisibilityEnum;
  DeclarationLine: Integer;
  Return: String): TMethodTreeNode;
begin
  Result := TMethodTreeNode.Create(
    ClassNode,
    FunctionName,
    FunctionType,
    Visibility,
    DeclarationLine,
    Return
  );
  Result.ID := FIDKeyCount;
  Inc(FIDKeyCount);
end;

class function TTreeParser.GetFunctionTreeVisibility(
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
      'Cannot convert syntax node type to visibility. Shouldnt be able to trigger this' +
      'Node type: ' + SyntaxNodeNames[SyntaxNodeType]);
  end;
end;

class function TTreeParser.GetMethodType(SyntaxNode: TSyntaxNode): TMethodTypeEnum;
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
    // @TODO Hack, dunno how to handle operator, need to update DelphiAST
    Result := ftClassFunction;
//    raise Exception.Create('Cannot convert method type. Kind attribute: ' + Kind);
  end;
end;

procedure TTreeParser.ParseFromDelphiAST(SyntaxNode: TSyntaxNode);
var
  UnitTreeNode: TUnitTreeNode;
begin
  UnitTreeNode := TUnitTreeNode.Create(SyntaxNode);
  FUnitNodes.Add(UnitTreeNode.UnitNodeName, UnitTreeNode);

  PopulateClassAndMethodList(UnitTreeNode);
  PopulateMethodImplementation(UnitTreeNode);
  FIsLoaded := True;
end;

procedure TTreeParser.ParseFromProjectIndex(ProjectIndex: TProjectIndexer);
var
  Index: Integer;
begin
  ClearTree;
  for Index := 0 to ProjectIndex.ParsedUnits.Count - 1 do begin
    if TRegEx.IsMatch(ProjectIndex.ParsedUnits[Index].Path, '\.pas$') then begin
      ParseFromDelphiAST(ProjectIndex.ParsedUnits[Index].SyntaxTree);
    end;
  end;
end;

procedure TTreeParser.PopulateClassAndMethodList(UnitTreeNode: TUnitTreeNode);
var
  InterfaceNode: TSyntaxNode;
  ChildNode: TSyntaxNode;
  TypeChildNode: TSyntaxNode;
  TopClassNode: TClassTreeNode;
begin
  InterfaceNode := UnitTreeNode.RootSyntaxNode.FindNode(ntInterface);
  Assert(Assigned(InterfaceNode), 'Interface node is not found, something must be wrong');

  for ChildNode in InterfaceNode.ChildNodes do begin
    if ChildNode.Typ = ntTypeSection then begin
      for TypeChildNode in ChildNode.ChildNodes do begin
        if TypeChildNode.Typ = ntTypeDecl then begin
          TopClassNode := ProcessTypeDeclaration(UnitTreeNode, TypeChildNode, nil);

          if Assigned(TopClassNode) then begin
            UnitTreeNode.TopLevelClassNodes.Add(TopClassNode)
          end;
        end;
      end;
    end;
  end;
end;

function TTreeParser.ProcessTypeDeclaration(
  UnitTreeNode: TUnitTreeNode;
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
    UnitTreeNode,
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
    NestedClassNode := ProcessTypeDeclaration(UnitTreeNode, ChildTypeDeclarationNode, Result);
    if Assigned(NestedClassNode) then begin
      Result.NestedClassNodes.Add(NestedClassNode);
    end;
  end;
end;

procedure TTreeParser.ProcessClassMethodListByVisibility(
  ClassTreeNode: TClassTreeNode;
  SyntaxNode: TSyntaxNode);
var
  Iteration: TSyntaxNode;
  Visibility: TVisibilityEnum;
  FunctionTreeNode: TMethodTreeNode;
  ReturnTypeNode: TSyntaxNode;
  ReturnType: String;
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

    ReturnType := '';
    ReturnTypeNode :=  Iteration.FindNode(ntReturnType);

    if Assigned(ReturnTypeNode) then begin
      ReturnType :=  ReturnTypeNode.ChildNodes[0].GetAttribute(anName);
    end;
    FunctionTreeNode := CreateFunctionTreeNode(
      ClassTreeNode,
      Iteration.GetAttribute(anName),
      GetMethodType(Iteration),
      Visibility,
      Iteration.Line,
      ReturnType
    );

    // @TODO: maybe add parameter here later if we have more time
    ClassTreeNode.AddFunctionTreeNode(FunctionTreeNode);
  end;
end;

procedure TTreeParser.PopulateMethodImplementation(UnitTreeNode: TUnitTreeNode);
var
  ImplementationNode: TSyntaxNode;
  MethodIteration: TSyntaxNode;
  MethodNameList: TStringList;
  MethodName: String;
  ClassHierarchy: TList<String>;
  SelectedClassNode: TClassTreeNode;
  SelectedMethodNode: TMethodTreeNode;
begin
  ImplementationNode := UnitTreeNode.RootSyntaxNode.FindNode(ntImplementation);
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
      SelectedClassNode := GetClassNode(UnitTreeNode, ClassHierarchy);

      if not Assigned(SelectedClassNode) then begin
//        raise Exception.Create('Class name is not found: ' + MethodNameList.DelimitedText);
        Exit;
      end;


      // Get small tree method node
      SelectedMethodNode := SelectedClassNode.GetMethodNode(
        MethodName,
        GetMethodType(MethodIteration)
      );

      // Checks that current implementation exists in the interface
      if not Assigned(SelectedMethodNode) then begin
//        raise Exception.Create('Method of class ' + SelectedClassNode.ClassNodeName +
//          ' is not found: ' + MethodName);
        Exit;
      end;

      SelectedMethodNode.ImplementationNode := MethodIteration;

      ProcessMethod(SelectedClassNode, SelectedMethodNode);

      FreeAndNil(ClassHierarchy);
    end
  end;

  FreeAndNil(MethodNameList);
end;

function TTreeParser.GetClassNode(
  CurrentUnitTreeNode: TUnitTreeNode;
  ClassHierarchy: TList<String>
): TClassTreeNode;

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
    if not SameStr(CurrentClassNode.ClassNodeName, ClassToSearch) then begin
      Exit;
    end
    else if CurrentClassHierarchy.Count = 1 then begin
      Result := CurrentClassNode;
      Exit;
    end;

    PrunedClassHierarchy := TList<String>.Create;
    PrunedClassHierarchy.AddRange(CurrentClassHierarchy);
    PrunedClassHierarchy.Delete(0);
    for NestedClassNode in CurrentClassNode.NestedClassNodes do begin
      if SameStr(NestedClassNode.ClassNodeName, PrunedClassHierarchy[0]) then begin
        Result := GetClassNodeRecursively(NestedClassNode, PrunedClassHierarchy);
      end;
    end;

    FreeAndNil(PrunedClassHierarchy);
  end;

var
  SelectedUnitTreeNode: TUnitTreeNode;
  TopClassNode: TClassTreeNode;
  OtherUnitTreeNode: TUnitTreeNode;
begin
  Result := nil;
  SelectedUnitTreeNode := CurrentUnitTreeNode;
  if FUnitNodes.ContainsKey(ClassHierarchy[0]) then begin
    SelectedUnitTreeNode := FUnitNodes[ClassHierarchy[0]];
  end;

  for TopClassNode in SelectedUnitTreeNode.TopLevelClassNodes do begin
    Result := GetClassNodeRecursively(TopClassNode, ClassHierarchy);
    if Assigned(Result) then begin
      Break;
    end;
  end;

  if not Assigned(Result) then begin
    for OtherUnitTreeNode in FUnitNodes.Values do begin
      if OtherUnitTreeNode = SelectedUnitTreeNode then begin
        Continue;
      end;

      for TopClassNode in OtherUnitTreeNode.TopLevelClassNodes do begin
        Result := GetClassNodeRecursively(TopClassNode, ClassHierarchy);
        if Assigned(Result) then begin
          Exit;
        end;
      end;
    end;
  end;
end;

procedure TTreeParser.ProcessMethod(
  ClassNode: TClassTreeNode;
  MethodNode: TMethodTreeNode
);
begin
  RecurseAddCallMethod(ClassNode, MethodNode, MethodNode.ImplementationNode);
end;

procedure TTreeParser.RecurseAddCallMethod(
  ThisClassNode: TClassTreeNode;
  SelectedMethodNode: TMethodTreeNode;
  // Method content (big tree statements node)
  SyntaxNode: TSyntaxNode);

  procedure AddFoundMethodToSelectedMethod(Iteration: TSyntaxNode);
  var
    IdentifierSyntaxNode: TSyntaxNode;
    CalledMethodName: String;
    FoundMethodNode: TMethodTreeNode;
    ResultMethodVal: TMethodTreeNode;
    ClassNameAndNodes: TPair<String, TObjectList<TClassTreeNode>>;
    ClassNode: TClassTreeNode;
  begin
    IdentifierSyntaxNode := Iteration.FindNode(ntIdentifier);

    FoundMethodNode := nil;

    // We did not go into the dot

    if Assigned(IdentifierSyntaxNode) then begin

      // MyFunc
      if Length(Iteration.ChildNodes) = 1 then begin
        CalledMethodName := Iteration.ChildNodes[0].GetAttribute(anName);
        FoundMethodNode := ThisClassNode.GetMethodNode(CalledMethodName);
      end

      // MyClass.MyFunc
      else if Length(Iteration.ChildNodes) = 2 then begin

        CalledMethodName := Iteration.ChildNodes[1].GetAttribute(anName);

        if (SameText(Iteration.ChildNodes[0].GetAttribute(anName), 'self')
          or SameText(Iteration.ChildNodes[0].GetAttribute(anName), ThisClassNode.ClassNodeName)) then
        begin

          FoundMethodNode := ThisClassNode.GetMethodNode(CalledMethodName); // Search only in class of this function
        end
        else begin
          // Search all classes, except current class
          for ClassNameAndNodes in FClassNodesDictionary do begin
            if ClassNameAndNodes.Key = ThisClassNode.ClassNodeName then begin
              Continue;
            end;

            for ClassNode in ClassNameAndNodes.Value do begin
              ResultMethodVal := ClassNode.GetMethodNode(CalledMethodName);

              if Assigned(ResultMethodVal) then begin
                FoundMethodNode := ResultMethodVal;
                Break;
              end;
            end;

            if Assigned(FoundMethodNode) then begin
              Break;
            end;
          end;
        end;

      end

      // Error
      else begin
        raise Exception.Create('Called method name is invalid:');
      end;

      if Assigned(FoundMethodNode) then begin
        // SelectedMethodNode has a call to FoundMethodNode in it's implementation.
        SelectedMethodNode.AddMethodCall(FoundMethodNode);
      end;
    end;
  end;

var
  Iteration: TSyntaxNode;
begin
  // For ALL children of STATEMENTS node (root case)
  for Iteration in SyntaxNode.ChildNodes do begin

    // Only if the node is a CALL node:
    if Iteration.Typ = ntCall then begin
      AddFoundMethodToSelectedMethod(Iteration);
    end

    else if Iteration.Typ = ntDot then begin
      AddFoundMethodToSelectedMethod(Iteration);
    end;

    RecurseAddCallMethod(ThisClassNode, SelectedMethodNode, Iteration);
  end;
end;

procedure TTreeParser.ClearTree;
var
  IterationUncatered: TSyntaxNode;
begin
  FIsLoaded := False;
  for IterationUncatered in FUncateredMethods do begin
    IterationUncatered.Free;
  end;

  FUncateredMethods.Clear;
  FClassNodesDictionary.Clear;
  FUnitNodes.Clear;
end;

function TTreeParser.GetUnusedPrivateMethods: TList<TMethodTreeNode>;
var
  ClassNodes: TObjectList<TClassTreeNode>;
  ClassNode: TClassTreeNode;
  MethodNode: TMethodTreeNode;
begin
  Result := TList<TMethodTreeNode>.Create;
  for ClassNodes in FClassNodesDictionary.Values do begin
    for ClassNode in ClassNodes do begin
      for MethodNode in ClassNode.GetMethodNodeByVisibility([vStrictPrivate, vPrivate]) do begin
        if MethodNode.CallerList.Count = 0 then begin
          Result.Add(MethodNode);
        end;
      end;
    end;
  end;
end;

end.
