//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

//import typealias ExExpress.Middleware // crash #imageLiteral(resourceName: "mod_swift-mustache-screenshot.jpg")
import ExExpress

public extension http.Server {

  // TBD: ExExpress also has this, we should probably drop it
  public func express(middleware: Middleware...) -> ApacheExpress {
    let app = ApacheExpress()
    
    for m in middleware {
      _ = app.use(m)
    }

    self.onRequest(handler: app.requestHandler)
    
    return app
  }

}

import class ExExpress.Express
import enum  ExExpress.process

open class ApacheExpress : Express {
  
  // MARK: - Extension Point for Subclasses
  
  override
  open func viewDirectory(for engine: String, response: ServerResponse)
            -> String
  {
    guard let ar = response as? ApacheServerResponse else {
      return super.viewDirectory(for: engine, response: response)
    }
    
    // Maybe that should be an array
    // This should allow 'views' as a relative path.
    // Also, in Apache it should be a configuration directive.
    let viewsPath = (get("views") as? String)
                 ?? process.env["EXPRESS_VIEWS"]
                 ?? ar.apacheRequest.pathRelativeToServerRoot(filename: "views")
                 ?? process.cwd()
    return viewsPath
  }
}
