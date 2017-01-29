<h2>mod_swift - mods_baredemo
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

## mods_baredemo

This project contains two 'raw' Apache handlers written in Swift. They are very
basic and only annotate the Apache API instead of wrapping it in some
pretty Swift library.

The project contains a pre-configured Xcode scheme for Apache.
Just press run in Xcode and you should be able to access Apache as 
[http://localhost:8042](http://localhost:8042).

### RequestInfoHandler

[RequestInfoHandler.swift](Sources/RequestInfoHandler.swift) just shows a few
properties available as part of the Apache request.
If it is invoked on behalf of a matching file in the document root,
it will also deliver the file to the browser.

### MustacheHandler

[MustacheHandler.swift](Sources/MustacheHandler.swift) loads and evaluates a 
[Mustache](http://mustache.github.io)
template sitting the Apache document root.
The handler is attached to the mustache file type using a configuration like 
this:

    <Location />
      AddType application/x-zeezide-mustache .mustache
      AddHandler de.zeezide.mustache .mustache
    </Location>

This will trigger the handler for all files ending in .mustache within the
document root.

Here is your screenshot:

<img src="../DocRoot/mod_swift-mustache-screenshot.jpg" align="center" />

and here is some code used to generate that page (shortened,
[full](Sources/MustacheHandler.swift)):

```Swift
let sampleDict  : [ String : Any ] = [
  "name"        : "Chris",
  "value"       : 10000,
  "taxed_value" : Int(10000 - (10000 * 0.4))
]

func MustacheHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  var req = ZzApacheRequest(raw: p!) // make it nicer to use
  guard req.handler == "de.zeezide.mustache" else { return DECLINED }
  
  req.contentType = "text/html; charset=ascii"
  guard let fn = req.filename else { return HTTP_NOT_FOUND }
  
  guard let template = try? String(contentsOfFile: fn) else {
    return HTTP_INTERNAL_SERVER_ERROR
  }
  req.puts(MustacheParser().parse(string: template).render(object: sampleDict))
  return OK
}
```

What this does is it loads a
[Mustache](http://mustache.github.io)
template 
[located in the Apache documents directory](../DocRoot/HelloWorld.mustache).
It then resolves the template from some Swift dictionary and returns the result
to the browser.
Note that the file lookup and all that is managed by other Apache modules,
this handler is just invoked for Mustache templates
([as configured in our apache.conf](apache.conf#L44)).

Remember that this is just a proof of concept. Quite likely you'd want some
wrapper library making the Apache API a little 'Swiftier'.
Also remember that you can use this not only to deliver dynamic content,
but you can also use it to add new authentication modules to Apache,
or write new filter modules (say one which converts XML to JSON on demand).

### Who

**mod_swift** is brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We like feedback, GitHub stars, cool contract work,
presumably any form of praise you can think of.
We don't like people who are wrong.

There is a `#mod_swift` channel on the [Noze.io Slack](http://slack.noze.io).
