//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension ApacheServer {

  public func express(middleware: Middleware...) -> Express {
    let app = Express()
    
    for m in middleware {
      _ = app.use(m)
    }

    self.onRequest(handler: app.requestHandler)
    
    return app
  }

}