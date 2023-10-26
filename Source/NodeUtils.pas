unit NodeUtils;

interface

uses
    DelphiAST.Classes
  , DelphiAST.Consts
  ;
type
  TFindMode = (fmCanSelfRecurse, fmNoSelfRecurse);

function FindAllNodesOfType(
  Node: TSyntaxNode;
  NodeType: TSyntaxNodeType;
  FindMode: TFindMode
): TArray<TSyntaxNode>;

implementation

uses
    System.Generics.Collections
  , System.SysUtils
  ;

// Using TObjectList instead of appending to array for optimal list collection
procedure FindNodeOfTypeRecursively(
  FoundNodes: TObjectList<TSyntaxNode>;
  Node: TSyntaxNode;
  NodeType: TSyntaxNodeType;
  FindMode: TFindMode
);
var
  ChildNode: TSyntaxNode;
begin
  for ChildNode in Node.ChildNodes do begin
    if ChildNode.Typ = NodeType then begin
      FoundNodes.Add(ChildNode);
      if FindMode = fmCanSelfRecurse then begin
        FindNodeOfTypeRecursively(FoundNodes, ChildNode, NodeType, FindMode);
      end;
    end
    else begin
      // @TODO If we have complete knowledge, we can try to ignore certain node type because we know all possible
      //       child node for optimisation
      FindNodeOfTypeRecursively(FoundNodes, ChildNode, NodeType, FindMode);
    end;
  end;
end;

function FindAllNodesOfType(
  Node: TSyntaxNode;
  NodeType: TSyntaxNodeType;
  FindMode: TFindMode
): TArray<TSyntaxNode>;
var
  FoundNodes: TObjectList<TSyntaxNode>;
begin
  FoundNodes := TObjectList<TSyntaxNode>.Create(False);

  FindNodeOfTypeRecursively(FoundNodes, Node, NodeType, FindMode);

  Result := FoundNodes.ToArray;
  FreeAndNil(FoundNodes);
end;

end.