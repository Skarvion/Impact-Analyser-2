unit FunctionTreeNodes;

interface

uses
  System.Generics.Collections
  ;

type

  TFunctionTypeEnum = (
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

  TMethodTreeNode = class(TObject)
  public const
    C_FunctionTypeString: array [TFunctionTypeEnum] of String = (
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

  private
    FID: Integer;
    FFunctionName: String;
    FFunctionType: TFunctionTypeEnum;
    FVisibility: TVisibilityEnum;

    FDeclarationLine: Integer;
    FImplementationLine: Integer;

    FMethodCallList: TList<TMethodTreeNode>;
    FCallerList: TList<TMethodTreeNode>;

    FHasRecursion: Boolean;

    function HasCallerRecursion(MethodNode: TMethodTreeNode): Boolean;

    function GetVisibilityAsString: String;

  public
    constructor Create(
      FunctionName: String;
      FunctionType: TFunctionTypeEnum;
      Visibility: TVisibilityEnum;
      DeclarationLine: Integer = 1;
      ImplementationLine: Integer = 1); overload;
    constructor Create; overload;
    destructor Destroy; override;

    procedure AddMethodCall(MethodNode: TMethodTreeNode);

    property ID: Integer read FID write FID;
    property FunctionName: String read FFunctionName write FFunctionName;
    property FunctionType: TFunctionTypeEnum read FFunctionType write FFunctionType;
    property Visibility: TVisibilityEnum read FVisibility write FVisibility;
    property VisibilityAsString: String read GetVisibilityAsString;
    property DeclarationLine: Integer read FDeclarationLine write FDeclarationLine;
    property ImplementationLine: Integer read FImplementationLine write FImplementationLine;
    property MethodCallList: TList<TMethodTreeNode> read FMethodCallList;
    property CallerList: TList<TMethodTreeNode> read FCallerList;
    property HasRecursion: Boolean read FHasRecursion;
  end;

implementation

uses
  SysUtils
  ;

{ TFunctionTreeNode }

constructor TMethodTreeNode.Create(
  FunctionName: String;
  FunctionType: TFunctionTypeEnum;
  Visibility: TVisibilityEnum;
  DeclarationLine: Integer = 1;
  ImplementationLine: Integer = 1);
begin
  FFunctionName := FunctionName;
  FFunctionType := FunctionType;
  FVisibility := Visibility;
  FMethodCallList := TList<TMethodTreeNode>.Create;
  FCallerList := TList<TMethodTreeNode>.Create;
  FHasRecursion := False;
end;

constructor TMethodTreeNode.Create;
begin
  Create('NULLNAME', ftProcedure, vPrivate);
end;

destructor TMethodTreeNode.Destroy;
begin
  FreeAndNil(FCallerList);
  FreeAndNil(FMethodCallList);
  inherited;
end;

procedure TMethodTreeNode.AddMethodCall(MethodNode: TMethodTreeNode);
begin
  if HasCallerRecursion(MethodNode) then begin
    MethodNode.FHasRecursion := True;
  end
  else begin
    MethodNode.FCallerList.Add(Self);
    FMethodCallList.Add(MethodNode);
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

end.
