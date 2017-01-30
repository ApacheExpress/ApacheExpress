//
//  Mustache.swift
//  Noze.io
//
//  Created by Helge Hess on 02/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import mustache

let mustacheExpress : ExpressEngine = { path, options, done in
  guard let template = fs.readFileSync(path, "utf8") else {
    return try done(fs.Error.ReadError)
  }
  
  let parser = MustacheParser()
  let tree   = parser.parse(string: template)
  
  let ctx = ExpressMustacheContext(path: path, object: options)
  
  var renderError : Error? = nil
  tree.render(inContext: ctx) { result in
    do {
      try done(nil, result)
    }
    catch (let error) {
      renderError = error
    }
  }
  if renderError != nil { throw renderError! }
}

fileprivate class ExpressMustacheContext : MustacheDefaultRenderingContext {
  
  let viewPath : String
  
  init(path p: String, object root: Any?) {
    self.viewPath = path.dirname(p)
    super.init(root)
  }
  
  override func retrievePartial(name n: String) -> MustacheNode? {
    let ext         = ".mustache"
    let partialPath = viewPath + "/" + (n.hasSuffix(ext) ? n : (n + ext))
    
    guard let template = fs.readFileSync(partialPath, "utf8") else {
      console.error("could not load partial: \(n): \(partialPath)")
      return nil
    }
    
    let parser = MustacheParser()
    let tree   = parser.parse(string: template)
    return tree
  }
  
}


// Dirutil helper

import func Darwin.dirname

enum path {
  
  static func dirname(_ p: String) -> String {
    return p.withCString { cstr in
      let mp = UnsafeMutablePointer(mutating: cstr)
      return String(cString: Darwin.dirname(mp)) // wrong on Linux
    }
  }
  
}
