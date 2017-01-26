//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import ZzApache
import Apache2

extension http {
  
  class ServerResponse : MessageBase,
                         GWritableStreamType, WritableByteStreamType
  {
    
    public var statusCode : Int? = nil
    
    public func writeHead(_ statusCode: Int,
                          _ headers: Dictionary<String, Any> = [:])
    {
      self.statusCode = statusCode
      
      // merge in headers
      for (key, value) in headers {
        setHeader(key, value)
      }
    }
    
    public func end() {
      // I don't think we need this here. We end when we return from the
      // handler.
    }
    
    
    // MARK: - Headers
    
    final override var _headersTable : OpaquePointer? {
      // TODO: this needs to take into account err_headers_out
      guard let h = apacheRequest.typedHandle else { return nil }
      return h.pointee.headers_out
    }
    
    
    // MARK: - Output Stream
    
    func writev(buckets chunks: [ [ UInt8 ] ], done: DoneCB?) throws {
      if statusCode == nil {
        writeHead(200)
      }
      
      guard !chunks.isEmpty        else { return }
      guard !chunks.first!.isEmpty else { return }
      
      guard let h = apacheRequest.typedHandle else {
        if let cb = done { cb() }
        throw(Error.ApacheHandleGone)
      }
      
      // TBD: This actually doesn't seem to be recommended for Apache 2.
      //      See: "Introduction to Buckets and Brigades" 
      for chunk in chunks {
        try chunk.withUnsafeBufferPointer { bp in
          var count = Int32(bp.count)
          var ptr   = bp.baseAddress
          
          let rc = ap_rwrite(ptr, count, h)
          if rc < 0 {
            throw Error.WriteFailed // TODO: improve me ;-)
          }
          
          count -= rc
          ptr = ptr?.advanced(by: Int(rc))
        }
      }
      if let cb = done { cb() }
    }
    
    // MARK: - CustomStringConvertible
    
    var description : String {
      var s = "<Response"
      if let h = apacheRequest.handle {
        s += "[\(h)]: "
      }
      else { s += "[gone]: " }
      
      if let status = self.statusCode {
        s += "\(status)"
      }
      
      s += ">"
      return s
    }
  }
}
