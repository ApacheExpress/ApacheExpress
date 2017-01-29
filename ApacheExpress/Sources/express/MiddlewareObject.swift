//
//  MiddlewareObject.swift
//  Noze.io
//
//  Created by Helge Hess on 02/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public protocol MiddlewareObject {
  
  func handle(request  req: IncomingMessage,
              response res: ServerResponse,
              next     cb:  @escaping Next) throws
  
}

public extension MiddlewareObject {
  
  public var middleware: Middleware {
    return { req, res, cb in
      try self.handle(request: req, response: res, next: cb)
    }
  }

  public var requestHandler: RequestEventCB {
    return { req, res in
      try self.handle(request: req, response: res) { _ in
        // essentially the final handler
        console.warn("No middleware called end: " +
                     "\(self) \(req.method) \(req.url)")
        res.writeHead(404)
        try res.end()
      }
    }
  }
}
