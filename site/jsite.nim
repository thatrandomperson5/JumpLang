
import libjumplang/[ast, parser, interpreter, syms, bytecode]
include karax/prelude
import karax/[vstyles, kdom]
import jsffi except `&`


proc interpret(f: kstring): kstring =
  try:
    let a = parse($(f))
    a.ensureSemantics()
    let bytecode = a.makeByteCode()
    let res = bytecode.interpret("<Unnamed>")
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
proc isDarkMode(): bool {.importcpp: "isDarkMode()".}

proc postRender() =
  var theTheme = "default".kstring
  if isDarkMode():
    theTheme = "dracula".kstring
  
  if myCodeMirror.Element == nil:
    myCodeMirror = newCodeMirror(kdom.getElementById("input"), js{
      mode: "python".kstring,
      value: "".kstring,
      lineNumbers: true,
      theme: theTheme
    })

let boxStyle = style(
  (StyleAttr.width, "100%".kstring),
  (StyleAttr.height, "100%".kstring),
  (StyleAttr.borderStyle, "solid".kstring),
  (StyleAttr.borderWidth, "1px".kstring),
  (StyleAttr.borderColor, "--highlight".kstring),
  (StyleAttr.maxHeight, "42vh".kstring),
  (StyleAttr.overflow, "scroll".kstring)
)

proc fillExample(ev: Event, n: VNode) =
  var txt: kstring
  let sel = n.value
  const hw = staticRead("../tests/test.jmp").kstring
  const lp = staticRead("../tests/test2.jmp").kstring
  const fc = staticRead("../tests/test3.jmp").kstring
  case $sel
  of "Hello World":
    txt = hw
  of "Loops":
    txt = lp
  of "Factorials":
    txt = fc
  else:
    txt = "".kstring
  myCodeMirror.setValue(txt)

proc createDom(): VNode = 
  let exampleOpts = ["None", "Hello World", "Loops", "Factorials"]
  result = buildHtml(tdiv):
    h1:
      text "JumpLang Web Interpreter"
    tdiv(style=boxStyle, id="input")
    pre(style=boxStyle):
      code:
        text o
    tdiv(style=style(
      (StyleAttr.display, "flex"),
      (StyleAttr.justifyContent, "space-between")
    )):
      button:
        text "Run"
        proc onclick(ev: Event; n: VNode) =
          o = "Working...\n"
          redraw()
          let code = myCodeMirror.getValue()
          if code != "".kstring:
            let res = interpret(code)
            o.add res
          o.add "Finished"
      tdiv(style=style(
        (StyleAttr.display, "flex"),
        (StyleAttr.alignItems, "center")
      )):
        b:
          text "Examples:&nbsp;&nbsp;"
        select(name="Examples", onchange=fillExample):
          for name in exampleOpts:
            option: text name
        
    

setRenderer createDom, "ROOT", postRender
setForeignNodeId "input"
