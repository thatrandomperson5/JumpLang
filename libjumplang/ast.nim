import std/strformat
import keywords
  
type
  JlKindError = object of ValueError

  JlKind* = enum OpExpr, Ident, StrLit, IntLit, BoolLit, FloatLit, KwExpr, StmtList, VarDecl, ArgList, CallExpr,
           IfStmt, FuncStmt, TemplateStmt, Op

  JlNode* = ref object
    case kind*: JlKind
    of Ident, StrLit, Op:
      s: string
    of IntLit:
      i: int
    of FloatLit:
      f: float
    of BoolLit:
      b: bool
    of StmtList, ArgList, IfStmt, VarDecl, KwExpr, CallExpr, FuncStmt, TemplateStmt, OpExpr:
      list: seq[JlNode]

const lsSet* = {StmtList, ArgList, IfStmt, VarDecl, KwExpr, CallExpr, FuncStmt, TemplateStmt, OpExpr} # A set of all the Ast node types that have children
const litSet = {StrLit, IntLit, BoolLit, FloatLit} # A set of all the Literals
const exprSet = {OpExpr, KwExpr, CallExpr} # A set of expressions
const valueSet = {Ident} + litSet + exprSet # A set of all possible value-like ast kinds

proc expectKind*(n: JlNode, k: JlKind) =
  ## Ensure n is of kind k
  if n.kind != k:
    raise newException(JlKindError, fmt"Got kind {n.kind} but expected {k}")

proc expectKind*(n: JlNode, k: set[JlKind]) =
  ## Ensure n's kind is one of k
  if n.kind notin k:
    raise newException(JlKindError, fmt"Got kind {n.kind} but expected {k}")

proc getStr*(n: JlNode): string =
  ## Get a string value from AST
  n.expectKind {Ident, StrLit, Op}
  return n.s

proc getInt*(n: JlNode): int =
  ## Get a int value from AST
  n.expectKind {IntLit}
  return n.i

proc getBool*(n: JlNode): bool =
  ## Get a bool value from AST
  n.expectKind {BoolLit}
  return n.b

proc getFloat*(n: JlNode): float =
  ## Get a float value from AST
  n.expectKind {FloatLit}
  return n.f

# AST Node initializers based on kind

proc newIdent*(s: string): JlNode = JlNode(kind: Ident, s: s)

proc newArgList*(): JlNode = JlNode(kind: ArgList)

proc newIfStmt*(): JlNode = JlNode(kind: IfStmt)

proc newFuncStmt*(): JlNode = JlNode(kind: FuncStmt)

proc newTemplateStmt*(): JlNode = JlNode(kind: TemplateStmt)

proc newVarDecl*(): JlNode = JlNode(kind: VarDecl)

proc newStmtList*(): JlNode = JlNode(kind: StmtList)

proc newOpExpr*(): JlNode = JlNode(kind: OpExpr)

proc newOp*(s: string): JlNode = JlNode(kind: Op, s: s)

proc newStrLit*(s: string): JlNode = JlNode(kind: StrLit, s: s)

proc newIntLit*(i: int): JlNode = JlNode(kind: IntLit, i: i)

proc newFloatLit*(f: float): JlNode = JlNode(kind: FloatLit, f: f)

proc newBoolLit*(b: bool): JlNode = JlNode(kind: BoolLit, b: b)

proc newKwExpr*(): JlNode = 
  return JlNode(kind: KwExpr)

proc newCallExpr*(): JlNode = 
  return JlNode(kind: CallExpr)

# Basic proc bindings for nodes

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
  n.expectKind lsSet
  for item in n.list:
    yield item

# String $ repr of a tree

proc traverseAst(node: JlNode, indent: int, res: var string) =
  ## Core of the $ proc, is recursive
  for _ in 0..indent:
     res.add "   "
  case node.kind:
  of StrLit, Ident, Op:
    res.add $(node.kind) & ": " & node.s & "\n"
  of IntLit:
    res.add "IntLit: " & $(node.i) & "\n"
  of FloatLit:
    res.add "FloatLit: " & $(node.f) & "\n"
  of BoolLit:
    res.add "BoolLit: " & $(node.b) & "\n"
  of StmtList, ArgList, IfStmt, VarDecl, KwExpr, CallExpr, FuncStmt, TemplateStmt, OpExpr:
    res.add $(node.kind) & ": \n"
    for item in node:
      traverseAst(item, indent+1, res)

proc `$`*(node: JlNode): string = 
  ## Basic launcher for traverseAst
  result = ""
  traverseAst(node, -1, result)

# Misc

proc expectLen*(node: JlNode, l: int) =
  ## Ensure the length of a nodes children
  if node.len != l:
    raise newException(JlKindError, fmt"Expected {l} items but got {node.len}")

proc ensureAst*(node: JlNode) = 
  ## Ensure the validity of a AST tree

  case node.kind
  of OpExpr:
      # {VALUE} {OP} {VALUE}
      node.expectLen(3)
      node[0].expectKind(valueSet)
      node[0].ensureAst()
      node[1].expectKind(Op)
      node[2].expectKind(valueSet)
      node[2].ensureAst()
  of IfStmt:
      # if {VALUE} then (LIST)
      node.expectLen(2)
      node[0].expectKind(valueSet)
      node[0].ensureAst()
      node[1].expectKind(StmtList)
      node[1].ensureAst()
  of VarDecl:
      # {IDENT} = {VALUE}
      node.expectLen(2)
      node[0].expectKind(Ident)
      node[1].expectKind(valueSet)
      node[1].ensureAst()
  of CallExpr:
      # {IDENT}(*{VALUE})
      node.expectLen(2)
      node[0].expectKind(Ident)
      node[1].expectKind(ArgList)
      for sub in node[1]:
        sub.expectKind(valueSet)
        sub.ensureAst()    
  of KwExpr:
      astHandleKeywords()

  of FuncStmt, TemplateStmt:
      # {IDENT}(*{IDENT}): (LIST)
      node.expectLen(3)
      node[0].expectKind(Ident)
      node[1].expectKind(ArgList)
      for sub in node[1]:
        sub.expectKind(Ident)
      node[2].expectKind(StmtList)
      node[2].ensureAst()    
  else: 
    if node.kind in lsSet:
      for child in node:
        child.ensureAst()

