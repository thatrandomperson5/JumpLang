import libjumplang/[parser, ast, syms, interpreter]

import std/terminal

type JlConfig = ref object
  checkSemantics: bool

proc printTrace(res: InterpreterResult): string =
  for item in res.stack:
    result.add "  In "
    case item.typ
    of Global:
      result.add item.name
    of Function:
      result.add "func " & item.name
    result.add ":\n"
  result.add "  " & res.msg

proc interpretFile(filename: string, conf: JlConfig) =
  let a = filename.parseFile
  echo a
  if conf.checkSemantics:
    a.ensureSemantics()
  let res = a.interpret(filename)
  if res.failed:
    styledEcho fgRed, "New Exception!\n", fgDefault, res.printTrace()

proc jumplang(checkSemantics=true, args: seq[string]) =
  let conf = JlConfig(checkSemantics: checkSemantics)
  for filename in args:
    interpretFile(filename, conf)


when isMainModule:
  import cligen
  dispatch jumplang
