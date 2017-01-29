//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import ZzApache
import Apache2

typealias ApacheServer = http_internal.ApacheServer

public extension http_internal.ApacheServer {

  // The main entry point to generate TinyExpress.http server callbacks
  func handler(request p: UnsafeMutablePointer<request_rec>?) -> Int32 {
    guard let handler = p?.pointee.oHandler   else { return DECLINED }
    guard handler == "de.zeezide.tinyexpress" else { // handlers are lowercased!
      return DECLINED
    }
    
    let context = http_internal.ApacheRequest(handle: p!, server: self)
    assert(context.request  != nil) // should be there right after init
    assert(context.response != nil)
    
    // invoke server callbacks
    do {
      try emitOnRequest(request: context.request!,
                        response: context.response!)
    }
    catch (let error) {
      apz_log_rerror_(#file, #line, -1 /*TBD*/, APLOG_ERR, -1, p,
                      "TinyExpress handler failed: \(error)")
      context.onHandlerDone()
      return HTTP_INTERNAL_SERVER_ERROR
    }
    
    // teardown / finish up
    let result = context.handlerResult
    context.onHandlerDone()
    return result
  }
}


// MARK: - Raw Request

// This could be used, but remember that you usually get a pointer to the
// struct, not the struct itself. Hence you would need to do this:
//
//   let method = req?.pointee.oMethod
//
extension request_rec {
  var oMethod      : String { return String(cString: method)        }
  var oURI         : String { return String(cString: uri)           }
  var oUnparsedURI : String { return String(cString: unparsed_uri)  }
  var oHandler     : String { return String(cString: handler)       }
  var oTheRequest  : String { return String(cString: the_request)   }
  var oProtocol    : String { return String(cString: self.protocol) }
}


// MARK: - Module

public extension Apache2.module {
  
  public init(name: String) {
    self.init()
    
    // Replica of STANDARD20_MODULE_STUFF (could also live as a C support fn)
    version       = MODULE_MAGIC_NUMBER_MAJOR
    minor_version = MODULE_MAGIC_NUMBER_MINOR
    module_index  = -1
    self.name     = UnsafePointer(strdup(name)) // leak
    dynamic_load_handle = nil
    next          = nil
    magic         = MODULE_MAGIC_COOKIE
    rewrite_args  = nil
  }
  
}
