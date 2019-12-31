import
  macros, strutils, sequtils, sugar

var bytes {.compileTime.}: seq[int]

proc `*`(c: string, n: int): string =
  newSeqWith(n, c).join("")

proc translate(): string =
  for i in 0..<(bytes.len div 3):
    result.add(chr(
      7 + 25*bytes[3*i] + 5*bytes[3*i+1] + bytes[3*i+2]))

proc action(n: int, code: NimNode): NimNode =
  bytes.add n

  proc f(n: NimNode) =
    if n.kind == nnkIdent:
      # XXX do NOT add mod here! This version (miraculously) works with utf8
      bytes.add( n.strVal.len-1 )
    for c in n.children:
      f(c)

  f(code)
  
  if bytes.len mod 3 == 0 and bytes.len >= 6:
    let str = translate()
    if {'\n'} == { str[str.len-1], str[str.len-2] }:
      bytes.setLen(0)
      return parseStmt(str)

  newStmtList()

proc vify*(strCode: string): string =
  var str = strCode
  var bytes: seq[int]
  doAssert str.find("\n\n") < 0, "No two consecutive new line characters"
  if str[str.len-1] == '\n':
    str &= "\n"
  else:
    str &= "\n\n"

  for c in str:
    var n = ord(c) - 7
    bytes.add n div 25
    if n div 25 > 4:
      echo c & " -> " & $n
    n = n mod 25
    bytes.add n div 5
    n = n mod 5
    bytes.add n

  var lineLen = 0
  for s in bytes.map(n => "v" * (n+1)):
    result &= s & " "
    lineLen += s.len + 1
    if lineLen >= 60:
      lineLen = 0
      result &= "\n"

macro generateDefinitions =
  result = newStmtList()

  for i in 1..10:
    let
      number = newIntLitNode(i-1)
      name = newIdentNode("v" * i)
    result.add quote do:
      macro `name`*(code: untyped):untyped {.discardable.} = action(`number`, code)

generateDefinitions

