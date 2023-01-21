template astHandleKeywords*(): untyped =
  child.expectLen(2)
  child[0].expectKind(Ident)
  child[1].expectKind(ArgList)
  let sub = child[1]
  case child[0].getStr:
  of "echo":
    discard
  of "jump":
    sub.expectLen(1)
    sub[0].expectKind(Ident)
  else:
   discard



template symHandleKeywords*(): untyped =
  let i = n[0].getStr()
  case i:
  of "echo":
    walkSyms(n[1], s)
  of "jump":
    definedIdent(s, getStr(n[1][0]), true).raiseSemanticError(getStr(n[1][0]), 0)
  else:
    raise newException(SemanticError, "Undeclared Keyword " & i)

template visitOp*(): untyped = 
  let a = i.visit(n[0])
  let b = i.visit(n[2])
  case n[1].getStr
  of "+":
    return newNativeInt(a.i + b.i)
  of "-":
    return newNativeInt(a.i - b.i)
  of "*":
    return newNativeInt(a.i * b.i)
  of "/":
    return newNativeInt((a.i / b.i).int)
  of ">=":
    return newNativeBool(a.i >= b.i)
  of "<=":
    return newNativeBool(a.i <= b.i)
  of ">":
    return newNativeBool(a.i > b.i)
  of "<":
    return newNativeBool(a.i < b.i)
  of "==":
    return newNativeBool(a.b == b.b)
  else:
    discard

template visitKw*(): untyped = 
  case n[0].getStr:
  of "echo":
    var s = ""
    for arg in n[0]:
      s.add i.visit(arg).s & " "
    when defined(js):
      output.add s & '\n'
    else:
      echo s
  of "jump":
    let ident = n[0].getStr
    let f = i[ident]
    f.expectKind(FlagBlock)
    discard i.visit(f.internal)
  else:
    discard