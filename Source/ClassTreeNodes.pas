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

  private
    FID: Integer;
    FClassNodeName: String;
    FClassNodeType: TClassNodeTypeEnum;
    FDeclarationLine: Integer;
    FMethodList: TList<TMethodTreeNode>;

  public
    constructor Create(
      ID: Integer;
      ClassName: String;
      ClassType: TClassNodeTypeEnum;
      DeclarationLine: Integer = 1);
    destructor Destroy; override;

    procedure AddFunctionTreeNode(Node: TMethodTreeNode);

    function GetMethodNode(
      MethodName: String;
      MethodType: TFunctionTypeEnum = ftNone): TMethodTreeNode;

    function GetMethodNodeByVisibility(Visibility: TVisibilityEnumSet): TList<TMethodTreeNode>;

    property ID: Integer read FID write FID;
    property ClassNodeName: String read FClassNodeName write FClassNodeName;
    property ClassNodeType: TClassNodeTypeEnum read FClassNodeType write FClassNodeType;
    property DeclarationLine: Integer read FDeclarationLine write FDeclarationLine;
    property MethodList: TList<TMethodTreeNode> read FMethodList;
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
  DeclarationLine: Integer = 1);
begin
  FID := ID;
  FClassNodeName := ClassName;
  FClassNodeType := ClassType;
  FDeclarationLine := DeclarationLine;
  FMethodList := TList<TMethodTreeNode>.Create;
end;

destructor TClassTreeNode.Destroy;
var
  Iteration: TMethodTreeNode;
begin
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
