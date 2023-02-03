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
  of "flag":
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
  of "flag":
    let i = n[1][0].getStr()
    raiseSemanticError(not s.inScope(i), i, 1)
    s[i] = Symbol(name: i, kind: FlagSym)
  else:
    raise newException(SemanticError, "Undeclared Keyword " & i)

template bcKw*(): untyped =
  let i = n[0].getStr()
  case i:
  of "echo":
    for child in n[1]:
      child.visit(jlc)
    jlc.add(BC(kind: ECHO, amount: n[1].len))
  of "jump":
    n[1].visit(jlc)
    jlc.add(newBcAction(JUMP))
  of "flag":
    jlc.add(BC(kind: PUSH, value: newNativeInt(jlc.len+1)))
    jlc.add(BC(kind: SET, name: n[1][0].getStr()))
  else:
    discard

template bcOp*(): untyped = 
  n[0].visit(jlc)
  n[2].visit(jlc)
  case n[1].getStr
  of "+":
    jlc.add newBCAction(ADDOP)
  of "-":
    jlc.add newBCAction(SUBOP)
  of "*":
    jlc.add newBCAction(MULTOP)
  of "/":
    jlc.add newBCAction(DIVOP)
  of ">=":
    jlc.add newBCAction(GTEOP)
  of "<=":
    jlc.add newBCAction(LTEOP)
  of ">":
    jlc.add newBCAction(GTOP)
  of "<":
    jlc.add newBCAction(LTOP)
  of "==":
    jlc.add newBCAction(EQOP)
  else:
    discard

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
    for arg in n[1]:
      s.add i.visit(arg).ensureStr & " "
    when defined(js):
      output.add s & '\n'
    else:
      echo s
  of "jump":
    let ident = n[1][0].getStr
    let f = i[ident]
    f.expectKind(FlagBlock)
    discard i.visit(f.internal)
  else:
    discard