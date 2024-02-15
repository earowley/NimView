import std/os
import futhark
import ./buildmeta

const
  webviewBase = bdir / "lib" / "webview"
  linkerFlags = case hostOS
  of "macosx":
    "-framework WebKit"
  else:
    ""

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
