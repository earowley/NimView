import std/os
import std/macros
import std/json
import std/asyncdispatch
import futhark
import ./private/buildmeta

const
  debugMode = defined(debug) or not defined(release)
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
  DispatchProc* = proc (cxt: webview_t, arg: pointer): void {.cdecl.}
  AutoAsyncCallback = proc(
    cxt: webview_t,
    id, json: string
  ): Future[void] {.async, gcsafe.}
  DispatchElement = object
    cxt: webview_t
    id, json: string
    acallback: AutoAsyncCallback

var dispatchThread: Thread[void]
var dispatchChan: Channel[DispatchElement]

proc dispatcherLoop {.thread.} =
  dispatchChan.open()
  while true:
    let elem = dispatchChan.recv()
    discard elem.acallback(elem.cxt, elem.id, elem.json)
    while hasPendingOperations():
      poll(0)
      let work = dispatchChan.tryRecv()
      if not work.dataAvailable:
        continue
      let msg = work.msg
      discard work.msg.acallback(msg.cxt, msg.id, msg.json)

createThread(dispatchThread, dispatcherLoop)

proc `=destroy`(self: WindowObj) =
  webview_destroy(self.raw)

proc `=copy`(dst: var WindowObj, src: WindowObj) {.error.}

proc newWindow*(debug: bool = debugMode): Window =
  let raw = webview_create(debug.cint, nil)
  if raw == nil:
    raise newException(WindowError, "Error creating webview window")
  Window(raw: raw)

proc `title=`*(self: Window, title: string) =
  webview_set_title(self.raw, title.cstring)

proc `size=`*(self: Window, size: tuple[width, height: int]) =
  webview_set_size(
    self.raw,
    size.width.cint,
    size.height.cint,
    WEBVIEW_HINT_NONE
  )

proc `html=`*(self: Window, content: string) =
  webview_set_html(self.raw, content.cstring)

proc navigate*(self: Window, url: string) =
  webview_navigate(self.raw, url.cstring)

proc run*(self: Window) =
  webview_run(self.raw)

proc terminate*(self: Window) =
  webview_terminate(self.raw)

proc eval*(self: Window, js: string) =
  webview_eval(self.raw, js.cstring)

proc dispatch*(self: Window, arg: pointer, p: DispatchProc) =
  webview_dispatch(self.raw, p, arg)

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
  proc glue(idRaw, jsonRaw: cstring, cxt: webview_t) {.cdecl.} =
    let parsed = parseJson($jsonRaw)
    const isAsync = compiles(waitFor callFromParsed(callback, parsed))
    when isAsync:
      type ResultType = typeof(waitFor callFromParsed(callback, parsed))
    else:
      type ResultType = typeof(callFromParsed(callback, parsed))
    when isAsync:
      proc asyncCallback(
        cxt: webview_t,
        id, json: string
      ) : Future[void] {.async, gcsafe.} =
        let parsed = parseJson(json)
        when ResultType is void:
          await callFromParsed(callback, parsed)
          webview_return(cxt, id.cstring, 0, "")
        else:
          let callbackResult = $(%*(await callFromParsed(
            callback,
            parsed
          )))
          webview_return(cxt, id.cstring, 0, callbackResult.cstring)
      let elem = DispatchElement(
        cxt: cxt,
        id: $idRaw,
        json: $jsonRaw,
        acallback: asyncCallback
      )
      dispatchChan.send(elem)
    elif ResultType is void:
      callFromParsed(callback, parsed)
      webview_return(cxt, idRaw, 0, "")
    else:
      let callbackResult = $(%*(callFromParsed(callback, parsed)))
      webview_return(cxt, idRaw, 0, callbackResult.cstring)
  webview_bind(self.raw, jsName.cstring, glue, self.raw)
