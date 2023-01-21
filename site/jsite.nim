# import libjumplang/[ast, interpreter, parser, syms]
include karax/prelude 

# proc interpret(f: kstring): kstring =
#   try:
#     let a = parse($(f))
#     a.ensureSemantics()
#     let res = a.interpret("<Unnamed>")
#     if res.failed:
#       result.add res.msg
#   except CatchableError as e:
#     result.add e.msg

proc createDom(): VNode = 
  buildHtml(tdiv):
    textarea(width="100", placeholder="Code here", id="input")
    textarea(readonly="true", width="100", placeholder="Output", id="output")
    button:
      text "Run"
      proc onclick(ev: Event; n: VNode) =
        getVNodeById("output").text = "Working...\n"
        # let res = interpret(getVNodeById("input").text)
        # getVNodeById("output").add text res
        getVNodeById("output").add text "Finished"

setRenderer createDom