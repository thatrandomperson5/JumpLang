
import ast, keywords
import std/[strutils]

type

  NativeTypeError* = object of ValueError
  JlObjKind* = enum NativeInt, NativeStr, NativeBool, Func, FlagBlock
  JlObj* = ref object
    case kind: JlObjKind
    of NativeInt:
      i: int
    of NativeStr:
      s: string
    of NativeBool:
      b: bool
    of Func:
      name: string
      address: int
    of FlagBlock:
      flag: string

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
  case obj.kind
  of NativeInt:
    return obj.i
  of Func:
    return obj.address
  else:
    raise newException(NativeTypeError, "Non-adressable object")


proc ensureStr*(obj: JlObj): string =
  case obj.kind
  of NativeInt:
    return $(obj.i)
  of NativeStr:
    return $(obj.s)
  of NativeBool:
    return $(obj.b)
  else:
    raise newException(NativeTypeError, "Cannot convert type to String")

proc ensureInt*(obj: JlObj): int =
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

proc ensureBool*(obj: JlObj): bool =
  case obj.kind
  of NativeInt:
    return obj.i > 0
  of NativeStr:
    return obj.s.len > 0
  of NativeBool:
    return obj.b
  else:
    raise newException(NativeTypeError, "Cannot convert type to Bool")

proc expectKind*(o: JlObj, k: JlObjKind) =
  if o.kind != k:
    raise newException(NativeTypeError, "Got wrong kind")

proc newNativeStr*(s: string): JlObj = JlObj(kind: NativeStr, s: s)

proc newNativeBool*(b: bool): JlObj = JlObj(kind: NativeBool, b: b)

proc newNativeInt*(i: int): JlObj = JlObj(kind: NativeInt, i: i)




proc visit(n: JlNode, jlc: var seq[BC]) =
  case n.kind
  of StrLit:
    jlc.add(BC(kind: PUSH, value: newNativeStr(n.getStr)))
  of IntLit:
    jlc.add(BC(kind: PUSH, value: newNativeInt(n.getInt)))
  of BoolLit:
    jlc.add(BC(kind: PUSH, value: newNativeBool(n.getBool)))
  of VarDecl:
    n[1].visit(jlc)
    jlc.add(BC(kind: SET, name: n[0].getStr))   
  of Ident:
    jlc.add(BC(kind: GET, name: n.getStr))   
  of FuncStmt:
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
    jlc.add(newBcAction(RETURN))
    jlc.add(newBcAction(EXIT))
    
    jumplink.value = newNativeInt(jlc.high)
    
  of CallExpr:
    let name = n[0].getStr
    n[1].visit(jlc)
    jlc.add(BC(kind: GET, name: name))  
    jlc.add(BC(kind: ENTERFUNC, name: name))
    jlc.add(newBcAction(JUMP))
  of IfStmt:
    n[0].visit(jlc)
    var code = BC(kind: IF)
    jlc.add(code)
    n[1].visit(jlc)
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
  for i, b in s:
    result.add $i & ": " & $(b[]) & "\n"

proc makeByteCode*(n: JlNode): seq[BC] =
  var res = newSeq[BC]()
  n.visit(res)
  return res