# Package

version     = "0.1.0"
author      = "thatrandomperson5"
description = "A interpreter made in nim"
license     = "MIT"
bin = @["jumplang"]

# Deps

requires "nim >= 0.10.0"
requires "npeg >= 1.2.0"
requires "cligen >= 1.5.37"
requires "https://github.com/thatrandomperson5/npeg-utils"

task test, "Test the interpreter.":
  exec "nimble install --depsOnly"
  exec "nim c jumplang.nim"
  exec "./jumplang tests/test.jmp"
  exec "./jumplang tests/test2.jmp"
  exec "./jumplang tests/test3.jmp"

task site, "Make the website.":
  exec "nimble install --depsOnly -y"
  exec "nim js -d:release --opt:speed -o:site/app.js site/jsite"
  exec "cd site && sh closure.sh"
