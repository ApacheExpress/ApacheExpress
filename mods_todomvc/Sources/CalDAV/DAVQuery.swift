//
//  DAVQuery.swift
//  mods_todomvc
//
//  Created by Helge Hess on 10/02/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import ExExpress

/**
 * Hold all the DAV relevant parsing information.
 */
struct DAVQuery : CustomStringConvertible {
  
  enum QueryType {
    case None
    case Propfind0
    case Propfind
    case MultiGET
    case CalendarQuery
    case AddressbookQuery
    case Sync
    case Unsupported
  }
  
  var depth      : DAVDepth  = .None
  var type       : QueryType = .None
  var properties = [ ( String, String ) ]() // tuples cannot be in a set
  var allProp    = false
  var hrefs      = [ String ]()
  var syncToken  : String? = nil
  
  func isPropertySelected(ns: String, name: String) -> Bool {
    guard !allProp else { return true } // we (sh)could be more selective here
    
    // make it a Set
    for ( sns, sn ) in properties {
      guard sn  == name else { continue }
      guard sns == ns   else { continue }
      return true
    }
    return false
  }
 
  var description: String {
    var s = "<DAVQuery:"
    
    if type != .None {
      s += " \(type)"
    }
    
    if allProp { s += " ALLPROP" }
    else if !properties.isEmpty {
      s += " "
      s += properties.map { $0.1 }.joined(separator: ",")
    }
    
    if depth != .None     { s += " depth=\(depth)" }
    if let st = syncToken { s += " sync=\(st)"     }
    
    if !hrefs.isEmpty {
      s += " #hrefs=\(hrefs.count)"
    }
    
    s += ">"
    return s
  }
}

extension bodyParser { // abuse this, can't extend the bodyParser enum ...
  
  fileprivate static let davQueryKey = "de.zeezide.apache.body-parser.davQuery"
  fileprivate static let davPropPatchKey =
                           "de.zeezide.apache.body-parser.davPropPatch"

  public static func davQuery() -> Middleware {
    return { req, res, next in
      // TODO: handle errors instead of throwing? That whole throw thing is crap
      
      guard typeIs(req, [ "text/xml" ]) != nil else { return try next() }
      
      var davQuery = DAVQuery()
      davQuery.depth = req.depth
      
      switch req.method {
        case "PROPFIND":
          switch req.depth {
            case .Zero:
              davQuery.type = .Propfind0
            case .None, .Infinity:
              davQuery.depth = .Infinity // default Depth ...
              davQuery.type  = .Propfind
            case .One:
              davQuery.type  = .Propfind
          }
        
        case "REPORT":
          if req.depth == .None { davQuery.depth = .Zero }
        
        default: // not a method we scan
          return try next()
      }
      
      #if USE_PIPES // would be nice, but not quite there :-)
        let xmlParser = ApacheXMLParser()
        try req.pipe(xmlParser)
      #else
        // lame, should be streaming
        let bytes = try req.readBody()
        
        if bytes.isEmpty {
          if req.method == "PROPFIND" {
            // PROPFIND w/o content is the same like allprop
            davQuery.allProp = true
          }
          else { // invalid request, no DAV stuff to parse
            return try next()
          }
        }
        else {
          let xmlParser = ApacheXMLParser()
          try xmlParser.end(bytes)
          
          if let xmlDoc = xmlParser.document?.pointee {
            // this is very permissive

            // figure out the report
            if req.method == "REPORT" {
              if let root = xmlDoc.root?.pointee {
                let rns = xmlDoc[namespace: root.ns]
                switch ( rns, root.oName ) {
                  
                  case ( ns.CalDAV,  "calendar-multiget" ),
                       ( ns.CardDAV, "addressbook-multiget" ):
                    davQuery.type = .MultiGET
                  
                  case ( ns.CalDAV, "calendar-query" ):
                    davQuery.type = .CalendarQuery
                  
                  case ( ns.CardDAV, "addressbook-query" ):
                    davQuery.type = .AddressbookQuery
                  
                  case ( ns.DAV, "sync-collection" ):
                    davQuery.type = .Sync
                  
                  default: // invalid, throw?
                    console.error("unexpected REPORT:", "{\(rns)}\(root.oName)")
                    return try next()
                }
              }
            }
            
            if let root = xmlDoc.root?.pointee {
              // collect desired properties & hrefs
              if let prop = root.firstElementWith(name: "prop")?.pointee {
                prop.forEach { propElem in
                  let rns = xmlDoc[namespace: propElem.pointee.ns]
                  davQuery.properties.append(( rns, propElem.pointee.oName ))
                }
              }
              
              // collect hrefs
              if davQuery.type == .MultiGET {
                davQuery.hrefs = root.elementsWith(name: "href").map { href in
                  return href.pointee.cdata
                }
              }
              
              // sync-token
              if davQuery.type == .Sync {
                davQuery.syncToken =
                  root.firstElementWith(name: "sync-token")?.pointee.cdata
              }
            }
          }
          
          // TODO: extract filters for calendar/ab-query
        }
      #endif
      
      req.davQuery = davQuery
      
      try next()
    }
  }
  
}

extension IncomingMessage {
  
  var davQuery : DAVQuery? {
    set { extra[bodyParser.davQueryKey] = newValue }
    get { return extra[bodyParser.davQueryKey] as? DAVQuery }
  }

}
