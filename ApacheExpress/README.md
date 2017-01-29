<h2>mod_swift - ApacheExpress
  <img src="http://zeezide.com/img/mod_swift.svg"
       align="right" width="128" height="128" />
</h2>

![Apache 2](https://img.shields.io/badge/apache-2-yellow.svg)
![Swift3](https://img.shields.io/badge/swift-3-blue.svg)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Travis](https://travis-ci.org/AlwaysRightInstitute/mod_swift.svg?branch=develop)

**mod_swift** is a technology demo which shows how to write native modules
for the
[Apache Web Server](https://httpd.apache.org)
in the 
[Swift 3](http://swift.org/)
programming language.
**Server Side Swift the [right](http://www.alwaysrightinstitute.com/) way**.

## ApacheExpress

TODO: Cleanup the README.
[mods_expressdemo](../mods_expressdemo/README.md)

### Know what? This looks awkwardly difficult ...

Fair enough. So we integrated a tiny subset of 
[Noze.io](http://noze.io/)
to allow you to do just that. This is what it looks like:

```Swift
func expressMain() {
  apache.onRequest { req, res in
    res.writeHead(200, [ "Content-Type": "text/html" ])
    try res.end("<h1>Hello World</h1>")
  }
}
```

And is configured like this in the Apache conf:

    <LocationMatch /express/*>
      SetHandler de.zeezide.TinyExpress
    </LocationMatch>

Now you are saying, this is all nice and pretty. But what about Connect?
I want to write and reuse middleware!
Here you go:

```Swift
func expressMain() {
  let app = apache.connect()
  
  app.use { req, res, next in
    console.info("Request is passing Connect middleware ...")
    res.setHeader("Content-Type", "text/html; charset=utf-8")
    // Note: we do not close the request, we continue with the next middleware
    try next()
  }
  
  app.use("/express/connect") { req, res, next in
    try res.write("<p>This is a random cow:</p><pre>")
    try res.write(vaca())
    try res.write("</pre>")
    res.end()
  }
}
```

And Express? Sure, the Apache Express is about to leave:
```Swift
let app = apache.express(cookieParser(), session())

app.get("/express/cookies") { req, res, _ in
  // returns all cookies as JSON
  try res.json(req.cookies)
}

app.get("/express/") { req, res, _ in
  let tagline = arc4random_uniform(UInt32(taglines.count))
  
  let values : [ String : Any ] = [
    "tagline"     : taglines[Int(tagline)],
    "viewCount"   : req.session["viewCount"] ?? 0,
    "cowOfTheDay" : cows.vaca()
  ]
  try res.render("index", values)
}
```

Yes. All that is running within Apache.
The working example can be found here:
[ExpressMain.swift](Sources/ExpressMain.swift#L9).
