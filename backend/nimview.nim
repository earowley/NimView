import std/strformat
import webview

const
  port    = 5173
  pageUri = fmt"http://localhost:{port}"

proc main =
  let win = newWindow(true)
  win.title = "Nimview App!"
  win.size = (800, 600)
  win.navigate(pageUri)
  win.run()

when isMainModule:
  main()
