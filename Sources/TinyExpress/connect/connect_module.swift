//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

public func connect(middleware: Middleware...) -> Connect {
  let app = Connect()
  
  for m in middleware {
    _ = app.use(m)
  }
  
  apache.onRequest(handler: app.handle)
  
  return app
}
