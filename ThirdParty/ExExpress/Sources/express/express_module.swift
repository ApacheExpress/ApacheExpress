//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if STANDALONE // leave that to the host of ExExpress to avoid ambiguities
public extension http.Server {

  public func express(middleware: Middleware...) -> Express {
    let app = Express()
    
    for m in middleware {
      _ = app.use(m)
    }

    self.onRequest(handler: app.requestHandler)
    
    return app
  }

}
#endif
