//
//  FileOutputStream.swift
//  ExExpress
//
//  Created by Helge Hess on 07/02/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

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
