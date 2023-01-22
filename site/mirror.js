
function makeMirror(id) {
  new CodeMirror(document.querySelector(id), {
		mode: "text/html",
		theme: "neonsyntax",
    value: ""
  })
}