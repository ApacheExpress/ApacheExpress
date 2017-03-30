//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

// This is the low-level entry point which sets up the Apache module.

import Apache2
import ZzApache
import Dispatch

// MARK: - API hooks

fileprivate var app : WebApp? = nil

func serve(_ appArg: @escaping WebApp) {
  app = appArg
}

// MARK: - Apache Hooks

fileprivate func register_hooks(pool: OpaquePointer?) {
  ap_hook_handler(S3WGAPIHandler, nil, nil, APR_HOOK_MIDDLE)
  ap_hook_post_config(post_config, nil, nil, APR_HOOK_LAST)
}

fileprivate func post_config(pconf:  OpaquePointer?,
                             plog:   OpaquePointer?,
                             ptemp:  OpaquePointer?,
                             server: UnsafeMutablePointer<server_rec>?) -> Int32
{
  Main()
  return OK
}

var module = Apache2.module(name: "mods_echo")

@_cdecl("ApacheMain")
public func ApacheMain(cmd: UnsafeMutablePointer<cmd_parms>) {
  // Setup module struct
  module.register_hooks = register_hooks
  
  // Let Apache know about our module
  let rc = apz_register_swift_module(cmd, &module)
  assert(rc == APR_SUCCESS, "Could not add Swift module!")
}


// MARK: - API Support

// Just a handler that logs a little info about a request and delivers
// the file when appropriate
func S3WGAPIHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  // the print crashes swiftc (Xcode 8.2.1 8C1002)
  //   print("handle request: \(p)")
  // this too:
  //   guard p != nil else { return DECLINED }
  
  guard strcmp(p?.pointee.handler, "echodemo") == 0 else { return DECLINED }
  
  guard let app = app else { return DECLINED }
  
  let request        = ApacheRequest(p!)
  let responseWriter = ApacheResponseWriter(p!)
  
  let bodyHandler = app(request, responseWriter)
  
  switch bodyHandler {
    case .discardBody:
      let rc = ap_discard_request_body(p)
      return OK // we are done
    
    case .processBody(let handler):
      let rc = ap_setup_client_block(p, REQUEST_CHUNKED_DECHUNK)
      guard rc == OK else {
        handler(HTTPBodyChunk.end)
        return OK
      }
      
      guard ap_should_client_block(p) != 0 else {
        // There is no message to read, this is *fine*. Not an error.
        handler(HTTPBodyChunk.end)
        return OK // we are done
      }
      
      let bufsize = 8092
      let buffer  = UnsafeMutablePointer<Int8>.allocate(capacity: bufsize)
      defer { buffer.deallocate(capacity: bufsize) }
      
      while true {
        let rc = ap_get_client_block(p, buffer, bufsize)
        guard rc != 0 else { break } // EOF
        
        guard rc >  0 else {
          handler(HTTPBodyChunk.failed(error: HTTPParserError.SomeError))
          return HTTP_BAD_REQUEST // no idea :-)
        }
        
        // hm
        buffer.withMemoryRebound(to: UInt8.self, capacity: rc) { buffer in
          let bp   = UnsafeBufferPointer(start: buffer, count: rc)
          //let data = DispatchData(bytesNoCopy: bp) - hm, dealloc error
          let data = DispatchData(bytes: bp)
          handler(HTTPBodyChunk.chunk(data: data))
        }
      }
      
      handler(HTTPBodyChunk.end)
      return OK // we are done
  }

}


// MARK: - Module

extension module {
  
  init(name: String) {
    self.init()
    
    // Replica of STANDARD20_MODULE_STUFF (could also live as a C support fn)
    version       = ZzApache.MODULE_MAGIC_NUMBER_MAJOR
    minor_version = Apache2.MODULE_MAGIC_NUMBER_MINOR
    module_index  = -1
    self.name     = UnsafePointer(strdup(name)) // leak
    dynamic_load_handle = nil
    next          = nil
    magic         = MODULE_MAGIC_COOKIE
    rewrite_args  = nil
  }
  
}
