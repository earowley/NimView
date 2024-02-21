# NimView

A library to simplify WebUI bindings for Nim. This makes it simple to create a fast, lightweight application which uses a framework such as React on the frontend and Nim for backend logic.

# Features

* Complete Nim bindings to WebUI
* A powerful macro binding system
 * Bind (most) functions from a single call
 * Use async the same as you would in Nim

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
