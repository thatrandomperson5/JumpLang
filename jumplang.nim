import libjumplang/[parser, syms, bytecode, interpreter]

import std/terminal

## The cli for jumplang, for the core look at ./libjumplang

type JlConfig = ref object 
  ## A config type for cli args
  checkSemantics: bool


proc printTrace(res: InterpreterResult): string =
  ## Basic trace construction for interpreter results
  for item in res.stack:
    result.add "In "
    case item.typ
    of Global:
      result.add item.name
    of Function:
      result.add "func " & item.name
    of Block:
      result.add item.name
    result.add ":\n"
  result.add res.msg


proc interpretFile(filename: string, conf: JlConfig) =
  ## Interpret a file given a filename

  let a = filename.parseFile # Parse the file
  # echo a
  if conf.checkSemantics: # Check semantics
    a.ensureSemantics()
  let bytecode = a.makeByteCode()
  when defined(jlDebugIt):
    echo bytecode
  let res = bytecode.interpret(filename)
  if res.failed:
    styledEcho fgRed, "New Exception!\n", fgDefault, res.printTrace() # Prin the trace on error

proc jumplang(checkSemantics=true, args: seq[string]) = 
  ## Convert cligen arguments to the JlConfig
  let conf = JlConfig(checkSemantics: checkSemantics)
  for filename in args:
    interpretFile(filename, conf)


when isMainModule: # Dispatch
  import cligen
  dispatch jumplang
