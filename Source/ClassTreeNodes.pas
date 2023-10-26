unit ClassTreeNodes;

interface

uses
    System.Generics.Collections
  , FunctionTreeNodes
  ;

type
  // @TODO: This part is SUPER dodgy, very misleading
  TClassNodeTypeEnum = (
    ctClass,
    ctRecord,
    ctScope);

  TClassTreeNode = class(TObject)
  public const
    C_ClassNodeTypeString: array [TClassNodeTypeEnum] of String = (
      'CLASS',
      'RECORD',
      'SCOPE');

  strict private
    FID: Integer;
    FClassNodeName: String;
    FClassNodeType: TClassNodeTypeEnum;
    FDeclarationLine: Integer;
    FOwnerClassNode: TClassTreeNode;

    FMethodList: TList<TMethodTreeNode>;
    FNestedClassNodes: TObjectList<TClassTreeNode>;

  public
    constructor Create(
      ID: Integer;
      ClassName: String;
      ClassType: TClassNodeTypeEnum;
      DeclarationLine: Integer;
      OwnerClassNode: TClassTreeNode
    ); overload;
    constructor Create(
      ID: Integer;
      ClassName: String;
      ClassType: TClassNodeTypeEnum;
      DeclarationLine: Integer
    ); overload;

    destructor Destroy; override;

    procedure AddFunctionTreeNode(Node: TMethodTreeNode);

    function GetMethodNode(
      MethodName: String;
      MethodType: TFunctionTypeEnum = ftNone): TMethodTreeNode;

    function GetMethodNodeByVisibility(Visibility: TVisibilityEnumSet): TList<TMethodTreeNode>;

    property ID: Integer read FID;
    property ClassNodeName: String read FClassNodeName;
    property ClassNodeType: TClassNodeTypeEnum read FClassNodeType;
    property DeclarationLine: Integer read FDeclarationLine;
    property OwnerClassNode: TClassTreeNode read FOwnerClassNode;

    property MethodList: TList<TMethodTreeNode> read FMethodList;
    property NestedClassNodes: TObjectList<TClassTreeNode> read FNestedClassNodes;
  end;

implementation

uses
  SysUtils
  ;

{ TClassTreeNode }

constructor TClassTreeNode.Create(
  ID: Integer;
  ClassName: String;
  ClassType: TClassNodeTypeEnum;
  DeclarationLine: Integer;
  OwnerClassNode: TClassTreeNode
);
begin
  FID := ID;
  FClassNodeName := ClassName;
  FClassNodeType := ClassType;
  FDeclarationLine := DeclarationLine;
  FOwnerClassNode := OwnerClassNode;

  FMethodList := TList<TMethodTreeNode>.Create;
  FNestedClassNodes := TObjectList<TClassTreeNode>.Create(True);
end;

constructor TClassTreeNode.Create(
  ID: Integer;
  ClassName: String;
  ClassType: TClassNodeTypeEnum;
  DeclarationLine: Integer
);
begin
  Create(ID, ClassNodeName, ClassType, DeclarationLine, nil);
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
  MethodType: TFunctionTypeEnum = ftNone): TMethodTreeNode;
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

end.
