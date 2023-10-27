unit MethodTreeNodes;

interface

uses
  System.Generics.Collections
  ;

type

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

  private
    FID: Integer;
    FFunctionName: String;
    FFunctionType: TMethodTypeEnum;
    FVisibility: TVisibilityEnum;

    FDeclarationLine: Integer;
    FImplementationLine: Integer;
    FReturn: String;
    FClassNodeName: String;

    FMethodsCalledWithinThisMethod: TList<TMethodTreeNode>;
    FCallerList: TList<TMethodTreeNode>;

    FHasRecursion: Boolean;

    FSelected: Boolean;

    function HasCallerRecursion(MethodNode: TMethodTreeNode): Boolean;

    function GetVisibilityAsString: String;

  public
    constructor Create(
      FunctionName: String;
      FunctionType: TMethodTypeEnum;
      Visibility: TVisibilityEnum;
      DeclarationLine: Integer = 1;
      ImplementationLine: Integer = 1;
      Return: String = ''); overload;
    constructor Create; overload;
    destructor Destroy; override;

    procedure AddMethodCall(CallingMethodNode: TMethodTreeNode);

    property ID: Integer read FID write FID;
    property FunctionName: String read FFunctionName write FFunctionName;
    property FunctionType: TMethodTypeEnum read FFunctionType write FFunctionType;
    property Visibility: TVisibilityEnum read FVisibility write FVisibility;
    property VisibilityAsString: String read GetVisibilityAsString;
    property DeclarationLine: Integer read FDeclarationLine write FDeclarationLine;
    property ImplementationLine: Integer read FImplementationLine write FImplementationLine;
    property MethodsCalledWithinThisMethod: TList<TMethodTreeNode> read FMethodsCalledWithinThisMethod;
    property CallerList: TList<TMethodTreeNode> read FCallerList;
    property HasRecursion: Boolean read FHasRecursion;
    property Selected: Boolean read FSelected write FSelected;
    property ClassNodeName: String read FClassNodeName write FClassNodeName;
    property Return: String read FReturn write FReturn;
  end;

implementation

uses
  SysUtils
  ;

{ TFunctionTreeNode }

constructor TMethodTreeNode.Create(
  FunctionName: String;
  FunctionType: TMethodTypeEnum;
  Visibility: TVisibilityEnum;
  DeclarationLine: Integer = 1;
  ImplementationLine: Integer = 1;
  Return: String = '');

begin
  FFunctionName := FunctionName;
  FFunctionType := FunctionType;
  FVisibility := Visibility;
  FMethodsCalledWithinThisMethod := TList<TMethodTreeNode>.Create;
  FCallerList := TList<TMethodTreeNode>.Create;
  FHasRecursion := False;
  FReturn := Return;
end;

constructor TMethodTreeNode.Create;
begin
  Create('NULLNAME', ftProcedure, vPrivate);
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

end.
