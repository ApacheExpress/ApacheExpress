//
//  CORS.swift
//  Noze.io
//
//  Created by Helge Heß on 02/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

fileprivate let defaultMethods : [ String ] = [
  "GET", "HEAD", "POST", "DELETE", "OPTIONS", "PUT", "PATCH"
]
fileprivate let defaultHeaders = [ "Accept", "Content-Type" ]

public func cors(allowOrigin  origin  : String,
                 allowHeaders headers : [ String ] = defaultHeaders,
                 allowMethods methods : [ String ] = defaultMethods,
                 handleOptions: Bool = false)
            -> Middleware
{
  return { req, res, next in
    let sHeaders = headers.joined(separator: ", ")
    let sMethods = methods.joined(separator: ",")
    
    res.setHeader("Access-Control-Allow-Origin",  origin)
    res.setHeader("Access-Control-Allow-Headers", sHeaders)
    res.setHeader("Access-Control-Allow-Methods", sMethods)
    
    if req.method == "OPTIONS" { // we handle the options
      // Note: This is off by default. OPTIONS is handled differently by the
      //       Express final handler (it passes with a 200).
      if handleOptions {
        res.setHeader("Allow", sMethods)
        res.writeHead(200)
        try res.end()
      }
      else {
        try next() // bubble up, there may be more OPTIONS stuff
      }
    }
    else {
      try next()
    }
  }
}
