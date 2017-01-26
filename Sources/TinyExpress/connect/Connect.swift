//
//  Connect.swift
//  Noze.io
//
//  Created by Helge Heß on 5/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/// TODO: document, what are the varargs in Next?
public typealias Next = (Any...) throws -> Void

/// Supposed to call Next() when it is done.
public typealias Middleware =
         ( IncomingMessage, ServerResponse, @escaping Next )
         throws -> Void


public class Connect {
  
  struct MiddlewareEntry {
    
    let urlPrefix  : String?
    let middleware : Middleware
    
    init(middleware: @escaping Middleware) {
      self.middleware = middleware
      self.urlPrefix  = nil
    }
    
    init(urlPrefix: String, middleware: @escaping Middleware) {
      self.urlPrefix  = urlPrefix
      self.middleware = middleware
    }
    
    func matches(request rq: IncomingMessage) -> Bool {
      if urlPrefix != nil && !rq.url.isEmpty {
        guard rq.url.hasPrefix(urlPrefix!) else { return false }
      }
      
      return true
    }
    
  }
  
  var middlewarez = [MiddlewareEntry]()
  
  
  // MARK: - use()
  
  @discardableResult
  public func use(_ cb: @escaping Middleware) -> Self {
    middlewarez.append(MiddlewareEntry(middleware: cb))
    return self
  }
  @discardableResult
  public func use(_ p: String, _ cb: @escaping Middleware) -> Self {
    middlewarez.append(MiddlewareEntry(urlPrefix: p, middleware: cb))
    return self
  }
  
  
  // MARK: - Closures to pass on
  
  public var handle : RequestEventCB {
    return { req, res in
      try self.doRequest(req, res)
    }
  }
  public var middleware : Middleware {
    return { req, res, cb in
      try self.doRequest(req, res) // THIS IS WRONG, need to call cb() only on last
      try cb()
    }
  }
  
  
  // MARK: - run middleware
  
  func doRequest(_ request:  IncomingMessage,
                 _ response: ServerResponse) throws
  {
    // first lookup all middleware matching the request (i.e. the URL prefix
    // matches)
    // TODO: would be nice to have this as a lazy filter.
    let matchingMiddleware = middlewarez.filter { $0.matches(request: request) }
    
    let endNext : Next = { _ in
      // essentially the final handler
      response.writeHead(404)
      response.end()
    }
    var next    : Next? = { _ in } // cannot be let as it's self-referencing
    
    var i = 0 // capture position in matching-middleware array (shared)
    next = {
      args in
      
      // grab next item from matching middleware array
      let middleware = matchingMiddleware[i].middleware
      i += 1 // this is shared between the blocks, move position in array
      
      // call the middleware - which gets the handle to go to the 'next'
      // middleware. the latter can be the 'endNext' which won't do anything.
      let isLast = i == matchingMiddleware.count
      try middleware(request, response, isLast ? endNext : next!)
      
      if isLast {
        next = nil // break cycle?
      }
    }
    
    try next!()
  }
  
}
