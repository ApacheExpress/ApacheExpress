//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import enum     ExExpress.http
import protocol ExExpress.ConsoleType

// MARK: - Private API

import Apache2

public enum http_internal { // hm, public internal? :-)
  
  public final class ApacheServer : http.Server {
    
    let handle : UnsafePointer<server_rec>
    let apLog  : ConsoleType
    
    public init(handle: UnsafePointer<server_rec>) {
      self.handle = handle
      self.apLog = ApacheConsole(server: handle)
      super.init()
    }
    
    public override var log : ConsoleType { return apLog }
  }

  // This is a wrapper around the Apache `request_rec` structure.
  //
  // It is a little awkward due to `swiftc` crasher workarounds.
  public final class ApacheRequest {

    let server           : ApacheServer
    var handle           : OpaquePointer? = nil
    var didHandleRequest = true
    
    var request  : ApacheIncomingMessage? = nil
    var response : ApacheServerResponse?  = nil
    
    init(handle: UnsafeMutablePointer<request_rec>, server: ApacheServer) {
      self.server = server
      
      // yes, this is awkward, but we cannot store request_rec or ZzApache in an
      // instance variable, crashes swiftc
      self.handle = OpaquePointer(handle)
      
      // All this is a little weird and probably should be done differently ;->
      request  = ApacheIncomingMessage(apacheRequest: self)
      response = ApacheServerResponse (apacheRequest: self)
    }
    
    var handlerResult : Int32 {
      guard didHandleRequest                  else { return DECLINED }
      
      // This means the user never triggered res.writeHead()
      guard let status = response?.statusCode else { return DECLINED }
      
      // Hm. Is this quite right? :-)
      // No: this is too late to set the content status. This is just what is
      //     being logged.
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
