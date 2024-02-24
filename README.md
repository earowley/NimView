# NimView

A library to simplify WebUI bindings for Nim. This makes it simple to create a fast, lightweight application which uses a framework such as React on the frontend and Nim for backend logic.

# Features

* Complete Nim bindings to WebUI
* A powerful binding system powered by Nim macros
  * Bind (most) functions from a single call
  * Use async the same as you would in regular Nim code

# Example

An example pulled directly from the tests directory:

```nim
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
```

From within the application:

```jsx
const data = [1, 2, 3, 4, 5];
console.log(await accumulate(data));
```

# Restrictions

The webview ABI uses JSON strings as a medium of communication with
backend frameworks. NimView uses Nim's std/json package to parse and
create JSON strings. This means that you can bind any function whose
parameters and return types can be processed by std/json. This includes
most types, such as:

1. Ints
2. Floats
3. Strings
4. Arrays/Sequences of 1-3
5. Objects of 1-4

This also means that there can be significant overhead when calling a Nim function from the browser or returning from a Nim function to the browser.
