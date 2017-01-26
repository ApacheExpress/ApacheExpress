//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import Darwin

// Basic Noze.io like stream protocols. But those in here are not
// asynchronous.
enum streams {
  
  // TBD: protocols cannot be nested?

}

typealias DoneCB = () -> Void

protocol StreamType {
}

protocol WritableStreamType : StreamType {
  func end()
}

protocol GWritableStreamType : class, WritableStreamType {
  
  associatedtype WriteType
  
  func writev(buckets b: [ [ WriteType ] ], done: DoneCB?) throws
}

protocol WritableByteStreamType : WritableStreamType {

  func writev(buckets chunks: [ [ UInt8 ] ], done: DoneCB?) throws
  
}


// MARK: - Simple Output Stream

class FileOutputStream : GWritableStreamType, WritableByteStreamType {
  
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
  
  func end() {
    guard canEnd else { return }
    fclose(handle)
    handle = nil
  }
  
  func flush() {
    guard handle != nil else { return }
    fflush(handle)
  }
  
  func writev(buckets: [ [ UInt8 ] ], done: DoneCB?) throws {
    guard !buckets.isEmpty        else { return }
    guard !buckets.first!.isEmpty else { return }
    guard handle != nil else { throw Error.Closed }
    
    for bucket in buckets {
      guard !bucket.isEmpty else { continue }
      
      try bucket.withUnsafeBufferPointer { bp in
        let rc = fwrite(bp.baseAddress, bp.count, 1, handle)
        guard rc == 1 else {
          if let cb = done { cb() }
          throw Error.WriteFailed
        }
      }
    }
    if let cb = done { cb() }
  }
  
}


// MARK: - Extensions

extension GWritableStreamType {
  
  func write(_ chunk: [ WriteType ], done: DoneCB? = nil) throws {
    try writev(buckets: [ chunk ], done: done )
  }
  
  func end(_ chunk: [ WriteType ]? = nil, doneWriting: DoneCB? = nil)
       throws
  {
    if let chunk = chunk {
      try writev(buckets: [ chunk ]) {
        if let cb = doneWriting { cb() }
        self.end() // only end after everything has been written
      }
    }
    else {
      if let cb = doneWriting { cb() } // nothing to write, immediately done
      end()
    }
  }
}

// MARK: - UTF8 support for UInt8 streams

/// Convenience - can write Strings to any Byte stream as UTF-8
extension GWritableStreamType where WriteType == UInt8 {
  // TODO: UTF8View should be a BucketType ...
  
  func write(_ chunk: String, done: DoneCB? = nil) throws {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    try writev(buckets: [ bucket ], done: done)
  }
  
  func end(_ chunk: String, doneWriting: DoneCB? = nil) throws {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    try writev(buckets: [ bucket ]) {
      if let cb = doneWriting { cb() }
      self.end()
    }
  }
}
