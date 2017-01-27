//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// Note: @escaping for 3.0.0 compat, not intended as per SR-2907
public func express(middleware: Middleware...) -> Express {
  let app = Express()
  
  for m in middleware {
    _ = app.use(m)
  }

  apache.onRequest(handler: app.requestHandler)
  
  return app
}
