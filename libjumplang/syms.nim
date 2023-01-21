import std/[tables, strformat]
import ast, keywords
type
  SemanticError = object of ValueError
  SymKind* = enum NativeSym, VarSym, FuncSym, TemplateSym, ParamSym, FlagSym

  Symbol* = object
    name: string
    case kind: SymKind
    of FuncSym, TemplateSym:
      params: seq[Symbol]
    else:
      discard

  ScopedSymTable* = object
    scope: int
    name: string
    t: Table[string, Symbol]

  SymTable* = ref ScopedSymTable
  SymContext = ref object
    stack: seq[SymTable]

proc newSymTable*(name: string, scope: int): SymTable = SymTable(name: name, scope: scope)

proc `[]=`*(t: var SymTable, key: string, value: Symbol) = t.t[key] = value

proc `[]`*(t: SymTable, key: string): Symbol = t.t[key]

proc `[]=`*(s: var SymContext, key: string, value: Symbol) = s.stack[^1][key] = value

proc v(s: SymContext): SymTable = s.stack[^1]

proc `$`*(t: SymTable): string = 
  result.add "Name: " & t.name & "\n"
  result.add "Scope: " & $(t.scope) & "\n"
  result.add "Symbols: \n"
  for key, value in t.t:
    result.add "    " & key & ": " & $value & "\n"

proc enter(s: var SymContext, n: SymTable) =
  s.stack.add n

proc exit(s: var SymContext) =
  discard s.stack.pop

proc definedIdent(s: SymContext, i: string, acceptFlags=false): bool =
  for n in 1..s.stack.len:
    let current = s.stack[^n]
    if i in current.t:
      if (not acceptFlags) and (s.v.t[i].kind == FlagSym):
        continue
      return true
  return false
proc inScope(s: SymContext, i: string): bool =
  if i in s.v.t:
    return true
  return false

proc raiseSemanticError(b: bool, name: string, t: int) =
  if not b:
    if t == 0:
      raise newException(SemanticError, fmt"Undeclared Identifier {name}!")
    elif t == 1:
      raise newException(SemanticError, fmt"ReDeclared Identifier {name}!")


proc walkSyms(n: JlNode, s: var SymContext) =
  case n.kind:
  of VarDecl:
    let i = n[0].getStr()
    s[i] = Symbol(name: i, kind: VarSym)
  of FuncStmt:
    let i = n[0].getStr()
    raiseSemanticError(not s.inScope(i), i, 1)
    var ns = Symbol(name: i, kind: FuncSym)
    var newTb = newSymTable(i, s.v.scope+1)
    for child in n[1]:
      let i = child.getStr()
      newTb[i] = Symbol(name: i, kind: ParamSym)
      ns.params.add Symbol(name: i, kind: ParamSym)
    when defined(jlDebugSym):
      echo "Entering: ", i
    s[i] = ns
    s.enter(newTb)
    for child in n[2]:
      walkSyms(child, s)
    when defined(jlDebugSym):
      echo s.v
    s.exit()
  of TemplateStmt:
    let i = n[0].getStr()
    raiseSemanticError(not s.inScope(i), i, 1)
    s[i] = Symbol(name: i, kind: TemplateSym)
  of FlagStmt:
    let i = n[0].getStr()
    raiseSemanticError(not s.inScope(i), i, 1)
    s[i] = Symbol(name: i, kind: FlagSym)
    for child in n[1]:
      walkSyms(child, s)
  of Ident:
    definedIdent(s, n.getStr()).raiseSemanticError(n.getStr, 0)
  of CallExpr:
    let i = n[0].getStr()    
    definedIdent(s, i).raiseSemanticError(i, 0)    
    let expected = s.v[i].params.len
    if n[1].len != expected:
      raise newException(SemanticError, fmt"Expected {expected} args but got {n[1].len} for {i}!")
    for child in n[1]:
      walkSyms(child, s)      
    
  of KwExpr:
    symHandleKeywords()
  else:
    if n.kind in lsSet:
      for child in n:
        walkSyms(child, s)

proc newNativeSym(name: string): Symbol = Symbol(kind: NativeSym, name: name)

proc addDefaults(s: var SymTable) =
  discard

proc ensureSemantics*(n: JlNode) =
  var sy = newSymTable("global", 0)
  sy.addDefaults()
  let l = @[sy]
  var s = SymContext(stack: l)
  when defined(jlDebugSym):
    echo "Entering: global"
  try:
    n.walkSyms(s)
  finally:
    when defined(jlDebugSym):
      echo s.v
    else:
      discard
