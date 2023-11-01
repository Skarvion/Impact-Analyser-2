unit SymbolTreeDataObjects;

interface

uses
    System.Generics.Collections
  , DelphiAST.Classes
  ;

type
  // @TODO: This part is SUPER dodgy, very misleading
  TClassNodeTypeEnum = (
    ctClass,
    ctRecord,
    ctScope);

  TMethodTypeEnum = (
    ftNone,
    ftClassFunction,
    ftFunction,
    ftClassProcedure,
    ftProcedure,
    ftConstructor,
    ftDestructor);

  TVisibilityEnum = (
    vStrictPrivate,
    vPrivate,
    vStrictProtected,
    vProtected,
    vPublic,
    vPublished);

  TVisibilityEnumSet = set of TVisibilityEnum;

  TMethodTreeNode = class;
  TClassTreeNode = class;

  TUnitTreeNode = class(TObject)
  strict private
    FRootSyntaxNode: TSyntaxNode;
    FTopLevelClassNodes: TObjectList<TClassTreeNode>;
    FUnitMethodNodes: TObjectList<TMethodTreeNode>;

    function GetUnitNodeName: String;

  public
    constructor Create(RootSyntaxNode: TSyntaxNode);
    destructor Destroy; override;

    property RootSyntaxNode: TSyntaxNode read FRootSyntaxNode;
    property UnitNodeName: String read GetUnitNodeName;
    property TopLevelClassNodes: TObjectList<TClassTreeNode> read FTopLevelClassNodes;
    property UnitMethodNodes: TObjectList<TMethodTreeNode> read FUnitMethodNodes;
  end;

  TClassTreeNode = class(TObject)
  public const
    C_ClassNodeTypeString: array [TClassNodeTypeEnum] of String = (
      'CLASS',
      'RECORD',
      'SCOPE');

  strict private
    FOwnerUnit: TUnitTreeNode;
    FID: Integer;
    FClassNodeName: String;
    FClassNodeType: TClassNodeTypeEnum;
    FDeclarationLine: Integer;
    FOwnerClassNode: TClassTreeNode;

    FMethodList: TList<TMethodTreeNode>;
    FNestedClassNodes: TObjectList<TClassTreeNode>;
    FSelected: Boolean;

  public
    constructor Create(
      OwnerUnit: TUnitTreeNode;
      ID: Integer;
      ClassName: String;
      ClassType: TClassNodeTypeEnum;
      DeclarationLine: Integer;
      OwnerClassNode: TClassTreeNode
    );

    destructor Destroy; override;

    procedure AddFunctionTreeNode(Node: TMethodTreeNode);

    function GetMethodNode(
      MethodName: String;
      MethodType: TMethodTypeEnum = ftNone): TMethodTreeNode;

    function GetMethodNodeByVisibility(Visibility: TVisibilityEnumSet): TList<TMethodTreeNode>;

    property OwnerUnit: TUnitTreeNode read FOwnerUnit;
    property ID: Integer read FID;
    property ClassNodeName: String read FClassNodeName;
    property ClassNodeType: TClassNodeTypeEnum read FClassNodeType;
    property DeclarationLine: Integer read FDeclarationLine;
    property OwnerClassNode: TClassTreeNode read FOwnerClassNode;

    property MethodList: TList<TMethodTreeNode> read FMethodList;
    property NestedClassNodes: TObjectList<TClassTreeNode> read FNestedClassNodes;

    property Selected: Boolean read FSelected write FSelected;
  end;

  TMethodTreeNode = class(TObject)
  public const
    C_FunctionTypeString: array [TMethodTypeEnum] of String = (
      'NONE',
      'CLASS FUNCTION',
      'FUNCTION',
      'CLASS PROCEDURE',
      'PROCEDURE',
      'CONSTRUCTOR',
      'DESTRUCTOR');

    C_VisibilityTypeString: array [TVisibilityEnum] of String = (
      'STRICT PRIVATE',
      'PRIVATE',
      'STRICT PROTECTED',
      'PROTECTED',
      'PUBLIC',
      'PUBLISHED');

  strict private
    FOwnerClassNode: TClassTreeNode;
    FID: Integer;
    FFunctionName: String;
    FFunctionType: TMethodTypeEnum;
    FVisibility: TVisibilityEnum;

    FImplementationNode: TSyntaxNode;

    FDeclarationLine: Integer;
    FReturn: String;

    FMethodsCalledWithinThisMethod: TList<TMethodTreeNode>;
    FCallerList: TList<TMethodTreeNode>;

    FHasRecursion: Boolean;

    FSelected: Boolean;

    function HasCallerRecursion(MethodNode: TMethodTreeNode): Boolean;

    function GetVisibilityAsString: String;
    function GetImplementationLine: Integer;

  public
    constructor Create(
      OwnerClassNode: TClassTreeNode;
      FunctionName: String;
      FunctionType: TMethodTypeEnum;
      Visibility: TVisibilityEnum;
      DeclarationLine: Integer;
      Return: String
    ); overload;
    destructor Destroy; override;

    procedure AddMethodCall(CallingMethodNode: TMethodTreeNode);

    property OwnerClassNode: TClassTreeNode read FOwnerClassNode;
    property ID: Integer read FID write FID;
    property FunctionName: String read FFunctionName write FFunctionName;
    property FunctionType: TMethodTypeEnum read FFunctionType write FFunctionType;
    property Visibility: TVisibilityEnum read FVisibility write FVisibility;
    property VisibilityAsString: String read GetVisibilityAsString;
    property DeclarationLine: Integer read FDeclarationLine write FDeclarationLine;
    property ImplementationNode: TSyntaxNode read FImplementationNode write FImplementationNode;
    property ImplementationLine: Integer read GetImplementationLine;
    property MethodsCalledWithinThisMethod: TList<TMethodTreeNode> read FMethodsCalledWithinThisMethod;
    property CallerList: TList<TMethodTreeNode> read FCallerList;
    property HasRecursion: Boolean read FHasRecursion;
    property Selected: Boolean read FSelected write FSelected;
    property Return: String read FReturn write FReturn;
  end;

