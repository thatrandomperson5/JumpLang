import npeg, ast
import npeg_utils/[indent, astc]
import std/[strutils]

let parser = peg("file", ac: AdoptionCenter[JlNode]):
  # Utils
  W <- *Blank
  ArgList <- astc.hooked(Expr * W * *(',' * W * Expr * W) * ?','):
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
  BoolLit <- >("true" | "false"):
    if $1 == "true":
      ac.add newBoolLit(true)
    else:
      ac.add newBoolLit(false)
  Lit <- W * (BoolLit | StrLit | IntLit) * W
  Comment <- W * '#' * *(1 - {'\n', '\r'})

  # Exprs
  OpKind <- >(">=" | "<=" | "==" | '>' | '<' | {'+', '-', '*', '/'}):
    ac.add newOp($1)
  Expr <- OpExpr 
  OpEnd <- W * >OpKind * W * PrimaryExpr:
    var op = newOpExpr()
    adoptCycle(ac, op, 3)

  OpExpr <- PrimaryExpr * *(OpEnd) * W
  PrimaryExpr <- Lit | (Ident * *PrimarySuffix)

  CallExpr <- '(' * ArgList * ')':
    var kwe = newCallExpr()
    adoptCycle(ac, kwe, 2)

  KwExpr <- +Blank * ArgList:
    var kwe = newKwExpr()
    adoptCycle(ac, kwe, 2)
  PrimarySuffix <- CallExpr | KwExpr

  # StandaloneStmt
  IfStmt <- ib.Line("if" * +Blank * Expr * W * ':' * ?Comment) * ib.Block(StmtList):
    var ifs = newIfStmt()
    adoptCycle(ac, ifs, 2)
  FlagStmt <- ib.Line("flag" * +Blank * Ident * W * ':' * ?Comment) * ib.Block(StmtList):
    var f = newFlagStmt()
    adoptCycle(ac, f, 2)

  DefStmt(kw) <- ib.Line(kw * +Blank * Ident * W * '(' * W * ArgList * W * ')' * W * ':' * ?Comment) * ib.Block(StmtList)
  FuncStmt <- DefStmt("func"):
    var def = newFuncStmt()
    adoptCycle(ac, def, 3)
  TemplateStmt <- DefStmt("template"):
    var def = newTemplateStmt()
    adoptCycle(ac, def, 3)
  StandaloneStmt <- FlagStmt | IfStmt | FuncStmt | TemplateStmt

  # File
  file <- StmtList * !1

proc parseFile*(f: string): JlNode =
  var ac = newAdoptionCenter[JlNode]()
  when defined(windows) or defined(posix):
    doAssert parser.matchFile(f, ac).ok
  else:
    doAssert parser.match(f.readFile, ac).ok
  ac[0].ensureAst()
  return ac[0]

proc parse*(d: string): JlNode =
  var ac = newAdoptionCenter[JlNode]()
  doAssert parser.match(d, ac).ok
  ac[0].ensureAst()
  return ac[0]