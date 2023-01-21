
import libjumplang/[ast, interpreter, parser, syms]
include karax/prelude 

proc interpret(f: kstring): kstring =
   try:
     let a = parse($(f))
     a.ensureSemantics()
     let res = a.interpret("<Unnamed>")
     if res.failed:
       result.add res.msg
   except CatchableError as e:
     result.add e.msg

var o: kstring = ""

proc createDom(): VNode = 
  buildHtml(tdiv):
    textarea(width="100", placeholder="Code here", id="input")
    textarea(readonly="true", width="100", placeholder="Output", id="output"):
      text o
    button:
      text "Run"
      proc onclick(ev: Event; n: VNode) =
        o = "Working...\n"
        # let res = interpret(getVNodeById("input").text)
        # o.add res
        o.add "Finished"

setRenderer createDom

