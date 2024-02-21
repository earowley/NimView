import std/strformat
import nimview

const
  port    = 5173
  pageUri = fmt"http://localhost:{port}"

proc addFromNim(a, b: int): int = a + b

proc main =
  let win = newWindow()
  win.title = "Basic Nim callback"
  win.size = (800, 600)
  win.bind("addFromNim", addFromNim)
  win.navigate(pageUri)
  win.run()

when isMainModule:
  main()
