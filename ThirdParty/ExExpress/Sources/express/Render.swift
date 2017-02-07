//
//  Render.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension ServerResponse {
  
  public func render(_ template: String, _ options : Any? = nil) throws {
    let res = self
    
    guard let app = self.app else {
      console.error("No app object assigned to response: \(self)")
      res.writeHead(500)
      try res.end()
      return
    }
    
    let viewEngine = (app.get("view engine") as? String) ?? "mustache"
    guard let engine = app.engines[viewEngine] else {
      console.error("Did not find view engine: \(viewEngine)")
      res.writeHead(500)
      try res.end()
      return
    }
    
    let viewsPath      = app.viewDirectory(for: viewEngine, response: self)
    let emptyOpts      : [ String : Any ] = [:]
    let appViewOptions = app.get("view options") ?? emptyOpts
    let viewOptions    = options ?? appViewOptions // TODO: merge if possible
    
    try lookupTemplate(views: viewsPath, template: template,
                       engine: viewEngine) {
      pathOrNot in
                        
      guard let path = pathOrNot else {
        res.writeHead(404)
        try res.end()
        return
      }
      
      try engine(path, viewOptions) { results in
        let rc = results.count
        let v0 = rc > 0 ? results[0] : nil
        let v1 = rc > 1 ? results[1] : nil
        
        if let error = v0 {
          console.error("template error: \(error)")
          res.writeHead(500)
          try res.end()
          return
        }
        
        guard let result = v1 else {
          console.warn("template returned no content: \(template) \(results)")
          res.writeHead(204)
          try res.end()
          return
        }

        // TBD: maybe support a stream as a result? (result.pipe(res))
        let s = (result as? String) ?? "\(result)"
        
        if res.getHeader("Content-Type") == nil {
          res.setHeader("Content-Type", "text/html; charset=utf-8")
        }
        
        res.writeHead(200)
        try res.write(s)
        try res.end()
      }
    }
  }
  
}

private func lookupTemplate(views p: String, template t: String,
                            engine e: String,
                            _ cb: ( String? ) throws -> Void) throws
{
  // TODO: try other combos
  let fsPath = "\(p)/\(t).\(e)"
  
  var error : Error? = nil
  
  // TODO: hack-adjust for Apache/throws
  fs.stat(fsPath) { err, stat in
    do {
      guard err == nil && stat != nil else {
        console.error("did not find template \(t) at \(fsPath)")
        try cb(nil)
        return
      }
      guard stat!.isFile() else {
        console.error("template path is not a file: \(fsPath)")
        try cb(nil)
        return
      }
      try cb(fsPath)
    }
    catch (let thrownError) {
      error = thrownError
    }
  }
  
  if error != nil { throw error! }
}

// Some protocol is implemented in Foundation, requiring this.
import Foundation
