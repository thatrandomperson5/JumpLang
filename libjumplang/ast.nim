import std/strformat
import keywords
  
type
  JlKindError = object of ValueError

  JlKind* = enum OpExpr, Ident, StrLit, IntLit, BoolLit, KwExpr, StmtList, VarDecl, ArgList, CallExpr,
           IfStmt, FuncStmt, TemplateStmt, Op, FlagStmt

  JlNode* = ref object
    case kind*: JlKind
    of Ident, StrLit, Op:
      s: string
    of IntLit:
      i: int
    of BoolLit:
      b: bool
    of StmtList, ArgList, IfStmt, VarDecl, KwExpr, CallExpr, FuncStmt, TemplateStmt, OpExpr, FlagStmt:
      list: seq[JlNode]

const lsSet* = {StmtList, ArgList, IfStmt, VarDecl, KwExpr, CallExpr, FuncStmt, TemplateStmt, OpExpr, FlagStmt}
const litSet = {StrLit, IntLit, BoolLit}
const exprSet = {OpExpr, KwExpr, CallExpr}
const valueSet = {Ident} + litSet + exprSet

proc expectKind*(n: JlNode, k: JlKind) =
  if n.kind != k:
    raise newException(JlKindError, fmt"Got kind {n.kind} but expected {k}")

proc expectKind*(n: JlNode, k: set[JlKind]) =
  if n.kind notin k:
    raise newException(JlKindError, fmt"Got kind {n.kind} but expected {k}")

proc getStr*(n: JlNode): string =
  n.expectKind {Ident, StrLit, Op}
  return n.s

proc getInt*(n: JlNode): int =
  n.expectKind {IntLit}
  return n.i

proc getBool*(n: JlNode): bool =
  n.expectKind {BoolLit}
  return n.b

proc newIdent*(s: string): JlNode = JlNode(kind: Ident, s: s)

proc newArgList*(): JlNode = JlNode(kind: ArgList)

proc newFlagStmt*(): JlNode = JlNode(kind: FlagStmt)

proc newIfStmt*(): JlNode = JlNode(kind: IfStmt)

proc newFuncStmt*(): JlNode = JlNode(kind: FuncStmt)

proc newTemplateStmt*(): JlNode = JlNode(kind: TemplateStmt)

proc newVarDecl*(): JlNode = JlNode(kind: VarDecl)

proc newStmtList*(): JlNode = JlNode(kind: StmtList)

proc newOpExpr*(): JlNode = JlNode(kind: OpExpr)

proc newOp*(s: string): JlNode = JlNode(kind: Op, s: s)

proc newStrLit*(s: string): JlNode = JlNode(kind: StrLit, s: s)

proc newIntLit*(i: int): JlNode = JlNode(kind: IntLit, i: i)

proc newBoolLit*(b: bool): JlNode = JlNode(kind: BoolLit, b: b)

proc newKwExpr*(): JlNode = 
  return JlNode(kind: KwExpr)

proc newCallExpr*(): JlNode = 
  return JlNode(kind: CallExpr)

proc len*(node: JlNode): int =
  node.expectKind lsSet
  return node.list.len

proc add*(node: var JlNode, child: JlNode) =
  node.expectKind lsSet
  node.list.add child

proc `[]`*(node: JlNode, i: int): JlNode =
  node.expectKind lsSet
  return node.list[i]

iterator items*(n: JlNode): JlNode = 
  echo "Got: ", n.kind
  n.expectKind lsSet
  for item in n.list:
    yield item

proc traverseAst(node: JlNode, indent: int, res: var string) =
  for _ in 0..indent:
     res.add "   "
  case node.kind:
  of StrLit, Ident, Op:
    res.add $(node.kind) & ": " & node.s & "\n"
  of IntLit:
    res.add "IntLit: " & $(node.i) & "\n"
  of BoolLit:
    res.add "BoolLit: " & $(node.b) & "\n"
  of StmtList, ArgList, IfStmt, VarDecl, KwExpr, CallExpr, FuncStmt, TemplateStmt, OpExpr, FlagStmt:
    res.add $(node.kind) & ": \n"
    for item in node:
      traverseAst(item, indent+1, res)

proc `$`*(node: JlNode): string = 
  result = ""
  traverseAst(node, -1, result)

proc expectLen*(node: JlNode, l: int) =
  if node.len != l:
    raise newException(JlKindError, fmt"Expected {l} items but got {node.len}")

proc ensureAst*(node: JlNode) = 
  node.expectKind StmtList
  for child in node:
    case child.kind
    of OpExpr:
      child.expectLen(2)
      child[0].expectKind(valueSet)
      child[1].expectKind(Op)
      child[2].expectKind(valueSet)
    of IfStmt:
      child.expectLen(2)
      child[0].expectKind(valueSet)
      child[1].expectKind(StmtList)
      child[1].ensureAst()
    of FlagStmt:
      child.expectLen(2)
      child[0].expectKind(Ident)
      child[1].expectKind(StmtList)
      child[1].ensureAst()
    of VarDecl:
      child.expectLen(2)
      child[0].expectKind(Ident)
      child[1].expectKind(valueSet)
    of CallExpr:
      child.expectLen(2)
      child[0].expectKind(Ident)
      child[1].expectKind(ArgList)
      for sub in child[1]:
        sub.expectKind(valueSet)
    of KwExpr:
      astHandleKeywords()

    of FuncStmt, TemplateStmt:
      child.expectLen(3)
      child[0].expectKind(Ident)
      child[1].expectKind(ArgList)
      for sub in child[1]:
        sub.expectKind(Ident)
      child[2].expectKind(StmtList)
      child[2].ensureAst()    
    else: 
      discard

