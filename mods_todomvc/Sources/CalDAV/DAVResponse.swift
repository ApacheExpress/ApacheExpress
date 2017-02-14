//
//  DAVResponse.swift
//  mods_todomvc
//
//  Created by Helge Hess on 10/02/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

// MARK: - DAV value objects

public enum DAVDepth {
  case Zero
  case One
  case Infinity
  case None
}

struct DAVResponse {
  
  enum Value {
    case Text(String)
    case URL(String)
    case TagSubset (String, String, [String]) // ns, tag, values
    case PropSubset(String, String, String, [String]) // ns, tag, attr, values
    case TagArray  ( [ ( String, String ) ] ) // array of (ns,tag)
    case Raw(String)
    case None
    
    init(privileges: [String]) {
      self = .TagSubset(ns.DAV, "privilege", privileges)
    }
  }
  
  let query         : DAVQuery?
  let defaultNS     : String?
  let url           : String
  var properties    = [ ( String, String, Value ) ]()
  var properties404 = [ ( String, String ) ]()
  
  init(url: String, _ defNS: String? = nil, _ props: [ String : Value ] = [:],
       query: DAVQuery? = nil)
  {
    self.url   = url
    self.query = query
    defaultNS  = defNS
    add(defaultNS ?? "", props)
  }
  
  mutating func add(_ ns: String, _ properties: [ String : Value ]) {
    for ( key, value ) in properties {
      if let query = query {
        guard query.isPropertySelected(ns: ns, name: key) else { continue }
      }
      self.properties.append( ( ns, key, value) )
    }
  }
  
  mutating func add(_ properties: [ String : Value ]) {
    let ns = defaultNS ?? ""
    for ( key, value ) in properties {
      if let query = query {
        guard query.isPropertySelected(ns: ns, name: key) else { continue }
      }
      self.properties.append( ( ns, key, value) )
    }
  }
  
  func render(to xml: XMLGenerator) {
    xml.tag(ns.DAV, "response") { xml in
      xml.tag(ns.DAV, "href", url)
      
      if !properties.isEmpty {
        xml.tag(ns.DAV, "propstat") { xml in
          xml.tag(ns.DAV, "status", "HTTP/1.1 200 OK")
          xml.tag(ns.DAV, "prop") { xml in
            for ( pns, name, value ) in properties {
              switch value {
                case .None:
                  xml.tag(pns, name)
                case .Raw(let value):
                  xml.tag(pns, name) { xml in xml.xml += value }
                case .Text(let s):
                  xml.tag(pns, name, s)
                case .URL(let url): // TODO: combine relative ones
                  xml.tag(pns, name) { xml in xml.tag(ns.DAV, "href", url) }
                
                case .TagSubset(let ns, let wrapperTag, let valueTags):
                  xml.tag(pns, name) { xml in
                    for valueTag in valueTags {
                      xml.tag(ns, wrapperTag) { xml in
                        xml.tag(ns, valueTag)
                      }
                    }
                  }
                case .PropSubset(let ns, let tag, let prop, let values):
                  xml.tag(pns, name) { xml in
                    for value in values {
                      xml.tag(ns, tag, [ prop : value ])
                    }
                  }
                case .TagArray(let tags):
                  xml.tag(pns, name) { xml in
                    for ( ns, tag ) in tags {
                      xml.tag(ns, tag)
                    }
                  }
              }
            }
          }
        }
      }
      
      if !properties404.isEmpty {
        xml.tag(ns.DAV, "propstat") { xml in
          xml.tag(ns.DAV, "status", "HTTP/1.1 404 Not Found")
          
          for ( pns, name ) in properties404 {
            xml.tag(ns.DAV, "prop") { xml in
              xml.tag(pns, name)
            }
          }
        }
      }
    }
  }
}
extension DAVResponse.Value : ExpressibleByStringLiteral  {
  public init(stringLiteral value: String) {
    self = .Text(value)
  }
  public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
    self = .Text(value)
  }
  public init(unicodeScalarLiteral value: StringLiteralType) {
    self = .Text(value)
  }
}
