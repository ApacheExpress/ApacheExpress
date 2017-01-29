//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import ZzApache
import Apache2

public class ServerResponse : MessageBase,
                              GWritableStreamType, WritableByteStreamType,
                              CustomStringConvertible
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
  
  
  // MARK: - End Handlers
  
  var finishListeners = [ ( ServerResponse ) -> Void ]()
  
  func emitFinish() {
    while !finishListeners.isEmpty {
      let copy = finishListeners
      finishListeners.removeAll()
      
      for listener in copy {
        listener(self)
      }
    }
  }
  
  public func onceFinish(handler: @escaping ( ServerResponse ) -> Void) {
    finishListeners.append(handler)
  }
  public func onFinish(handler: @escaping ( ServerResponse ) -> Void) {
    finishListeners.append(handler)
  }
  
  // MARK: - Headers
  
  final override var _headersTable : OpaquePointer? {
    // TODO: this needs to take into account err_headers_out
    guard let h = apacheRequest.typedHandle else { return nil }
    return h.pointee.headers_out
  }
  
  
  // MARK: - Output Stream
  
  public func end() throws {
    guard let th = apacheRequest.typedHandle else {
      throw(Error.ApacheHandleGone)
    }
    
    let brigade = apacheRequest.createBrigade()
    let eof = apr_bucket_eos_create(brigade?.pointee.bucket_alloc)
    apz_brigade_insert_tail(brigade, eof)
    let rv = ap_pass_brigade(th.pointee.output_filters, brigade)
    
    emitFinish()
    
    if rv != APR_SUCCESS {
      throw Error.WriteFailed // TODO: Improve me ;-)
    }
  }
  
  public func writev(buckets chunks: [ [ UInt8 ] ], done: DoneCB?) throws {
    if statusCode == nil {
      writeHead(200)
    }
    
    guard !chunks.isEmpty        else { return }
    guard !chunks.first!.isEmpty else { return }
    
    guard let h = apacheRequest.typedHandle else {
      if let cb = done { try cb() }
      throw(Error.ApacheHandleGone)
    }
    
    let brigade = apacheRequest.createBrigade()
    
    // Note: What we really want here is a special bucket_type that can extract
    //       the buffer from the Swift object on-demand.
    for chunk in chunks {
      try chunk.withUnsafeBufferPointer { bp in
        var count = Int32(bp.count)
        var ptr   = bp.baseAddress
        
        // This flushes to the filter if the internal write buffer becomes
        // too large.
        let rc = apz_fwrite(h.pointee.output_filters, brigade,
                            ptr, apr_size_t(count))
        if rc < 0 {
          throw Error.WriteFailed // TODO: improve me ;-)
        }
        
        count -= rc
        ptr = ptr?.advanced(by: Int(rc))
      }
    }
    
    let rv = ap_pass_brigade(h.pointee.output_filters, brigade)
    
    if let cb = done { try cb() }
    
    if rv != APR_SUCCESS {
      throw Error.WriteFailed // TODO: Improve me ;-)
    }
  }
  
  // MARK: - CustomStringConvertible
  
  public var description : String {
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
