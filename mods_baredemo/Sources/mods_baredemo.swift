//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

// This is the low-level entry point which sets up the Apache module.

import Apache2
import ZzApache

// MARK: - Hooks

fileprivate func register_hooks(pool: OpaquePointer?) {
  ap_hook_handler(RequestInfoHandler, nil, nil, APR_HOOK_MIDDLE)
  ap_hook_handler(MustacheHandler,    nil, nil, APR_HOOK_MIDDLE)
  ap_hook_handler(DatabaseHandler,    nil, nil, APR_HOOK_MIDDLE)
}

// MARK: - This is our module structure for Apache
var module = Apache2.module(name: "mods_baredemo")


// MARK: - Config

extension request_rec {
  
  var ourConfig : ApacheDictionaryConfig? { // can this be nil?
    let ptr = ap_get_module_config(self.per_dir_config, &module)
    return ApacheDictionaryConfig.fromOpaque(ptr)
  }
  
}
extension ZzApacheRequest { // Auth wrappers for http_core
  var ourConfig : ApacheDictionaryConfig {
    return raw.pointee.ourConfig!
  }
}

typealias ApacheDirectiveTake2 =
                  @convention(c) ( UnsafeMutablePointer<cmd_parms>?,
                                   UnsafeMutableRawPointer?,
                                   UnsafePointer<Int8>?,
                                   UnsafePointer<Int8>? )
                                  -> UnsafePointer<Int8>?

fileprivate
func SetSwiftConfigValue(cmd:    UnsafeMutablePointer<cmd_parms>?,
                         config: UnsafeMutableRawPointer?,
                         arg0:   UnsafePointer<Int8>?,
                         arg1:   UnsafePointer<Int8>?)
  -> UnsafePointer<Int8>?
{
  let cfg = ApacheDictionaryConfig.fromOpaque(config)
  cfg?.values[String(cString: arg0!)] = String(cString: arg1!)
  // print("run \(cmd) \(config) \(arg0) \(arg1): \(cfg)")
  return nil
}

let OR_ALL = (OR_LIMIT|OR_OPTIONS|OR_FILEINFO|OR_AUTHCFG|OR_INDEXES)

extension command_rec {
  
  mutating func take2(_ name: String,
                      _ cb:   @escaping ApacheDirectiveTake2,
                      reqOverride: Int32 = OR_ALL,
                      _ info: String)
  {
    self.name         = UnsafePointer(strdup(name)) // TODO: dealloc
    self.func.take2   = cb
    self.cmd_data     = nil // userdata
    self.req_override = reqOverride
    self.args_how     = Apache2.TAKE2
    self.errmsg       = UnsafePointer(strdup(info)) // TODO: dealloc
  }

  mutating func end() {
    self.name     = nil
    self.cmd_data = nil
  }
}


// MARK: - `ApacheMain` is called by mod_swift to configure the module!

@_cdecl("ApacheMain")
public func ApacheMain(cmd: UnsafeMutablePointer<cmd_parms>) {
  // Setup module struct
  module.register_hooks    = register_hooks
  
  module.create_dir_config = { p, d in ApacheDictionaryConfig.create(p, d) }
  module.merge_dir_config  = { p, b, n in
    return ApacheDictionaryConfig.merge(p, b, n)
  }
  
  let commands = UnsafeMutablePointer<command_rec>.allocate(capacity: 2)
  do {
    var ptr = commands
    
    ptr.pointee.take2("SetSwiftConfigValue",
                      SetSwiftConfigValue,
                      "Set a config value in the Swift config dict")
    
    ptr = ptr.advanced(by: 1)
    ptr.pointee.end()
  }
  module.cmds = UnsafePointer(commands)
  
  // Let Apache know about our module
  let rc = apz_register_swift_module(cmd, &module)
  assert(rc == APR_SUCCESS, "Could not add Swift module!")
}
