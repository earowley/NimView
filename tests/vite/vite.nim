import std/strformat
import nimview

const
  port    = 5173
  pageUri = fmt"http://localhost:{port}"

proc accumulate(data: seq[int]): int =
  for i in data:
    result += i

proc main =
  let win = newWindow()
  win.title = "Vite Tests"
  win.size = (800, 600)
  win.bind("accumulate", accumulate)
  win.navigate(pageUri)
  win.run()

when isMainModule:
  main()
