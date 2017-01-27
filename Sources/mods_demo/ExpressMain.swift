//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import Darwin
import cows

func expressMain() {
  // this is our 'high level' entry point where we can register routes and such.
  console.info("Attention passengers, the ZeeZide express is leaving ...")
  
  
  // Level 1: demo for a generic http.Server like callback
  apache.onRequest { req, res in
    guard req.url.hasPrefix("/server") else { return }
    
    console.info("simple handler:", req)
    res.writeHead(200, [ "Content-Type": "text/html" ])
    try res.end("<h1>Hello World</h1>")
  }
  
  
  // Level 2: Lets go and Connect! Middleware based processing
  
  do {
    let app = connect()
    
    app.use { req, res, next in
      guard req.url.hasPrefix("/connect") else { return }
      
      console.info("Request is passing Connect middleware ...")
      
      // send a common header
      res.setHeader("Content-Type", "text/html; charset=utf-8")
      try res.write("<h4>Connect Example</h4>")
      try res.write("<p><a href='/'>Homepage</a></p>")
      
      // Note: we do not close the request, we continue with the next middleware
      try next()
    }
    
    app.use("/connect/hello") { req, res, next in
      console.info("Entering Hello middleware ..")
      try res.write("<h1>Hello Connect!</h1>")
      try res.write("<p>This is a random cow:</p><pre>")
      try res.write(vaca())
      try res.write("</pre>")
      res.end()
    }
  }
  
  // Level 3: After Connecting we'd like to hop into the Apache Express!
  
  do {
    let app = express()
    
    // app.use(logger("dev")) - no use in Apache
    // app.use(bodyParser.urlencoded()) - TODO!!!
    app.use(cookieParser())
    app.use(session())
    // app.use(serveStatic(__dirname + "/public"))
    // - TODO, kinda, makes less sense with Apache
    
    app.use { req, res, next in
      guard req.url.hasPrefix("/express") else { return }
      
      console.info("Request is passing Express middleware ...")
      try next()
    }
    
    
    // MARK: - Express Settings
    
    // really mustache, but we want to use .html
    app.set("view engine", "html")
    
    
    // MARK: - Routes
    
    let taglines = [
      "Less than Perfect.",
      "Das Haus das Verrückte macht.",
      "Rechargeables included",
      "Sensible Server Side Swift aS a Successful Software Service Solution",
      "Zoftware az a a Zervice by ZeeZide"
    ]
    
    // MARK: - Session View Counter
    
    app.use { req, _, next in
      req.session["viewCount"] = req.session[int: "viewCount"] + 1
      try next()
    }
    
    
    // MARK: - JSON & Cookies
    
    app.get("/express/json") { _, res, _ in
      try res.json([
        [ "firstname": "Donald",   "lastname": "Duck" ],
        [ "firstname": "Dagobert", "lastname": "Duck" ]
      ])
    }
    
    app.get("/express/cookies") { req, res, _ in
      // returns all cookies as JSON
      try res.json(req.cookies)
    }
    
    
    // MARK: - Cows
    
    app.get("/express/cows") { req, res, _ in
      let cow = cows.vaca()
      try res.send("<html><body><pre>\(cow)</pre></body></html>")
    }
    
    
    // MARK: - Main page
    
    app.get("/express/") { req, res, _ in
      let tagline = arc4random_uniform(UInt32(taglines.count))
      
      let values : [ String : Any ] = [
        "tagline"     : taglines[Int(tagline)],
        "viewCount"   : req.session["viewCount"] ?? 0,
        "cowOfTheDay" : cows.vaca()
      ]
      try res.render("index", values)
    }
  }
}
