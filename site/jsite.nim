
import libjumplang/[ast, parser, interpreter, syms, bytecode]
include karax/prelude
import karax/[vstyles, kdom]
import jsffi except `&`


proc interpret(f: kstring): kstring =
  ## Interpretation core
  try:
    let a = parse($(f)) # Parse the code
    a.ensureSemantics() # Ensure the intergrity of the code
    let bytecode = a.makeByteCode() # Make byte code
    let res = bytecode.interpret("<Unnamed>") # Run as file <Unnamed>
    result.add output # Output is a var to collect what would be "echo"
    if res.failed:
       result.add res.msg # Catch interpreter errors
  except CatchableError as e: # Catch all other errors
     result.add e.msg & '\n'

var o: kstring = "Output here" # The reactive output section

# Codemirror
type CodeMirror = distinct Element
var myCodeMirror: CodeMirror # The current mirror

proc newCodeMirror(element: Element, config: js): CodeMirror {. importcpp: "CodeMirror(@)" .}
proc setValue(cm: CodeMirror, value: kstring) {.importcpp: "#.setValue(@)".}
proc getValue(cm: CodeMirror): kstring {.importcpp: "#.getValue()".}
proc isDarkMode(): bool {.importcpp: "isDarkMode()".}


# Codemirror rendering
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

# Virutal styles
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
  ## Example handler
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
      text "JumpLang Web Interpreter" # Title
    tdiv(style=boxStyle, id="input") # Codemirror
    pre(style=boxStyle): # Output
      code:
        text o
    tdiv(style=style(
      (StyleAttr.display, "flex".kstring),
      (StyleAttr.justifyContent, "space-between".kstring)
    )): # Run button bar
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
        (StyleAttr.display, "flex".kstring),
        (StyleAttr.alignItems, "center".kstring)
      )):
        bold(style=style(StyleAttr.marginRight, "20px")):
          text "Examples:"
        select(name="Examples", onchange=fillExample):
          for name in exampleOpts:
            option: text name
        
    

setRenderer createDom, "ROOT", postRender
setForeignNodeId "input"
