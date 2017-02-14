//
//  XMLUtilities.swift
//  mods_todomvc
//
//  Created by Helge Hess on 08/02/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

struct ns { // could be an enum : String, but that makes it harder to use
  static let DAV       = "DAV:"
  static let CalDAV    = "urn:ietf:params:xml:ns:caldav"
  static let CardDAV   = "urn:ietf:params:xml:ns:carddav"
  static let GroupDAV  = "http://groupdav.org/"
  static let CalServer = "http://calendarserver.org/ns/"
  static let MobileMe  = "http://me.com/_namespace/"
  static let ICal      = "http://apple.com/ns/ical/"
}

extension String {
  
  var xmlEscaped : String { // lame
    // there is also `apr_xml_quote_string`, but it needs a pool
    return characters.reduce("") { res, c in
      switch c {
        case "<":  return res + "&lt;"
        case ">":  return res + "&gt;"
        case "&":  return res + "&amp;"
        case "'":  return res + "&apos;"
        case "\"": return res + "&quot;"
        default:   return res + String(c)
      }
    }
  }
  
}

// Simple XML generator
final class XMLGenerator {
  // FIXME: do not collect in memory, but directly stream to response
  
  let defaultNamespace : String? = ns.DAV
  let defaultPrefixes  : [ String : String ] = [
    ns.DAV       : "",
    ns.CalDAV    : "cal",
    ns.CardDAV   : "card",
    ns.CalServer : "cs",
    ns.MobileMe  : "me",
    ns.ICal      : "ical"
  ]
  
  let preamble   = "<?xml version=\"1.0\"?>\n"
  let registerNamespaces : [ String ]
  var xml        = ""
  
  var nsCounter      : Int = 0
  var activePrefixes : [ String : String ]? = nil
  
  init(namespaces : [ String ] = []) {
    self.registerNamespaces = namespaces
  }

  func tag(_ namespace  : String? = nil, _ name : String,
           _ attributes : [ String : String ]? = nil) {
    _tag(namespace, name, attributes: attributes) { xml in }
  }
  
  func tag(_ namespace  : String? = nil,
           _ name       : String,
           _ cdata      : String)
  {
    _tag(namespace, name, attributes: nil) { xml in
      xml.xml.append(cdata.xmlEscaped)
    }
  }
  func tag(_ namespace  : String? = nil,
           _ name       : String,
           children    : ( XMLGenerator ) -> Void)
  {
    _tag(namespace, name, attributes: nil, children: children)
  }
  
  func registerDefaultNamespaces() -> [ String ] {
    guard !registerNamespaces.isEmpty else { return [] }
    if activePrefixes == nil { activePrefixes = [ String : String ]() }

    var newNamespaces = [ String ]()
    for ns in registerNamespaces {
      _ = prefixForNamespace(ns, &newNamespaces)
    }
    return newNamespaces
  }
  
  func prefixForNamespace(_ ns: String, _ newNamespaces: inout [ String ])
       -> String
  {
    let prefix : String
    
    if let ap = activePrefixes?[ns] {
      prefix = ap
    }
    else {
      if let dp = defaultPrefixes[ns] {
        prefix = dp
      }
      else {
        prefix = "ns\(nsCounter)"; nsCounter += 1
        nsCounter += 1
      }
      if activePrefixes == nil { activePrefixes = [ String : String ]() }
      activePrefixes![ns] = prefix
      newNamespaces.append(ns)
    }
    
    return prefix
  }
  
  func _tag(_ namespace : String? = nil,
            _ name      : String,
            attributes  : [ String : Any]?,
            children    : ( XMLGenerator ) -> Void = { _ in } )
  {
    var newNamespaces = [ String ]()
    
    // prepare default prefixes
    
    if xml.isEmpty { xml += preamble; xml.reserveCapacity(1024) }
    newNamespaces.append(contentsOf: registerDefaultNamespaces())
    
    // setup name
    
    let prefixedName : String
    
    if let ns = namespace {
      let prefix : String = prefixForNamespace(ns, &newNamespaces)
      prefixedName = prefix.isEmpty ? name : (prefix + ":" + name)
    }
    else {
      prefixedName = name
    }
    
    xml.append("<")
    xml.append(prefixedName)
    
    // declare namespaces
    
    for ns in newNamespaces {
      let prefix = activePrefixes?[ns] ?? ""
      if prefix == "" {
        xml.append(" xmlns=\"")
      }
      else {
        xml.append(" xmlns:")
        xml.append(prefix)
        xml.append("=\"")
      }
      xml.append(ns)
      xml.append("\"")
    }
    
    // attributes
    
    if let attributes = attributes {
      for ( name, value ) in attributes {
        xml.append(" ")
        xml.append(name)
        xml.append("=\"")
        if let s = value as? String {
          xml.append(s.xmlEscaped)
        }
        else {
          xml.append("\(value)".xmlEscaped)
        }
        xml.append("\"")
      }
    }
    
    // content
    
    xml.append(">")

    let lenBefore = xml.endIndex
    children(self)
    
    if lenBefore == xml.endIndex {
      xml.remove(at: xml.index(before: lenBefore))
      xml.append(" />")
    }
    else {
      xml.append("</")
      xml.append(prefixedName)
      xml.append(">")
    }
    
    // clear namespaces
    for ns in newNamespaces {
      _ = activePrefixes?.removeValue(forKey: ns)
    }
  }
}
