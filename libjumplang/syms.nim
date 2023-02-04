import std/[tables, strformat]
import ast, keywords

## Checks to make sure the code will not break run-time, currently not connected to any other files
  
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
    kind: SymTableKind 
    t: Table[string, Symbol]
  SymTableKind {.pure.} = enum stkFunc, stkGlobal

  SymTable* = ref ScopedSymTable
  SymContext = ref object
    stack: seq[SymTable]

# Misc utils

proc newSymTable*(name: string, scope: int, kind: SymTableKind): SymTable = 
  return SymTable(name: name, scope: scope, kind: kind)

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
  ## Enter a scope
  s.stack.add n

proc exit(s: var SymContext) =
  ## Exit current scope
  discard s.stack.pop

proc definedIdent(s: SymContext, i: string, acceptFlags=false): bool =
  ## Check if an identifier exisits in any scope
  for n in 1..s.stack.len:
    let current = s.stack[^n]
    if i in current.t:
      if (not acceptFlags) and (s.v.t[i].kind == FlagSym):
        continue
      return true
  return false

proc funcInScope(s: SymContext): bool =
  ## Util to make sure you are inside a function scope
  for n in 1..s.stack.len:
    let current = s.stack[^n]
    if current.kind == stkFunc:
      return true
  return false


proc inScope(s: SymContext, i: string): bool =
  ## Check if a ident is in the current scope, for all scopes see "definedIdent"
  if i in s.v.t:
    return true
  return false

proc raiseSemanticError(b: bool, name: string, t: int) =
  ## Raise sym error
  if not b:
    if t == 0:
      raise newException(SemanticError, fmt"Undeclared Identifier {name}!")
    elif t == 1:
      raise newException(SemanticError, fmt"ReDeclared Identifier {name}!")


proc walkSyms(n: JlNode, s: var SymContext) =
  ## Main semantic checker
  case n.kind:
  of VarDecl: # Add a var sym
    let i = n[0].getStr()
    s[i] = Symbol(name: i, kind: VarSym) 
  of FuncStmt: # Add a func sym and enter a new scope
    let i = n[0].getStr()
    raiseSemanticError(not s.inScope(i), i, 1)
    var ns = Symbol(name: i, kind: FuncSym)
    var newTb = newSymTable(i, s.v.scope+1, stkFunc)
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
  of TemplateStmt: # Unused right now
    let i = n[0].getStr()
    raiseSemanticError(not s.inScope(i), i, 1)
    s[i] = Symbol(name: i, kind: TemplateSym)

  of Ident: # Make sure identifier exists
    definedIdent(s, n.getStr()).raiseSemanticError(n.getStr, 0)
  of CallExpr: # Make sure proper argument amount
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

# Unused, will be used later for system modules
proc newNativeSym(name: string): Symbol = Symbol(kind: NativeSym, name: name)

proc addDefaults(s: var SymTable) =
  discard

proc ensureSemantics*(n: JlNode) =
  ## Light wrapper with debug of walkSyms
  var sy = newSymTable("global", 0, stkGlobal)
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