implementation

uses
    DelphiAST.Consts
  , System.SysUtils
  ;

{ TUnitTreeNode }

constructor TUnitTreeNode.Create(RootSyntaxNode: TSyntaxNode);
begin
  FRootSyntaxNode := RootSyntaxNode;
  FTopLevelClassNodes := TObjectList<TClassTreeNode>.Create(True);
  FUnitMethodNodes := TObjectList<TMethodTreeNode>.Create(True);
end;

destructor TUnitTreeNode.Destroy;
begin
  FreeAndNil(FUnitMethodNodes);
  FreeAndNil(FTopLevelClassNodes);
  inherited;
end;

function TUnitTreeNode.GetUnitNodeName: String;
begin
  Assert(FRootSyntaxNode.Typ = ntUnit, 'Root syntax node is not unit, it is ' + SyntaxNodeNames[FRootSyntaxNode.Typ]);
  Result := FRootSyntaxNode.GetAttribute(anName);
end;

{ TClassTreeNode }

constructor TClassTreeNode.Create(
  OwnerUnit: TUnitTreeNode;
  ID: Integer;
  ClassName: String;
  ClassType: TClassNodeTypeEnum;
  DeclarationLine: Integer;
  OwnerClassNode: TClassTreeNode
);
begin
  FOwnerUnit := OwnerUnit;
  FID := ID;
  FClassNodeName := ClassName;
  FClassNodeType := ClassType;
  FDeclarationLine := DeclarationLine;
  FOwnerClassNode := OwnerClassNode;

  FMethodList := TList<TMethodTreeNode>.Create;
  FNestedClassNodes := TObjectList<TClassTreeNode>.Create(True);
end;

destructor TClassTreeNode.Destroy;
var
  Iteration: TMethodTreeNode;
begin
  FreeAndNil(FNestedClassNodes);
  for Iteration in FMethodList do begin
    Iteration.Free;
  end;
  FreeAndNil(FMethodList);
  inherited;
end;

procedure TClassTreeNode.AddFunctionTreeNode(Node: TMethodTreeNode);
begin
  FMethodList.Add(Node);
end;

function TClassTreeNode.GetMethodNode(
  MethodName: String;
  MethodType: TMethodTypeEnum = ftNone): TMethodTreeNode;
var
  Iteration: TMethodTreeNode;
begin
  // @TODO: haven't catered for overload yet
  // and using ftNone a bit dodgy, will have to look at this again later
  for Iteration in FMethodList do begin
    if SameText(Iteration.FunctionName, MethodName) and
      ((MethodType = ftNone) or (Iteration.FunctionType = MethodType)) then
    begin
      Result := Iteration;
      Exit;
    end;
  end;

  Result := nil;
end;

function TClassTreeNode.GetMethodNodeByVisibility(Visibility: TVisibilityEnumSet):
  TList<TMethodTreeNode>;
var
  Iteration: TMethodTreeNode;
begin
  Result := TList<TMethodTreeNode>.Create;

  for Iteration in FMethodList do begin
    if Iteration.Visibility in Visibility then begin
      Result.Add(Iteration);
    end;
  end;
end;

{ TMethodTreeNode }

constructor TMethodTreeNode.Create(
  OwnerClassNode: TClassTreeNode;
  FunctionName: String;
  FunctionType: TMethodTypeEnum;
  Visibility: TVisibilityEnum;
  DeclarationLine: Integer;
  Return: String
);
begin
  FOwnerClassNode := OwnerClassNode;
  FFunctionName := FunctionName;
  FFunctionType := FunctionType;
  FVisibility := Visibility;
  FMethodsCalledWithinThisMethod := TList<TMethodTreeNode>.Create;
  FCallerList := TList<TMethodTreeNode>.Create;
  FHasRecursion := False;
  FReturn := Return;

  FImplementationNode := nil;
end;

destructor TMethodTreeNode.Destroy;
begin
  FreeAndNil(FCallerList);
  FreeAndNil(FMethodsCalledWithinThisMethod);
  inherited;
end;

procedure TMethodTreeNode.AddMethodCall(CallingMethodNode: TMethodTreeNode);
begin
  if HasCallerRecursion(CallingMethodNode) then begin
    CallingMethodNode.FHasRecursion := True;
  end
  else begin
    CallingMethodNode.FCallerList.Add(Self);
    FMethodsCalledWithinThisMethod.Add(CallingMethodNode);
  end;
end;

function TMethodTreeNode.HasCallerRecursion(MethodNode: TMethodTreeNode): Boolean;
var
  Iteration: TMethodTreeNode;
begin
  Result := False;
  if Self = MethodNode then begin
    Result := True;
    Exit;
  end;
  for Iteration in FCallerList do begin
    Result := Iteration.HasCallerRecursion(MethodNode);
    if Result then begin
      Exit;
    end;
  end;
end;

function TMethodTreeNode.GetVisibilityAsString: String;
begin
  case FVisibility of
    vStrictPrivate: Result := 'strict private';
    vPrivate: Result := 'private';
    vStrictProtected: Result := 'strict protected';
    vProtected: Result := 'protected';
    vPublic: Result := 'public';
    vPublished: Result := 'published';
  end;
end;

function TMethodTreeNode.GetImplementationLine: Integer;
begin
  Result := FImplementationNode.Line;
end;

end.
