
import libjumplang/[ast, parser, interpreter, syms]
include karax/[prelude, vstyles]


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

proc makeMirror(query: kstring) {.importcpp: "makeMirror(#)".}

proc postRender() =
  makeMirror("#input")

let boxStyle = style(
  (StyleAttr.width, "100%"),
  (StyleAttr.borderStyle, "solid"),
  (StyleAttr.borderWidth, "1px"),
  (StyleAttr.borderColor, "--highlight")
)

proc createDom(): VNode = 
  result = buildHtml(tdiv):
    tdiv(style=boxStyle, id="input")
    code(style=boxStyle):
      pre:
        text o
    button:
      text "Run"
      proc onclick(ev: Event; n: VNode) =
        o = "Working...\n"
        let code = getVNodeById("input").getInputText()
        let res = interpret(code)
        o.add res
        o.add "Finished"

setRenderer createDom, "ROOT", postRender

