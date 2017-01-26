//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import ZzApache
import Apache2

public class IncomingMessage : MessageBase, CustomStringConvertible {

  var httpVersion : String {
    guard let h = apacheRequest.typedHandle else { return "" }
    return h.pointee.oProtocol
  }
  var method : String {
    set {
      guard let h = apacheRequest.typedHandle else { return }
      
      let mnum = ap_method_number_of(newValue)
      // TODO: check return value
      
      // Not sure this is really OK
      h.pointee.method_number = mnum
      h.pointee.method = UnsafePointer(apr_pstrdup(h.pointee.pool, newValue))
    }
    get {
      guard let h = apacheRequest.typedHandle else { return "" }
      return h.pointee.oMethod
    }
  }
  
  var url : String {
    guard let h = apacheRequest.typedHandle else { return "" }
    return h.pointee.oURI
  }

  // MARK: - Headers
  
  final override var _headersTable : OpaquePointer? {
    guard let h = apacheRequest.typedHandle else { return nil }
    return h.pointee.headers_in
  }
  
  // MARK: - CustomStringConvertible
  
  public var description : String {
    var s = "<Request"
    if let h = apacheRequest.handle {
      s += "[\(h)]: "
    }
    else { s += "[gone]: " }
    s += "\(method) \(url)"
    s += ">"
    return s
  }
}
