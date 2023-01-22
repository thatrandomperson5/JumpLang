
import libjumplang/[ast, parser, interpreter, syms]
include karax/[prelude, vstyles]
import jsffi except `&`


proc interpret(f: kstring): kstring =
  try:
    let a = parse($(f))
    a.ensureSemantics()
    let res = a.interpret("<Unnamed>")
    result.add output
    if res.failed:
       result.add res.msg
  except CatchableError as e:
     result.add e.msg & '\n'

var o: kstring = ""

proc makeMirror(query: kstring = "#input") {.importcpp: "makeMirror(#)".}

proc createDom(): VNode = 
  result = buildHtml(tdiv):
    tdiv(style=style(StyleAttr.width, "100%"), id="input")
    textarea(readonly="true", width="100", placeholder="Output", id="output"):
      text o
    button:
      text "Run"
      proc onclick(ev: Event; n: VNode) =
        o = "Working...\n"
        let code = getVNodeById("input").getInputText()
        let res = interpret(code)
        o.add res
        o.add "Finished"
  makeMirror() 

setRenderer createDom

