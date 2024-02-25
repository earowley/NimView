import std/os
import std/strformat
import nimview

const
  debugPort     = 5173
  pageUri       = fmt"http://localhost:{debugPort}"
  debugMode     = defined(debug) or not defined(release)
  staticFileDir = "dist"

proc accumulate(data: seq[int]): int =
  for i in data:
    result += i

proc main =
  let win = newWindow(debugMode)
  win.title = "Vite Tests"
  win.size = (800, 600)
  win.bind("accumulate", accumulate)
  when debugMode:
    win.navigate(pageUri)
    win.run()
  else:
    let staticFiles = getAppFilename().parentDir / staticFileDir
    win.runAppDir(staticFiles)

when isMainModule:
  main()
