new EditorView({
  doc: 'console.log("hello")',
  extensions: [
    basicSetup,
    languageConf.of(javascript()),
    autoLanguage
  ],
  parent: document.querySelector("#input")
})