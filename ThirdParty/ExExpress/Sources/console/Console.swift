//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

public enum LogLevel : Int8 { // cannot nest types in generics
  case Error
  case Warn
  case Log
  case Info
  case Trace
  
  var logPrefix : String {
    switch self {
      case .Error: return "ERROR: "
      case .Warn:  return "WARN:  "
      case .Info:  return "INFO:  "
      case .Trace: return "Trace: "
      case .Log:   return ""
    }
  }
  var logPrefixAsBytes : [ UInt8 ] {
    switch self {
      case .Error: return errorBucket
      case .Warn:  return warnBucket
      case .Info:  return infoBucket
      case .Trace: return traceBucket
      case .Log:   return []
    }
  }
}

fileprivate let errorBucket = Array("ERROR: ".utf8)
fileprivate let warnBucket  = Array("WARN:  ".utf8)
fileprivate let infoBucket  = Array("INFO:  ".utf8)
fileprivate let traceBucket = Array("Trace: ".utf8)


/// Writes UTF-8 to any byte stream.
public protocol ConsoleType {
  
  var logLevel : LogLevel { get }
  
  func primaryLog(_ logLevel: LogLevel, _ msgfunc: () -> String,
                  _ values: [ Any? ] )
}

public extension ConsoleType { // Actual logging funcs
  
  public func error(_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Error, msg, values)
  }
  public func warn (_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Warn, msg, values)
  }
  public func log  (_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Log, msg, values)
  }
  public func info (_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Info, msg, values)
  }
  public func trace(_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Trace, msg, values)
  }
  
  public func dir(_ obj: Any?) {
    // TODO: implement more
    log("\(obj)")
  }
}

class ConsoleBase : ConsoleType {

  public var logLevel : LogLevel
  let stderrLogLevel  : LogLevel = .Error // directed to stderr, if available
  
  public init(_ logLevel: LogLevel = .Info) {
    self.logLevel = logLevel
  }

  public func primaryLog(_ logLevel: LogLevel,
                         _ msgfunc : () -> String,
                         _ values : [ Any? ] )
  {
  }
}

fileprivate
func writeValues<T: GWritableStreamType>(to t: T, _ values : [ Any? ]) throws
                 where T.WriteType == UInt8
{
  for v in values {
    try t.writev(buckets: spaceBrigade, done: nil)
    
    let bucket : [ UInt8 ] // arrgh
    if let v = v as? CustomStringConvertible {
      bucket = Array<UInt8>(v.description.utf8)
    }
    else if let v = v as? String {
      bucket = Array<UInt8>(v.utf8)
    }
    else {
      bucket = Array<UInt8>("\(v)".utf8)
    }
    try t.writev(buckets: [ bucket ], done: nil)
  }
}

// The implementation of this is a little less obvious due to all the
// generics ... we could hook it up to ReadableStream which might make it a
// little cleaner. But hey! ;-)

let eolBrigade   : [ [ UInt8 ] ] = [ [ 10 ] ]
let spaceBrigade : [ [ UInt8 ] ] = [ [ 32 ] ] // best name evar

class Console<OutStreamType: GWritableStreamType> : ConsoleBase
                     where OutStreamType.WriteType == UInt8
{
  
  let stdout : OutStreamType
  
  // Note: An stderr optional doesn't fly because the type of Console
  //       can't be derived w/o giving a type.
  public init(_ stdout: OutStreamType, logLevel: LogLevel = .Info) {
    self.stdout   = stdout
    super.init(logLevel)
  }
  
  public override func primaryLog(_ logLevel : LogLevel,
                                  _ msgfunc  : () -> String,
                                  _ values   : [ Any? ] )
  {
    // Note: We just write and write and write, not waiting for the stream
    //       to actually drain the buffer.
    // TBD:  We could make this threadsafe by dispatching the write to core.Q.
    //       Not sure it's worth it.
    guard logLevel.rawValue <= self.logLevel.rawValue else { return }
    
    let s = msgfunc()
    try! stdout.write(logLevel.logPrefixAsBytes)
    try! stdout.write(Array(s.utf8)) // ouch
    try! writeValues(to: stdout, values)
    try! stdout.writev(buckets: eolBrigade, done: nil)
  }
}

// Unfortunately we can't name this 'Console' as I hoped. Swift complains about
// invalid redeclaration..
class Console2<OutStreamType: GWritableStreamType,
               ErrStreamType: GWritableStreamType>
             : ConsoleBase
             where OutStreamType.WriteType == UInt8,
                   ErrStreamType.WriteType == UInt8
{
  
  let stdout : OutStreamType
  let stderr : ErrStreamType
  
  // Note: An stderr optional doesn't fly because the type of Console
  //       can't be derived w/o giving a type.
  public init(_ stdout: OutStreamType, _ stderr: ErrStreamType,
              logLevel: LogLevel = .Info)
  {
    self.stdout   = stdout
    self.stderr   = stderr
    super.init(logLevel)
  }
  
  public override func primaryLog(_ logLevel : LogLevel,
                                  _ msgfunc  : () -> String,
                                  _ values   : [ Any? ] )
  {
    // Note: We just write and write and write, not waiting for the stream
    //       to actually drain the buffer.
    // TBD:  We could make this threadsafe by dispatching the write to core.Q.
    //       Not sure it's worth it.
    guard logLevel.rawValue <= self.logLevel.rawValue else { return }
    
    let s = msgfunc()
    
    if logLevel.rawValue <= stderrLogLevel.rawValue {
      try! stderr.write(logLevel.logPrefixAsBytes)
      try! stdout.write(Array(s.utf8)) // ouch
      try! writeValues(to: stdout, values)
      try! stderr.writev(buckets: eolBrigade, done: nil)
    }
    else {
      try! stdout.write(logLevel.logPrefixAsBytes)
      try! stdout.write(Array(s.utf8)) // ouch
      try! writeValues(to: stdout, values)
      try! stdout.writev(buckets: eolBrigade, done: nil)
    }
  }
}
