
function makeMirror(id) {
  new CodeMirror(document.querySelector(id), {
    doc: 'console.log("hello")',
  })
}