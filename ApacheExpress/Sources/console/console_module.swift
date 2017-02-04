//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

#if os(Linux)
  import var Glibc.stdout
  import var Glibc.stderr
#else
  import Darwin
#endif

public enum console {
  
  // FIXME: Obviously this should be hooked up to Apache logging. For this to
  //        work we would probably need thread-local storage to be able to
  //        direct the logs to a proper request logger.
  static var defaultConsole : ConsoleType =
               Console2(FileOutputStream(handle: stdout),
                        FileOutputStream(handle: stderr))
  
  // top level functions, so that you can do: console.info() ...
  // Note: yes, we could name `defaultConsole` 'console', but then stuff
  //       like console.module gets weird.

  public static func error(_ msg: @autoclosure () -> String, _ values : Any?...) {
    defaultConsole.primaryLog(.Error, msg, values)
  }
  public static func warn (_ msg: @autoclosure () -> String, _ values : Any?...) {
    defaultConsole.primaryLog(.Warn, msg, values)
  }
  public static func log  (_ msg: @autoclosure () -> String, _ values : Any?...) {
    defaultConsole.primaryLog(.Log, msg, values)
  }
  public static func info (_ msg: @autoclosure () -> String, _ values : Any?...) {
    defaultConsole.primaryLog(.Info, msg, values)
  }
  public static func trace(_ msg: @autoclosure () -> String, _ values : Any?...) {
    defaultConsole.primaryLog(.Trace, msg, values)
  }

  public static func dir(_ obj: Any?) {
    defaultConsole.dir(obj)
  }
}
