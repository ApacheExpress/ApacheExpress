//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import ZzApache
import Apache2

// Base class for IncomingMessage/ServerResponse
public class MessageBase {
  
  enum Error : Swift.Error {
    case ApacheHandleGone
    case WriteFailed
    case ReadFailed
  }
  
  public var extra = [ String : Any ]()
  
  let apacheRequest : http_internal.ApacheRequest
  let log           : ConsoleType
  
  init(apacheRequest: http_internal.ApacheRequest) {
    self.apacheRequest = apacheRequest
    log = ApacheConsole(request: apacheRequest.handle)
  }
  
  
  // MARK: - Teardown
  
  func onHandlerDone() { // teardown
    // This is called before the Apache request structures goes out of
    // scope. Since the Swift object can live longer, we could copy over
    // the data we want to preserve (headers etc)
  }
  
  
  // MARK: - Headers
  
  var _headersTable : OpaquePointer? {
    fatalError("subclasses need to override _headersTable ...")
  }
  
  public func setHeader(_ name: String, _ value: Any) {
    if let value = value as? String {
      apr_table_set(_headersTable, name, value)
    }
    else { // hm ;->
      apr_table_set(_headersTable, name, "\(value)")
    }
  }
  
  public func removeHeader(_ name: String) {
    apr_table_unset(_headersTable, name)
  }
  
  public func getHeader(_ name: String) -> Any? {
    guard let v = apr_table_get(_headersTable, name) else { return nil }
    return String(cString: v)
  }
}

