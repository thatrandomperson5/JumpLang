
import libjumplang/[ast, parser, interpreter, syms]
include karax/prelude
import karax/[vstyles, kdom]
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
type CodeMirror = distinct Element
var myCodeMirror: CodeMirror

proc newCodeMirror(element: Element, config: js): CodeMirror {. importcpp: "CodeMirror(@)" .}
proc setValue(cm: CodeMirror, value: kstring) {.importcpp: "#.setValue(@)".}
proc getValue(cm: CodeMirror): kstring {.importcpp: "#.getValue()".}

proc postRender() =
  myCodeMirror = newCodeMirror(kdom.getElementById("input"), js{
    mode: "text/html".kstring,
    value: "".kstring,
    lineNumbers: true,
  })

let boxStyle = style(
  (StyleAttr.width, "100%".kstring),
  (StyleAttr.borderStyle, "solid".kstring),
  (StyleAttr.borderWidth, "1px".kstring),
  (StyleAttr.borderColor, "--highlight".kstring)
)

proc createDom(): VNode = 
  result = buildHtml(tdiv):
    tdiv(style=boxStyle, id="input")
    code:
      pre(style=boxStyle):
        text o
    button:
      text "Run"
      proc onclick(ev: Event; n: VNode) =
        o = "Working...\n"
        let code = myCodeMirror.getValue()
        let res = interpret(code)
        o.add res
        o.add "Finished"

setRenderer createDom, "ROOT", postRender

