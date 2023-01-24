# JumpLang
Just a test interpreter made in nim


# Use it!
When i post a release you can download the binary for your OS **OR** run the web interpreter [here](https://thatrandomperson5.github.io/JumpLang/)

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
## Funcs
```py
func name(arg1, arg2):
  # Stuff
```
```py
name(1, 2)
```
