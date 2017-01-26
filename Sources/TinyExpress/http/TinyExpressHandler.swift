//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import ZzApache
import Apache2

// The main entry point to generate TinyExpress.http server callbacks
func TinyExpressHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  guard let handler = p?.pointee.oHandler   else { return DECLINED }
  guard handler == "de.zeezide.tinyexpress" else { // handlers are lowercased!
    return DECLINED
  }
  
  guard let server = apache else {
    apz_log_rerror_(#file, #line, -1 /*TBD*/, APLOG_ERR, -1, p,
                    "TinyExpress handler is invoked, " +
                    "but global context is missing!")
    return HTTP_INTERNAL_SERVER_ERROR
  }
  
  let context = http_internal.ApacheRequest(handle: p!, server: server)
  assert(context.request  != nil) // should be there right after init
  assert(context.response != nil)
  
  // invoke server callbacks
  do {
    try server.emitOnRequest(request: context.request!,
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

func TinyExpressPostConfig(pconf: OpaquePointer?,
                           plog:  OpaquePointer?,
                           ptemp: OpaquePointer?,
                           server: UnsafeMutablePointer<server_rec>?) -> Int32
{
  // lets call out express main function
  expressMain()
  return OK
}
