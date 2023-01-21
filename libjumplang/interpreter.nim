import std/tables, ast, keywords
type
  ArType* = enum Global, Function
  NativeTypeError = object of ValueError

  JlObjKind = enum NativeInt, NativeStr, NativeBool, Func, FlagBlock
  JlObj = ref object
    case kind: JlObjKind
    of NativeInt:
      i: int
    of NativeStr:
      s: string
    of NativeBool:
      b: bool
    of Func:
      params: seq[string]
      name: string
      body: JlNode # StmtList
    of FlagBlock:
      flag: string
      internal: JlNode # StmtLit

  ActivationRecord = ref object
    name*: string
    typ*: ArType
    lvl: int
    data: Table[string, JlObj]

  CallStack = seq[ActivationRecord]

  Interpreter = ref object
    stack: CallStack
    tree: JlNode
  InterpreterResult* = ref object
    failed*: bool
    msg*: string
    stack*: CallStack

proc expectKind(o: JlObj, k: JlObjKind) =
  if o.kind != k:
    raise newException(NativeTypeError, "Got wrong kind")

proc newNativeStr(s: string): JlObj = JlObj(kind: NativeStr, s: s)

proc newNativeBool(b: bool): JlObj = JlObj(kind: NativeBool, b: b)

proc newNativeInt(i: int): JlObj = JlObj(kind: NativeInt, i: i)

proc `[]`(i: Interpreter, key: string): JlObj = i.stack[^1].data[key]

proc v(i: Interpreter): ActivationRecord = i.stack[^1]

proc `[]=`(i: Interpreter, key: string, v: JlObj) = i.stack[^1].data[key] = v

when defined(js):
  var output: string

proc visit(i: var Interpreter, n: JlNode): JlObj =
  case n.kind
  of VarDecl:
    let ident = n[0].getStr()
    let value = i.visit(n[1])
    i[ident] = value
  of Ident:
    return i[n.getStr]
  of StrLit:
    return newNativeStr(n.getStr)
  of IntLit:
    return newNativeInt(n.getInt)
  of BoolLit:
    return newNativeBool(n.getBool)
  of FuncStmt:
    var obj = JlObj(kind: Func, name: n[0].getStr)
    for i in n[1]:
      obj.params.add i.getStr
    obj.body = n[2]
    i[n[0].getStr] = obj
  of CallExpr:
    let ident = n[0].getStr
    let f = i[ident]
    f.expectKind(Func)
    var ar = ActivationRecord(name: ident, typ: Function, lvl: i.v.lvl+1)
    i.stack.add ar
    when defined(jlDebugIt):
      echo "Entering: ", ar[]
    for index, item in f.params:
      i[item] = i.visit(n[1][index])
    discard i.visit(f.body)
    discard i.stack.pop
    when defined(jlDebugIt):
      echo "Exiting: ", ar[]
  of IfStmt:
    let cond = i.visit(n[0])
    if cond.b:
      discard i.visit(n[1])
  of KwExpr:
    visitKw()
  of FlagStmt:
    var obj = JlObj(kind: FlagBlock, flag: n[0].getStr, internal: n[1])
    i[n[0].getStr] = obj
  of OpExpr:
    visitOp()
  else: 
    if n.kind in lsSet:
      echo "Sending: ", n.kind
      for child in n:
        discard i.visit(child)

proc interpret*(n: JlNode, name: string): InterpreterResult =
  var i = Interpreter(tree: n) 
  var ar = ActivationRecord(name: name, typ: Global, lvl: 1)
  result = InterpreterResult(failed: false)
  when defined(jlDebugIt):
    echo "Entering: ", ar[]
  i.stack.add ar
  try:
    discard i.visit(n)
  except CatchableError as e:
    result.failed = true
    result.msg = e.msg
    result.stack = i.stack
  when defined(jlDebugIt):
    echo "Exiting: ", ar[]
  discard i.stack.pop