# JumpLang
![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/thatrandomperson5/jumplang) ![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/thatrandomperson5/jumplang) ![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/thatrandomperson5/jumplang/rel.yml) ![GitHub Repo stars](https://img.shields.io/github/stars/thatrandomperson5/jumplang?style=social) ![GitHub last commit](https://img.shields.io/github/last-commit/thatrandomperson5/jumplang) ![GitHub commit activity](https://img.shields.io/github/commit-activity/m/thatrandomperson5/jumplang)

A example interpreter made in about 1165 lines of nim


# Use it!
Download the binary for your OS [here](https://github.com/thatrandomperson5/JumpLang/releases) **OR** run the web interpreter [here](https://thatrandomperson5.github.io/JumpLang/)

# CLI
```
jumplang <filename.jmp>
```
# Syntax
## Keywords
```py
echo "Hello world" # Echo
```
```py
flag h: # Jump to using jump keyword
  # Content
```
```py
jump h
```
```py
if true:
  # Stuff
```
## Lits
```py
echo -159 # Int
```
```py
echo true # bool
```
```py
echo "str" # Str
```
```py
echo 0.567 # float
```

## Funcs
```py
func name(arg1, arg2):
  # Stuff
```
```py
name(1, 2)
```
