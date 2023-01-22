
function makeMirror(id) {
  new EditorView({
    doc: 'console.log("hello")',
    extensions: [
      basicSetup,
    ],
    parent: document.querySelector(id)
  })
}