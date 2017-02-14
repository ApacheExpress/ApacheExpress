//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

// This is the low-level entry point which sets up the Apache module.

import Apache2
import ApacheExpress
import ZzApache

// This is our support object for ApacheExpress. Careful, this must be
// thread safe!
var apache : http_internal.ApacheServer! = nil

// The main entry point to generate ApacheExpress.http server callbacks
func ApacheExpressHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  guard let apache = apache else { return DECLINED }
  return apache.handler(request: p)
}

func ApacheExpressPostConfig(pconf:  OpaquePointer?,
                             plog:   OpaquePointer?,
                             ptemp:  OpaquePointer?,
                             server: UnsafeMutablePointer<server_rec>?) -> Int32
{
  expressMain()
  return OK
}

fileprivate func register_hooks(pool: OpaquePointer?) {
  // this is to support ApacheExpress
  ap_hook_handler    (ApacheExpressHandler,    nil, nil, APR_HOOK_MIDDLE)
  ap_hook_post_config(ApacheExpressPostConfig, nil, nil, APR_HOOK_LAST)
  
  // this is for .well-known URLs used to locate the CalDAV API entrypoint
  ap_hook_handler(dotWellKnownHandler, nil, nil, APR_HOOK_FIRST)
}


// This is our module structure for Apache
var module = Apache2.module(name: "mods_todomvc")


// And `ApacheMain` is called by mod_swift to configure the module!
@_cdecl("ApacheMain")
public func ApacheMain(cmd: UnsafeMutablePointer<cmd_parms>) {
  // Setup module struct
  module.register_hooks = register_hooks
  
  // this is to support ApacheExpress
  apache = http_internal.ApacheServer(handle: cmd.pointee.server)
  
  let rc = apz_register_swift_module(cmd, &module)
  assert(rc == APR_SUCCESS, "Could not add Swift module!")
}
