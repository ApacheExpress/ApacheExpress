//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import Darwin
import class Foundation.ProcessInfo

public enum process {

  public static var pid : Int { return Int(getpid()) }

  #if os(Linux)
    public static let platform = "linux"
  #else
    public static let platform = "darwin"
  #endif
  
  #if os(Linux)
    public static let isRunningInXCode = false
  #else
    public static var isRunningInXCode : Bool = {
      // TBD: is there a better way?
      let s = getenv("XPC_SERVICE_NAME")
      if s == nil { return false }
      return strstr(s, "Xcode") != nil
    }()
  #endif

  
  // MARK: - FS
  
  enum Error : Swift.Error {
    case CouldNotChangedWorkingDirectory
  }

  public static func chdir(path: String) throws {
    let rc = Darwin.chdir(path)
    guard rc == 0 else { throw Error.CouldNotChangedWorkingDirectory }
  }
  
  public static func cwd() -> String {
    let rc = Darwin.getcwd(nil /* malloc */, 0)
    assert(rc != nil, "process has no cwd??")
    defer { free(rc) }
    guard rc != nil else { return "" }
    
    let s = String(validatingUTF8: rc!)
    assert(s != nil, "could not convert cwd to String?!")
    return s!
  }

  public static let argv = CommandLine.arguments
  
  public static var env : [ String : String ] {
    return ProcessInfo.processInfo.environment
  }
}
