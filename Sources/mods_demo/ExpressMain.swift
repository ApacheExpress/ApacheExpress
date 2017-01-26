//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import cows

func expressMain() {
  // this is our 'high level' entry point where we can register routes and such.
  console.info("Attention passengers, the ZeeZide express is leaving ...")
  
  
  // Level 1: demo for a generic http.Server like callback
  apache.onRequest { req, res in
    if req.url == "/express/hello" {
      console.info("simple handler:", req)
      res.writeHead(200, [ "Content-Type": "text/html" ])
      try res.end("<h1>Hello World</h1>")
    }
  }
  
  
  // Level 2: Lets go and Connect! Middleware based processing
  
  let app = connect()
  
  app.use { req, res, next in
    guard req.url != "/express/hello" else { return } // do not interfere Level1
    
    console.info("Request is passing Connect middleware ...")
    
    // send a common header
    res.setHeader("Content-Type", "text/html; charset=utf-8")
    try res.write("<h4>Connect Example</h4>")
    try res.write("<p><a href='/'>Homepage</a></p>")
    
    // Note: we do not close the request, we continue with the next middleware
    try next()
  }
  
  app.use("/express/connect") { req, res, next in
    console.info("Entering Hello middleware ..")
    try res.write("<h1>Hello Connect!</h1>")
    try res.write("<p>This is a random cow:</p><pre>")
    try res.write(vaca())
    try res.write("</pre>")
    res.end()
  }
}
