//
//  WebDAVUtilities.swift
//  mods_todomvc
//
//  Created by Helge Hess on 08/02/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

// WebDAV extensions for Express

import ExExpress // Not Apache specific!


let davConformance = [ // yeah, we lie a little ;->
  "1", "2", "3", "calendar-access", "addressbook"
]
let allowedMethods = [
  "DELETE", "HEAD", "GET", "PUT",
  "OPTIONS", "PROPFIND", "PROPPATCH", "REPORT"
]

protocol ETaggable {
  var etag : String { get } // technically an array
}
protocol CTaggable {
  var ctag : String { get }
}
extension CTaggable {
  var syncTokenBaseURL : String {
    return "http://mod-swift.org/sync-token/todomvc/"
  }
  var syncToken : String { return syncTokenBaseURL + ctag }
}


// MARK: - DAV HTTP Headers and such

extension IncomingMessage {
  
  var depth : DAVDepth {
    guard let value = getHeader("depth") as? String else { return .None }
    switch value {
      case "0":        return .Zero
      case "1":        return .One
      case "infinity": return .Infinity
      default:         return .None
    }
  }
  
  var isTextCalendarRequest : Bool {
    if accepts("text/calendar") != nil { return true }
    
    // Unfortunately clients SUCK and do not set what they expect! This is SO
    // embarrassing and annoying, especially for companies which at least used
    // to have a standing for open standards. Oh my.
    return isCalendarAgent || isDataAccessDaemon
  }
  
  var isCalendarAgent : Bool {
    guard let ua = getHeader("User-Agent") as? String else { return false }
    return ua.contains("CalendarAgent/")
  }
  
  var isDataAccessDaemon : Bool {
    guard let ua = getHeader("User-Agent") as? String else { return false }
    return ua.contains("dataaccessd/")
  }
}

extension ServerResponse {
  
  func send(_ responses: [ DAVResponse ]) throws {
    // FIXME: stream instead ...
    if canAssignContentType {
      status(207)
      setHeader("Content-Type", "text/xml; charset=utf-8")
    }
    
    let xml = XMLGenerator(namespaces: [ ns.DAV, ns.CalDAV ])
    xml.tag(ns.DAV, "multistatus") { xml in
      for response in responses {
        response.render(to: xml)
      }
    }
    xml.xml += "\n"
    
    try self.end(xml.xml)
  }
 
  func sendInvalidSyncToken() throws {
    let xml = "<error xmlns='DAV:'><valid-sync-token/></error>"
    status(403)
    setHeader("Content-Type", "text/xml; charset=utf-8")
    try self.end(xml)
  }
}


// MARK: - Routing Extensions

public extension RouteKeeper {
  
  @discardableResult
  public func propfind0(_ p: String, _ cb: @escaping Middleware) -> Self {
    return propfind(p, .Zero, cb)
  }
  @discardableResult
  public func propfind1(_ p: String, _ cb: @escaping Middleware) -> Self {
    return propfind(p, .One, cb)
  }
  
  @discardableResult
  public func propfind(_ p: String, _ depth: DAVDepth? = nil,
                       _ cb: @escaping Middleware) -> Self
  {
    if let depth = depth {
      add(route: Route(pattern: p, method: "PROPFIND", middleware: [
        { req, res, next in
          guard req.depth == depth else { return try next() }
          try cb(req, res, next)
        }
      ]))
    }
    else {
      add(route: Route(pattern: p, method: "PROPFIND", middleware: [cb]))
    }
    return self
  }
  
  @discardableResult
  public func proppatch(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "PROPPATCH", middleware: [cb]))
    return self
  }
  
  @discardableResult
  public func report(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "REPORT", middleware: [cb]))
    return self
  }
  
  @discardableResult
  public func options(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "OPTIONS", middleware: [cb]))
    return self
  }
  
}
