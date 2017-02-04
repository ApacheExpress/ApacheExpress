//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import ZzApache
import Apache2

import mustache

let sampleDict  : [ String : Any ] = [
  "name"        : "Chris",
  "value"       : 10000,
  "taxed_value" : Int(10000 - (10000 * 0.4)),
  "in_ca"       : true,
  "addresses"   : [
    [ "city"    : "Cupertino" ],
    [ "city"    : "Mountain View" ]
  ]
]

func MustacheHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  var req = ZzApacheRequest(raw: p!) // var because we set the contentType
  
  // We only handle this 'handler key' (added using AddHandler for the
  // .mustache extension in the apache.conf).
  guard req.handler == "de.zeezide.mustache" else { return DECLINED }

  // fix out MIME type
  req.contentType = "text/html; charset=ascii"
  
  // check whether the file got resolved, else return 404
  guard let fn = req.filename else { return HTTP_NOT_FOUND }

  // load file
  guard let template = try? String(contentsOfFile: fn) else {
    print("could not load template?!")
    return HTTP_INTERNAL_SERVER_ERROR
  }
  
  // parse file
  let parser = MustacheParser()
  let tree   = parser.parse(string: template)
  
  // build object to render, we could use sampleDict, but we want to add stuff
  var object = sampleDict
  object["filename"] = fn
  object["template"] = template
  
  // render template into String (a little more complex for partial support)
  let ctx = ApacheMustacheContext(path: fn, object: object)
  tree.render(inContext: ctx)
  
  // send render template to client
  req.puts(ctx.string)
  
  return OK
}


// A Mustache rendering context which looks up partials relative to a path
class ApacheMustacheContext : MustacheDefaultRenderingContext {
  
  let viewPath : String
  
  init(path p: String, object root: Any?) {
    viewPath = path.dirname(p)
    super.init(root)
  }
  
  override func retrievePartial(name n: String) -> MustacheNode? {
    let ext         = ".mustache"
    let partialPath = viewPath + "/" + (n.hasSuffix(ext) ? n : (n + ext))
    
    guard let template = try? String(contentsOfFile: partialPath) else {
      // TODO: use Apache error logger
      print("ERROR: could not load partial: \(n): \(partialPath)")
      return nil
    }
    
    let parser = MustacheParser()
    let tree   = parser.parse(string: template)
    return tree
  }
}


// Dirutil helper

#if os(Linux)
  import func Glibc.dirname
#else
  import func Darwin.dirname
#endif

enum path {

  static func dirname(_ p: String) -> String {
    return p.withCString { cstr in
      let mp = UnsafeMutablePointer(mutating: cstr)
      #if os(Linux)
        return String(cString: Glibc.dirname(mp)) // wrong on Linux
      #else
        return String(cString: Darwin.dirname(mp)) // wrong on Linux
      #endif
    }
  }
  
}
