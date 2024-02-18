import std/os
import std/macros
import std/json
import futhark
import ./buildmeta

const
  webviewBase = bdir / "lib" / "webview"
  linkerFlags = when hostOS == "macosx":
    "-framework WebKit"
  else:
    {.error: "Unsupported OS: " & hostOS.}

importc:
  path webviewBase
  "webview.h"

{.compile(webviewBase / "webview.cc", "-x c++ -std=c++11 -DWEBVIEW_STATIC").}
{.passL: linkerFlags.}

type
  WindowObj = object
    raw: webview_t
  Window* = ref WindowObj
  WindowError* = object of Defect

proc `=destroy`(self: WindowObj) =
  webview_destroy(self.raw)

proc `=copy`(dst: var WindowObj, src: WindowObj) {.error.}

proc newWindow*(debug: bool): Window =
  let raw = webview_create(debug.cint, nil)
  if raw == nil:
    raise newException(WindowError, "Error creating webview window")
  Window(raw: raw)

proc `title=`*(self: Window, title: string) =
  webview_set_title(self.raw, title)

proc `size=`*(self: Window, size: tuple[width, height: int]) =
  webview_set_size(
    self.raw,
    size.width.cint,
    size.height.cint,
    WEBVIEW_HINT_NONE
  )

proc navigate*(self: Window, url: string) =
  webview_navigate(self.raw, url.cstring)

proc run*(self: Window) =
  webview_run(self.raw)

template argsTupleImpl(val: NimNode): NimNode =
  val.expectKind(nnkSym)
  let tt = val.getTypeImpl()
  tt.expectKind(nnkProcTy)
  var params = newSeq[NimNode]()
  for param in tt[0]:
    if param.kind == nnkIdentDefs:
      params.add(param[1])
  let result = nnkTupleConstr.newNimNode()
  for param in params:
    result.add(param)
  result

macro callFromParsed(fun, parsed: typed): untyped =
  let argTypes = parseExpr(argsTupleImpl(fun).repr)
  var callParams = newSeq[NimNode]()
  let to = bindSym("to")
  let jnidx = bindSym("[]")
  for i in 0..<argTypes.len:
    let indexer = newCall(
      jnidx,
      parsed,
      newLit(i)
    )
    let toExpr = newCall(
      to,
      indexer,
      argTypes[i]
    )
    callParams.add(toExpr)
  result = newCall(fun, callParams)

template `bind`*(self: Window, jsName: string, callback: typed): untyped =
  proc glue(id, jsonArgs: cstring, cxt: webview_t) {.cdecl, global.} =
    let parsed = parseJson($jsonArgs)
    type ResultType = typeof(callFromParsed(callback, parsed))
    when ResultType is void:
      callFromParsed(callback, parsed)
    else:
      let callbackResult = $(%*(callFromParsed(callback, parsed)))
      webview_return(cxt, id, 0, callbackResult.cstring)
  webview_bind(self.raw, jsName.cstring, glue, self.raw)
