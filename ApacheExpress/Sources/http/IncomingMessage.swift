//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import ZzApache
import Apache2

public class IncomingMessage : MessageBase, CustomStringConvertible {

  public var httpVersion : String {
    guard let h = apacheRequest.typedHandle else { return "" }
    return h.pointee.oProtocol
  }
  
  public var method : String {
    set {
      guard let h = apacheRequest.typedHandle else { return }
      
      let mnum = ap_method_number_of(newValue)
      // TODO: check return value
      
      // Not sure this is really OK
      h.pointee.method_number = mnum
      h.pointee.method = UnsafePointer(apr_pstrdup(h.pointee.pool, newValue))
    }
    get {
      guard let h = apacheRequest.typedHandle else { return "" }
      return h.pointee.oMethod
    }
  }
  
  public var url : String {
    guard let th = apacheRequest.typedHandle else { return "" }
    return th.pointee.oURI
  }

  // MARK: - Headers
  
  final override var _headersTable : OpaquePointer? {
    guard let th = apacheRequest.typedHandle else { return nil }
    return th.pointee.headers_in
  }
  
  // MARK: - CustomStringConvertible
  
  public var description : String {
    var s = "<Request"
    if let h = apacheRequest.handle {
      s += "[\(h)]: "
    }
    else { s += "[gone]: " }
    s += "\(method) \(url)"
    s += ">"
    return s
  }
}

public extension IncomingMessage {
  
  public func readBody(bufsize: Int = 4096) throws -> [ UInt8 ] {
    guard let th = apacheRequest.typedHandle
     else { throw Error.ApacheHandleGone }
    
    let rc = ap_setup_client_block(th, REQUEST_CHUNKED_ERROR)
    guard rc == 0 else { throw Error.ReadFailed }
    
    guard ap_should_client_block(th) != 0 else { throw Error.ApacheHandleGone }
    
    var bytes   = [ UInt8 ]()
    // If there is a content-length, reserve capacity
    
    let buffer  = UnsafeMutablePointer<Int8>.allocate(capacity: bufsize)
    defer { buffer.deallocate(capacity: bufsize) }
    
    while true {
      let rc = ap_get_client_block(th, buffer, bufsize)
      guard rc != 0 else { break } // EOF
      guard rc >  0 else { throw Error.ReadFailed }

      // hm
      buffer.withMemoryRebound(to: UInt8.self, capacity: rc) { buffer in
        let bp = UnsafeBufferPointer(start: buffer, count: rc)
        bytes.append(contentsOf: bp)
      }
    }
    
    return bytes
  }
}
