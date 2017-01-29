//
//  ServerResponse.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension ServerResponse {
  // TODO: Would be cool: send(stream: GReadableStream), then stream.pipe(self)
  
  
  // MARK: - Status Handling
  
  /// Set the HTTP status, returns self
  ///
  /// Example:
  ///
  ///     res.status(404).send("didn't find it")
  ///
  @discardableResult
  public func status(_ code: Int) -> Self {
    statusCode = code
    return self
  }
  
  /// Set the HTTP status code and send the status description as the body.
  ///
  public func sendStatus(_ code: Int) throws {
    statusCode = code
    
    // TODO:
    // send(status.statusText)
    try send("HTTP status \(code)")
  }
  
  
  // MARK: - Sending Content
 
  public func send(_ string: String) throws {
    if canAssignContentType {
      var ctype = string.hasPrefix("<html") ? "text/html" : "text/plain"
      ctype += "; charset=utf-8"
      setHeader("Content-Type", ctype)
    }
    
    try self.end(string)
  }
  
  public func send(_ data: [UInt8]) throws {
    if canAssignContentType {
      setHeader("Content-Type", "application/octet-stream")
    }
    
    try self.end(data)
  }
  
  public func send(_ object: JSON)          throws { try json(object) }
  public func send(_ object: JSONEncodable) throws { try json(object) }
  
  var canAssignContentType : Bool {
    // TODO: fixme for Apache
    return statusCode == nil && getHeader("Content-Type") == nil
  }
  
  public func format(handlers: [ String : () -> () ]) {
    var defaultHandler : (() -> ())? = nil
    
    guard let rq = request else {
      handlers["default"]?()
      return
    }
    
    for ( key, handler ) in handlers {
      guard key != "default" else { defaultHandler = handler; continue }
      
      if let mimeType = rq.accepts(key) {
        if canAssignContentType {
          setHeader("Content-Type", mimeType)
        }
        handler()
        return
      }
    }
    if let cb = defaultHandler { cb() }
  }
  
  
  // MARK: - Header Accessor Renames
  
  public func get(_ header: String) -> Any? {
    return getHeader(header)
  }
  public func set(_ header: String, _ value: Any?) {
    if let v = value {
      setHeader(header, v)
    }
    else {
      removeHeader(header)
    }
  }
}
