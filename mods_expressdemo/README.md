<h2>mod_swift - mods_expressdemo
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

## mods_expressdemo

[ApacheExpress](../ApacheExpress/README.md) is a port of the
[Noze.io](http://noze.io/)
[Express](https://github.com/NozeIO/Noze.io/tree/master/Sources/express)
and
[Connect](https://github.com/NozeIO/Noze.io/tree/master/Sources/connect)
frameworks, as well as some associated modules, to the mod_swift Apache API.

mods_expressdemo is a demo for those.
It demos Mustache template rendering, form values, cookies, sessions, JSON support,
cookie access, and most importantly: 🐄.

Well, that:
```swift
app.get("/express/form") { _, res, _ in
  try res.render("form")
}
app.post("/express/form") { req, res, _ in
  let user = req.body[string: "u"]
  
  let options : [ String : Any ] = [
    "user"      : user,
    "nouser"    : user.isEmpty,
    "viewCount" : req.session["viewCount"] ?? 0
  ]
  try res.render("form", options)
}

app.get("/express/json") { _, res, _ in
  try res.json([
    [ "firstname": "Donald",   "lastname": "Duck" ],
    [ "firstname": "Dagobert", "lastname": "Duck" ]
  ])
}

app.get("/express/cookies") { req, res, _ in
  try res.json(req.cookies)  // returns all cookies as JSON
}

app.get("/express/cows") { req, res, _ in
  let cow = cows.vaca()
  try res.send("<html><body><pre>\(cow)</pre></body></html>")
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


### Who

**mod_swift** is brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We like feedback, GitHub stars, cool contract work,
presumably any form of praise you can think of.
We don't like people who are wrong.

There is a `#mod_swift` channel on the [Noze.io Slack](http://slack.noze.io).
