//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

// Basic Noze.io like stream protocols. But those in here are not
// asynchronous.
public enum streams {
  
  // TBD: protocols cannot be nested?

}

public typealias DoneCB = () throws -> Void

public protocol StreamType {
}

public protocol WritableStreamType : StreamType {
  func end() throws
}

public protocol GWritableStreamType : class, WritableStreamType {
  
  associatedtype WriteType
  
  func writev(buckets b: [ [ WriteType ] ], done: DoneCB?) throws
}

public protocol WritableByteStreamType : WritableStreamType {

  func writev(buckets chunks: [ [ UInt8 ] ], done: DoneCB?) throws
  
}


// MARK: - Simple Output Stream

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

public class FileOutputStream : GWritableStreamType, WritableByteStreamType {
  
  enum Error : Swift.Error {
    case WriteFailed
    case Closed
  }
  
  var handle : UnsafeMutablePointer<FILE>!
  
  init(handle: UnsafeMutablePointer<FILE>!) {
    self.handle = handle
  }
  
  var canEnd : Bool {
    // TODO: not quite right, but works for us now ;->
    return !(handle == stdin || handle == stdout || handle == stderr)
  }
  
  public func end() throws {
    guard canEnd else { return }
    fclose(handle)
    handle = nil
  }
  
  func flush() {
    guard handle != nil else { return }
    fflush(handle)
  }
  
  public func writev(buckets: [ [ UInt8 ] ], done: DoneCB?) throws {
    guard !buckets.isEmpty        else { return }
    guard !buckets.first!.isEmpty else { return }
    guard handle != nil else { throw Error.Closed }
    
    for bucket in buckets {
      guard !bucket.isEmpty else { continue }
      
      try bucket.withUnsafeBufferPointer { bp in
        let rc = fwrite(bp.baseAddress, bp.count, 1, handle)
        guard rc == 1 else {
          if let cb = done { try cb() }
          throw Error.WriteFailed
        }
      }
    }
    if let cb = done { try cb() }
  }
  
}


// MARK: - Extensions

public extension GWritableStreamType {
  
  public func write(_ chunk: [ WriteType ], done: DoneCB? = nil) throws {
    try writev(buckets: [ chunk ], done: done )
  }
  
  public func end(_ chunk: [ WriteType ]? = nil, doneWriting: DoneCB? = nil)
              throws
  {
    if let chunk = chunk {
      try writev(buckets: [ chunk ]) {
        if let cb = doneWriting { try cb() }
        try self.end() // only end after everything has been written
      }
    }
    else {
      if let cb = doneWriting { try cb() } // nothing to write, immediately done
      try end()
    }
  }
}

// MARK: - UTF8 support for UInt8 streams

/// Convenience - can write Strings to any Byte stream as UTF-8
public extension GWritableStreamType where WriteType == UInt8 {
  // TODO: UTF8View should be a BucketType ...
  
  public func write(_ chunk: String, done: DoneCB? = nil) throws {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    try writev(buckets: [ bucket ], done: done)
  }
  
  public func end(_ chunk: String, doneWriting: DoneCB? = nil) throws {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    try writev(buckets: [ bucket ]) {
      if let cb = doneWriting { try cb() }
      try self.end()
    }
  }
}
