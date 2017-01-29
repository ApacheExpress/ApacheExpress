//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import Apache2
import ZzApache

class ApacheConsole : ConsoleType {
  
  let request : OpaquePointer!
  let server  : UnsafePointer<server_rec>!
  
  init(request: OpaquePointer! = nil,
       server: UnsafePointer<server_rec>! = nil)
  {
    self.request = request
    self.server  = server
  }

  var logLevel : LogLevel {
    // TODO
    return .Log
  }
  
  func primaryLog(_ logLevel: LogLevel, _ msgfunc: () -> String,
                  _ values: [ Any? ] )
  {
    var s = msgfunc()
    
    for v in values {
      s += " "
      
      if let v = v as? CustomStringConvertible {
        s += v.description
      }
      else if let v = v as? String {
        s += v
      }
      else {
        s += "\(v)"
      }
    }
    
    if request != nil {
      apz_log_rerror_(nil, -1, -1, logLevel.apacheLevel, -1,
                      UnsafePointer<request_rec>(request), s)
    }
    else if server != nil {
      apz_log_error_(nil, -1, -1, logLevel.apacheLevel, -1,
                     server, s)
    }
    else {
      apz_log_error_(nil, -1, -1, logLevel.apacheLevel, -1,
                     nil, s)
    }
  }
}

extension LogLevel {
  
  var apacheLevel : Int32 {
    switch self {
      case .Error: return APLOG_ERR
      case .Warn:  return APLOG_WARNING
      case .Log:   return APLOG_NOTICE
      case .Info:  return APLOG_INFO
      case .Trace: return APLOG_DEBUG
    }
  }
  
}
