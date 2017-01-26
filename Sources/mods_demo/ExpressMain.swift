//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

func expressMain() {
  // this is our 'high level' entry point where we can register routes and such.
  console.info("Attention passengers, the ZeeZide express is leaving ...")
  
  // demo for a generic http.Server like callback
  apache.onRequest { req, res in
    if req.url == "/express/hello" {
      console.info("simple handler:", req)
      res.writeHead(200, [ "Content-Type": "text/html" ])
      try res.end("<h1>Hello World</h1>")
    }
  }
}
