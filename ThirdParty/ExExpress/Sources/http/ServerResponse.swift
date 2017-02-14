//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

// Note: In here we drop the dependency on `GWritableStreamType` so that we can
//       use it as a type. It still is a `WritableByteStreamType` and the
//       implementing class can still add GWritableStreamType.

public protocol ServerResponse : HttpMessageBaseType, WritableByteStreamType {
  
  var statusCode  : Int? { get set }
  var headersSent : Bool { get }
  
  func writeHead(_ statusCode: Int, _ headers: Dictionary<String, Any>)
  
  func writev(buckets chunks: [ [ UInt8 ] ], done: DoneCB?) throws

  // func emitFinish()
  func onceFinish(handler: @escaping ( ServerResponse ) -> Void)
  func onFinish  (handler: @escaping ( ServerResponse ) -> Void)
}

public extension ServerResponse {

  public func writeHead(_ statusCode: Int,
                        _ headers: Dictionary<String, Any> = [:]) {
    self.statusCode = statusCode
    
    // merge in headers
    for (key, value) in headers {
      setHeader(key, value)
    }
  }

}
