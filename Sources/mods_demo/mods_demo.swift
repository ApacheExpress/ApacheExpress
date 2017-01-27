//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

// This is the low-level entry point which sets up the Apache module.

import Apache2

// This is our support object for TinyExpress. Careful, this must be
// thread safe!
var apache : http_internal.ApacheServer! = nil

fileprivate func register_hooks(pool: OpaquePointer?) {
  ap_hook_handler(RequestInfoHandler, nil, nil, APR_HOOK_MIDDLE)
  ap_hook_handler(MustacheHandler,    nil, nil, APR_HOOK_MIDDLE)
  
  // this is to support TinyExpress
  ap_hook_handler    (TinyExpressHandler,    nil, nil, APR_HOOK_MIDDLE)
  ap_hook_post_config(TinyExpressPostConfig, nil, nil, APR_HOOK_LAST)
}


// This is our module structure for Apache
var module = Apache2.module(name: "mods_demo")


// And `ApacheMain` is called by mod_swift to configure the module!
@_cdecl("ApacheMain")
func ApacheMain(cmd: UnsafeMutablePointer<cmd_parms>) {
  // Setup module struct
  module.register_hooks = register_hooks
  
  // this is to support TinyExpress
  apache = http_internal.ApacheServer(handle: cmd.pointee.server)
  
  // Let Apache know about our module
  let error = ap_add_loaded_module(&module, cmd.pointee.pool, "mods_demo")
  assert(error == nil, "Could not add Swift module!")
  
  // Note: we are lazy and do not register a cleanup
  ap_single_module_configure(cmd.pointee.pool, cmd.pointee.server, &module);
}
