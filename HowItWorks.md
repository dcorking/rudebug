# Infrastructure #

rudebug defines some infrastructure methods for itself and the user to use (like `$rudebug.selected`). It stuffs all of them into a Module accessible via the `$rudebug` global to avoid collisions with the debugged code.

# Source code viewer #

Uses `File.read()` to read the files on the debugging server. Syntax highlighting uses [rsyntax](http://syntax.rubyforge.org/) with a custom convertor for highlighting to a GTK text buffer.

# Object browser #

  * The root of the object browser always is a Binding.
  * Every node has children like instance variables, self for bindings, methods for classes and modules and so on.
  * Children are lazily loaded when their parent node is expanded so huge object graphs are no problem.
  * Object graph cycles (`obj.child.eql?(obj)`) are detected. Cyclic nodes are not allowed to be expanded.
  * The variable `$rudebug.selected` is updated on the server whenever the selection is changed.

# Code shell #

  * All code is executed in a single session so you can access variables across multiple lines of code.
  * Exceptions are rescued and displayed to the user.
  * `$rudebug.selected` can be used to refer to the object selected in the object browser.
  * Unlike IRB there is no support for spreading `if`, `def` or similar statements over multiple lines.

# Backends #
Implementing a new debugging backend is fairly easy. This section ought to explain everything, but if in doubt have a look at the included backends. They are derived from `Connection::Base`. They need to support the following instance methods:
  * `stepping_support?()`: Return true if this back end supports stepping.
  * `connect(server)`: `server` is the connection target string from the user. Should do `on_disconnect.call(); disconnect()` in case of unexpected disconnect. Should do `Connection::Base.load_rudebug_code(session)`. Does `on_session.call(session)` whenever a new breakpoint is executed. (Multiple concurrent breakpoints are possible.)
  * `disconnect()`: Disconnect from server.

Sessions objects don't need to be derived from anything. They need to support the following methods:
  * `eval(code)`: Evaluate code. Do `raise(Connection::RemoteException, error_str)` in case of a remote exception.  Else return `inspect` representation of code result.
  * `current_file()`: Return file name of current context.
  * `current_line()`: Return line number of current context.
  * `source_code(file)`: Remotely read file and return result.
  * `continue()`: Continue running code on server.
  * `step_over()`: Halt after executing the next line of code on server. Don't step into methods. Does nothing if `stepping_support?()` returns false.
  * `step_into()`: Halt after executing the next line of code on server. Step into methods. Does nothing if `stepping_support?()` returns false.