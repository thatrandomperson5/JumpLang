import std/tables, ast, keywords, bytecode
type
  ArType* = enum Global, Function, Block


  ActivationRecord = ref object
    name*: string
    typ*: ArType
    retr: int
    lvl: int
    data: Table[string, JlObj]

  CallStack = seq[ActivationRecord]

  Interpreter = ref object
    stack: CallStack
    code: seq[BC]
    pos: int
    memstack: seq[JlObj]
    
  InterpreterResult* = ref object
    failed*: bool
    msg*: string
    stack*: CallStack

proc `$`*(ar: ActivationRecord): string =
  result.add "Name: " & ar.name & "\n"
  result.add "Type: " & $(ar.typ) & "\n"
  result.add "Lvl: " & $(ar.lvl) & "\n"
  result.add "Data: \n"
  for key, value in ar.data:
    result.add key & ": " & $(value[]) & "\n"

proc `[]`(i: Interpreter, key: string): JlObj = 
  for index in 1..i.stack.len:
    let item = i.stack[^index]
    if key in item.data:
      return item.data[key]
  raise newException(CatchableError, "Interpreter failure, symbol checks have failed.")

proc v(i: Interpreter): ActivationRecord = i.stack[^1]


proc mpop(i: var Interpreter): JlObj = i.memstack.pop

proc madd(i: var Interpreter, v: JlObj) = i.memstack.add v

proc `[]=`(i: Interpreter, key: string, v: JlObj) = i.stack[^1].data[key] = v

when defined(js):
  var output*: string




proc run(i: var Interpreter) =
  let current = i.code[i.pos]
  case current.kind
  of PUSH:
    i.madd current.value
  of ECHO:
    var s = ""
    for _ in 1..current.amount:
      s = i.mpop.ensureStr() & " " & s
    when defined(js):
      output.add s & "\n"
    else:
      echo s
  of SET:
    i[current.name] = i.mpop
  of GET:
    i.madd i[current.name]
  of ENTERFUNC:
    var ar = ActivationRecord(name: current.name, typ: Function, lvl: i.v.lvl+1, retr: i.pos+1)
    i.stack.add ar

  of JUMP:
    i.pos = i.mpop.getAddr
  of RETURN:
    var ar = i.stack.pop
    while true:
      if ar.typ == Function:
        i.pos = ar.retr
        break
      if i.stack.len == 0:
        raise newException(CatchableError, "Interpreter failure, symbol checks have failed.")
      ar = i.stack.pop

  of EXIT:
    when defined(jlDebugIt):
      echo $(i.v)
    discard i.stack.pop
  of IF:
    if not i.mpop.ensureBool:
      i.pos = current.amount
    else:
      var ar = ActivationRecord(name: "if", typ: Block, lvl: i.v.lvl+1)
      i.stack.add ar

  # Start ops   
  of ADDOP:
    i.madd newNativeFloat(i.mpop.ensureFloat + i.mpop.ensureFloat)
  of SUBOP:
    let rev = [i.mpop.ensureFloat, i.mpop.ensureFloat]
    i.madd newNativeFloat(rev[1] - rev[0])
  of MULTOP:
    i.madd newNativeFloat(i.mpop.ensureFloat * i.mpop.ensureFloat)
  of DIVOP:
    let rev = [i.mpop.ensureFloat, i.mpop.ensureFloat]
    i.madd newNativeFloat(rev[1] / rev[0])
  of EQOP:
    i.madd newNativeBool(i.mpop.ensureBool == i.mpop.ensureBool)
  of GTEOP:
    let rev = [i.mpop.ensureFloat, i.mpop.ensureFloat]
    i.madd newNativeBool(rev[1] >= rev[0])
  of LTEOP:
    let rev = [i.mpop.ensureFloat, i.mpop.ensureFloat]
    i.madd newNativeBool(rev[1] <= rev[0])
  of GTOP:
    let rev = [i.mpop.ensureFloat, i.mpop.ensureFloat]
    i.madd newNativeBool(rev[1] >= rev[0])
  of LTOP:
    let rev = [i.mpop.ensureFloat, i.mpop.ensureFloat]
    i.madd newNativeBool(rev[1] < rev[0])
  i.pos += 1
  when defined(jlDebugIt):
    echo i.pos, ": ", i.memstack




proc interpret*(code: seq[BC], name: string): InterpreterResult =
  when defined(js):
    output = ""

  var i = Interpreter(code: code, pos: 0) 
  var ar = ActivationRecord(name: name, typ: Global, lvl: 1)
  result = InterpreterResult(failed: false)
  when defined(jlDebugIt):
    echo "Entering: ", ar.name
  i.stack.add ar
  try:
    while i.pos <= code.high:
      i.run()
  except NativeTypeError as e:
    result.failed = true
    result.msg = e.msg
    result.stack = i.stack
  when defined(jlDebugIt):
    echo "Exiting: ", $ar
  discard i.stack.pop