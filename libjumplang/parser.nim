import npeg, ast
import npeg/codegen
import npeg_utils/[indent, astc]
import std/[strutils, parseutils]

let parser = peg("file", ac: AdoptionCenter[JlNode]):
  # Utils
  W <- *Blank
  ArgList <- astc.hooked(?Expr * W * *(',' * W * Expr * W) * ?','):
    var arl = newArgList()
    adoptCycle(ac, arl)
  FArgList <- astc.hooked(Expr * W * *(',' * W * Expr * W) * ?','):
    var arl = newArgList()
    adoptCycle(ac, arl)
    
  Escape <- '\\' * {'n', 't', '"'}

  # Main
  JLineType <- VarDecl | PrimaryExpr
  JLine <- ib.Line(&1 * ?JLineType * ?Comment)
  StmtList <- astc.hooked(+(StandaloneStmt | JLine)):
    var ls = newStmtList()
    adoptCycle(ac, ls)

  Ident <- >(Alpha * *Alnum):
    ac.add newIdent($1)
  IdentCheck <- Alpha * *Alnum

  VarDecl <- &(IdentCheck * W * '=') * Ident * W * '=' * W * Expr: # Ensure ident checks so no extra appear
    var vd = newVarDecl()
    adoptCycle(ac, vd, 2)

  # Literals
  StrLit <- '"' * >(*(1-{'\n', '\t', '"'})) * '"':
    ac.add newStrLit($1)
  IntLit <- >(?'-' * +Digit):
    ac.add newIntLit(parseInt($1))
  FloatLit <- >(?'-' * +Digit * "." * +Digit): 
    var res: float
    doAssert parseFloat($1, res) == len($1)
    ac.add newFloatLit(res)
  BoolLit <- >("true" | "false"):
    if $1 == "true":
      ac.add newBoolLit(true)
    else:
      ac.add newBoolLit(false)
  Lit <- W * (BoolLit | StrLit | FloatLit | IntLit) * W
  Comment <- W * '#' * *(1 - {'\n', '\r'})

  # Exprs
  OpKind <- >(">=" | "<=" | "==" | '>' | '<' | {'*', '/', '+', '-'}):
    ac.add newOp($1)
  Expr <- OpExpr 
  OpEnd <- W * >OpKind * W * PrimaryExpr:
    var op = newOpExpr()
    adoptCycle(ac, op, 3)

  OpExpr <- PrimaryExpr * *(OpEnd) * W
  GroupExpr <- '(' * Expr * ')'
  PrimaryExpr <- (Lit | GroupExpr)  | (Ident * *PrimarySuffix)

  CallExpr <- '(' * ArgList * ')':
    var kwe = newCallExpr()
    adoptCycle(ac, kwe, 2)

  KwExpr <- +Blank * FArgList:
    var kwe = newKwExpr()
    adoptCycle(ac, kwe, 2)
  PrimarySuffix <- CallExpr | KwExpr

  # StandaloneStmt
  IfStmt <- ib.Line("if" * +Blank * Expr * W * ':' * ?Comment) * ib.Block(StmtList):
    var ifs = newIfStmt()
    adoptCycle(ac, ifs, 2)

  #[
  FlagStmt <- ib.Line("flag" * +Blank * Ident * W * ':' * ?Comment) * ib.Block(StmtList):
    var f = newFlagStmt()
    adoptCycle(ac, f, 2)
  ]#

  DefStmt(kw) <- ib.Line(kw * +Blank * Ident * W * '(' * W * ArgList * W * ')' * W * ':' * ?Comment) * ib.Block(StmtList)
  FuncStmt <- DefStmt("func"):
    var def = newFuncStmt()
    adoptCycle(ac, def, 3)
  TemplateStmt <- DefStmt("template"):
    var def = newTemplateStmt()
    adoptCycle(ac, def, 3)
  StandaloneStmt <- IfStmt | FuncStmt | TemplateStmt # FlagStmt | 

  # File
  file <- StmtList * !1

type 
  JlSyntaxError = object of CatchableError
  MultiFileInfo = ref object
   line: int
   cola: int
   colb: int
   snippet: string


proc getMultiFileInfo(data: string, ls: (int, int)): MultiFileInfo =
  ## Extract line, col and snippet data from a string.
  var linecount = 1
  var colcount = 1
  var total = 0
  var datacopy: string
  result = MultiFileInfo()
  for c in datacopy:
    if total == ls[0]:
      result.cola = colcount
      result.line = linecount
    if total >= ls[0]:
      result.snippet.add c
    if total == ls[1]:
      result.colb = colcount
      return result
    if c == '\n':
      linecount += 1
      colcount = 0
    colcount += 1
    total += 1

proc check(m: MatchResult, data: string, fname="<Unnamed>") =
  ## Make syntax error if parse result is not ok 
  if not m.ok:
    let info = getMultiFileInfo(data, (m.matchLen, m.matchMax))
    var msg = "Syntax Error in " & fname & " (" & $(info.line)
    msg.add ", " & $(info.cola) & ':' & $(info.colb) & "):"
    msg.add "  " & info.snippet
    raise newException(JlSyntaxError, msg)

proc parseFile*(f: string): JlNode =
  ## Parse file wrapper
  var ac = newAdoptionCenter[JlNode]()
  let filedata = f.readFile
  when defined(windows) or defined(posix):
    check parser.matchFile(f, ac), filedata, f
  else:
    check parser.match(filedata, ac), filedata, f
  ac[0].ensureAst()
  return ac[0]

proc parse*(d: string): JlNode =
  ## Parse string wrapper
  var ac = newAdoptionCenter[JlNode]()
  check parser.match(d, ac), d
  ac[0].ensureAst()
  return ac[0]