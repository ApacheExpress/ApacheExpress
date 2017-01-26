//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import ZzApache
import Apache2

extension http {
  
  class IncomingMessage : MessageBase, CustomStringConvertible {

    var httpVersion : String {
      guard let h = apacheRequest.typedHandle else { return "" }
      return h.pointee.oProtocol
    }
    var method : String {
      guard let h = apacheRequest.typedHandle else { return "" }
      return h.pointee.oMethod
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
    
    var description : String {
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
}
