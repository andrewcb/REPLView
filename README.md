# REPLView

A Cocoa interface element which implements the interface for a Read-Eval-Print Loop (REPL).

![Animated screenshot of the example application](https://user-images.githubusercontent.com/414905/45753990-4f42a100-bc12-11e8-943f-cd0cbcb02d6e.gif)


## Overview

*REPLView* is a Cocoa View for macOS which presents a scrolling text window with an editable input line at the bottom. The user can type text into the input line; when they press Enter, the text is passed to a provided *evaluator* function, which executes, evaluates or otherwise processes it, potentially producing output and/or error messages, which are then appended to the scrolling text window.

*REPLView* has the following features:

* Colour-coded output, with distinct colours for output, errors, echoed user input and previous sessions' restored output
* User input echoing may be configured with customisable formatting or disabled altogether
* Multi-line input history, which can be navigated with the up/down arrow keys
* Output may be *synchronous* (returned by the evaluator function) and/or *asynchronous* (written to the REPL window at any time)

## Using REPLView

The `REPLView` code is entirely contained in the source file `REPLView.swift`. `REPLView` is a subclass of `NSView`, and can be inserted into an app's view hierarchy either in a Storyboard/NIB, or programmatically. A REPLView instance has the following instance variables which may be set:

* `evaluator` — a function (closure) which is used to evaluate the text the user submits; code using REPLView should provide this, setting REPLView's `evaluator` variable to it. This function is to take one argument: a `String` containing the line submitted (without the trailing newline character); it returns an Optional value which, if present, is a `REPLView.EvalResponse` type, representing a result. This may be either `.output(String)`, representing a line of ordinary output, or `.error(String)`, representing an error message. If it is `nil`, the evaluator function does not return anything to display.
* `backgroundColor` — a `NSColor` value containing the colour of the REPL window background
* `outputColor` — a `NSColor` value containing the colour of ordinary output text displayed, as well as the user's input
* `errorColor` — a `NSColor` value containing the colour of error text displayed
* `echoColor` — a `NSColor` value containing the colour that the user's input is displayed in if it is echoed to the scrolling window
* `echoFormatter` — a function which, given a line the user just entered, returns an optional line to append to the scrolling window; the default implementation provided returns the input line prefixed with `">>> "`. To disable echoing, replace `echoFormatter` with a function that returns `nil`, i.e., `{ _ in nil }`.
* `maxHistoryLines` — the maximum number of lines of history to keep internally.

To print a line of (ordinary, non error) output to the REPLView's window, call its `printOutputLn(:)` method, i.e.,
```
myRepl.printOutputLn("Hello world")
```

To print an error message, use the `printErrorLn(:)` method in the same way. (Alternatively, you can use the `println(response:)` method, passing a `REPLView.EvalResponse` value, if that is more convenient.)

## Example code

The provided `REPLViewExample` project builds a basic example application, which reads integers on the REPL's input and prints their hexadecimal representations (or error messages if non-integer inputs are given). This demonstrates the basic operation of `REPLView`. Note that in this example, the REPL's colour scheme is defined in the Storyboard.

## Compatibility

REPLView is written in Swift 4. Due to its use of Swift's type system, it probably won't ever be compatible with Objective C, but if you're writing new code in Objective C, you should probably ask yourself why.

## Authors

 * **Andrew Bulhak** - [GitHub](https://github.com/andrewcb/)/[Technical blog](http://tech.null.org/)

## License

`REPLView` is licensed under the MIT License.
