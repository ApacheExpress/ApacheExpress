//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import ZzApache
import Apache2

// MARK: - Public API

public enum http {
}


// MARK: - Private API

public enum http_internal {

  // This is a wrapper around the Apache `request_rec` structure.
  //
  // It is a little awkward due to `swiftc` crasher workarounds.
  public final class ApacheRequest {

    let server           : ApacheServer
    var handle           : OpaquePointer? = nil
    var didHandleRequest = true
    
    var request  : IncomingMessage? = nil
    var response : ServerResponse?  = nil
    
    init(handle: UnsafeMutablePointer<request_rec>, server: ApacheServer) {
      self.server = server
      
      // yes, this is awkward, but we cannot store request_rec or ZzApache in an
      // instance variable, crashes swiftc
      self.handle = OpaquePointer(handle)
      
      // All this is a little weird and probably should be done differently ;->
      request  = IncomingMessage(apacheRequest: self)
      response = ServerResponse (apacheRequest: self)
    }
    
    var handlerResult : Int32 {
      guard didHandleRequest                  else { return DECLINED }
      
      // This means the user never triggered res.writeHead()
      guard let status = response?.statusCode else { return DECLINED }
      
      // Hm. Is this quite right? :-)
      return status == 200 ? OK : Int32(status)
    }
    
    func onHandlerDone() { // teardown and break cycles!
      if let req = request  { req.onHandlerDone(); request  = nil }
      if let res = response { res.onHandlerDone(); response = nil }
      handle = nil
    }
    
    var isValid : Bool { return handle != nil }
    
    var typedHandle : UnsafeMutablePointer<request_rec>? {
      // yes, this is awkward, but we cannot store request_rec or ZzApache in an
      // instance variable, crashes swiftc
      guard let handle = handle else { return nil }
      return UnsafeMutablePointer<request_rec>(handle)
    }
    
    func pathRelativeToServerRoot(filename: String) -> String? {
      guard let th = typedHandle else { return nil }
      guard let abspath = ap_server_root_relative(th.pointee.pool, filename)
       else { return nil }
      return String(cString: abspath)
    }
    
    func createBrigade() -> UnsafeMutablePointer<apr_bucket_brigade>? {
      guard let th = typedHandle else { return nil }
      
      return apr_brigade_create(th.pointee.pool,
                                th.pointee.connection.pointee.bucket_alloc)
    }
  }

}
