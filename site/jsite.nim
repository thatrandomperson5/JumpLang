
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
proc isDarkMode(): bool {.importcpp: "isDarkMode()".}

proc postRender() =
  var theTheme = "default".kstring
  if isDarkMode():
    theTheme = "dracula".kstring
  echo "Theme: ", theTheme
  
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
  (StyleAttr.maxHeight, "50vh".kstring),
  (StyleAttr.overflow, "scroll".kstring)
)

proc fillExample(ev: Event, n: VNode) =
  var txt: kstring
  let sel = n.value
  const hw = staticRead("../tests/test.jmp").kstring
  const lp = staticRead("../tests/test2.jmp").kstring
  case $sel
  of "Hello World":
    txt = hw
  of "Loops":
    txt = lp
  else:
    txt = "".kstring
  myCodeMirror.setValue(txt)

proc createDom(): VNode = 
  let exampleOpts = ["None", "Hello World", "Loops"]
  result = buildHtml(tdiv):
    h1:
      text "JumpLang Web Interpreter"
    tdiv(style=boxStyle, id="input")
    pre(style=boxStyle):
      code:
        text o
    tdiv(style=style(StyleAttr.display, "flex")):
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
