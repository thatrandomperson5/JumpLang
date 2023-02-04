
import ast, keywords
import std/[strutils, parseutils]

type

  NativeTypeError* = object of ValueError
  ## Physical run-time objects
  JlObjKind* = enum NativeInt, NativeStr, NativeBool, NativeFloat, Func, FlagBlock
  JlObj* = ref object # Move later
    case kind: JlObjKind
    of NativeInt:
      i: int
    of NativeStr:
      s: string
    of NativeBool:
      b: bool
    of NativeFloat:
      f: float
    of Func:
      name: string
      address: int
    of FlagBlock:
      flag: string
  ## Bytecode kinds
  BCKind* = enum PUSH, ECHO, SET, GET, JUMP, RETURN, ENTERFUNC, IF, EXIT,
    ADDOP, SUBOP, DIVOP, MULTOP, # + - / *
    EQOP, GTEOP, LTEOP, GTOP, LTOP # == >= <= > <
  BC* = ref object
    case kind*: BCKind
    of PUSH:
      value*: JlObj
    of ECHO, IF:
      amount*: int
    of SET, GET, ENTERFUNC:
      name*: string
    else:
      discard

proc `$`*(obj: JlObj): string = $(obj[])

proc newBCAction(kind: BCKind): BC = BC(kind: kind)

proc getAddr*(obj: JlObj): int =
  ## Get an address from a run-time object
  case obj.kind
  of NativeInt:
    return obj.i
  of Func:
    return obj.address
  else:
    raise newException(NativeTypeError, "Non-adressable object")


proc ensureStr*(obj: JlObj): string =
  ## make sure the result is string
  case obj.kind
  of NativeInt:
    return $(obj.i)
  of NativeStr:
    return $(obj.s)
  of NativeBool:
    return $(obj.b)
  of NativeFloat:
    return $(obj.f)
  else:
    raise newException(NativeTypeError, "Cannot convert type to String")

proc ensureInt*(obj: JlObj): int =
  ## make sure the result is int
  case obj.kind
  of NativeInt:
    return obj.i
  of NativeStr:
    return obj.s.parseInt()
  of NativeBool:
    if obj.b: return 1
    else: return 0
  else:
    raise newException(NativeTypeError, "Cannot convert type to Int")

proc ensureFloat*(obj: JlObj): float =
  ## make sure the result is float
  case obj.kind
  of NativeInt:
    return obj.i.float
  of NativeStr:
    var res: float
    doAssert obj.s.parseFloat(res) == obj.s.len
    return res
  of NativeFloat:
    return obj.f
  else:
    raise newException(NativeTypeError, "Cannot convert type to Float")

proc ensureBool*(obj: JlObj): bool =
  ## make sure the result is bool
  case obj.kind
  of NativeInt:
    return obj.i > 0
  of NativeFloat:
    return obj.f > 0.0
  of NativeStr:
    return obj.s.len > 0
  of NativeBool:
    return obj.b
  else:
    raise newException(NativeTypeError, "Cannot convert type to Bool")

proc expectKind*(o: JlObj, k: JlObjKind) =
  ## Expect kind
  if o.kind != k:
    raise newException(NativeTypeError, "Got wrong kind")

# Inititalizers
proc newNativeStr*(s: string): JlObj = JlObj(kind: NativeStr, s: s)

proc newNativeBool*(b: bool): JlObj = JlObj(kind: NativeBool, b: b)

proc newNativeInt*(i: int): JlObj = JlObj(kind: NativeInt, i: i)

proc newNativeFloat*(f: float): JlObj = JlObj(kind: NativeFloat, f: f)

# Main visitor, creates bytecode
proc visit(n: JlNode, jlc: var seq[BC]) =
  case n.kind
  of StrLit:
    jlc.add(BC(kind: PUSH, value: newNativeStr(n.getStr)))
  of IntLit:
    jlc.add(BC(kind: PUSH, value: newNativeInt(n.getInt)))
  of FloatLit:
    jlc.add(BC(kind: PUSH, value: newNativeFloat(n.getFloat)))
  of BoolLit:
    jlc.add(BC(kind: PUSH, value: newNativeBool(n.getBool)))
  of VarDecl:
    n[1].visit(jlc)
    jlc.add(BC(kind: SET, name: n[0].getStr))   
  of Ident:
    jlc.add(BC(kind: GET, name: n.getStr))   
  of FuncStmt:
    # PUSH {FUNC OBJ} SET PUSH {ENDPOS} JUMP SET {ARGUMENTS} PUSH 0 RETURN
    let name = n[0].getStr
    let f = JlObj(kind: Func, name: name, address: jlc.len+3)
    jlc.add(BC(kind: PUSH, value: f))
    jlc.add(BC(kind: SET, name: f.name))
    var jumplink = BC(kind: PUSH)
    jlc.add(jumplink)
    jlc.add(newBcAction(JUMP))
    for i in countdown(n[1].len-1, 0):
      let arg = n[1][i]
      jlc.add(BC(kind: SET, name: arg.getStr))
    n[2].visit(jlc)
    jlc.add(BC(kind: PUSH, value: newNativeInt(0)))
    jlc.add(newBcAction(RETURN))    

    jumplink.value = newNativeInt(jlc.high)
    
  of CallExpr:
    # GET ENTERFUNC JUMP
    let name = n[0].getStr
    n[1].visit(jlc)
    jlc.add(BC(kind: GET, name: name))  
    jlc.add(BC(kind: ENTERFUNC, name: name))
    jlc.add(newBcAction(JUMP))
  of IfStmt:
    # {COND} IF {BODY} EXIT
    n[0].visit(jlc)
    var code = BC(kind: IF)
    jlc.add(code)
    n[1].visit(jlc)
    jlc.add(newBcAction(EXIT))
    code.amount = jlc.high

  of KwExpr:
    bcKw()
  of OpExpr:
    bcOp()
  else: 
    if n.kind in lsSet:
      for child in n:
        child.visit(jlc)

proc `$`*(s: seq[BC]): string =
  ## For debuggign
  for i, b in s:
    result.add $i & ": " & $(b[]) & "\n"

proc makeByteCode*(n: JlNode): seq[BC] =
  ## Wrapper proc
  var res = newSeq[BC]()
  n.visit(res)
  return res