
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

var o: kstring = "Output here"
type CodeMirror = distinct Element
var myCodeMirror: CodeMirror

proc newCodeMirror(element: Element, config: js): CodeMirror {. importcpp: "CodeMirror(@)" .}
proc setValue(cm: CodeMirror, value: kstring) {.importcpp: "#.setValue(@)".}
proc getValue(cm: CodeMirror): kstring {.importcpp: "#.getValue()".}

proc postRender() =
  if myCodeMirror.Element == nil:
    myCodeMirror = newCodeMirror(kdom.getElementById("input"), js{
      mode: "text/python".kstring,
      value: "".kstring,
      lineNumbers: true,
    })

let boxStyle = style(
  (StyleAttr.width, "100%".kstring),
  (StyleAttr.height, "100%".kstring),
  (StyleAttr.borderStyle, "solid".kstring),
  (StyleAttr.borderWidth, "1px".kstring),
  (StyleAttr.borderColor, "--highlight".kstring)
)

proc fillExample(ev: Event, n: VNode) =
  var txt: kstring
  let sel = n.value
  case $sel
  of "Hello World":
    txt = staticRead("../tests/test.jmp").kstring
  of "Loops":
    txt = staticRead("../tests/test2.jmp").kstring
  else:
    txt = "".kstring
  myCodeMirror.setValue(txt)

proc createDom(): VNode = 
  let exampleOpts = ["Hello World", "Loops"]
  result = buildHtml(tdiv):
    tdiv(style=boxStyle, id="input")
    pre(style=boxStyle):
      code:
        text o
    button:
      text "Run"
      proc onclick(ev: Event; n: VNode) =
        o = "Working...\n"
        let code = myCodeMirror.getValue()
        if code != "".kstring:
          let res = interpret(code)
          o.add res
          o.add "Finished"
    select(name="Examples", onchange=fillExample):
      for name in exampleOpts:
        option: text name
        
    

setRenderer createDom, "ROOT", postRender
setForeignNodeId "input"
