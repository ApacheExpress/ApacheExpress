//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

public protocol IncomingMessage : HttpMessageBaseType {

  var httpVersion : String { get     }
  var method      : String { get set }
  var url         : String { get     }
  
  // hack, use a proper stream
  func readBody(bufsize: Int) throws -> [ UInt8 ]

}

public extension IncomingMessage {
  
  func readBody() throws -> [ UInt8 ] { // default args
    return try readBody(bufsize: 4096)
  }
  
  func readBodyAsString() throws -> String? {
    var body = try readBody()
    body.append(0) // oh well, yes this can be done better, but not builtin
    return String(cString: body)
  }
}
