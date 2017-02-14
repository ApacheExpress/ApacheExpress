//
//  ApacheXML.swift
//  mods_todomvc
//
//  Created by Helge Hess on 09/02/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

// MARK: - Apache XML Parser

import ApachePortableRuntime
import ExExpress


/**
 * Small wrapper for the XML parser included in Apache (which uses Expat).
 *
 * Usage:
 *
 *     let parser = ApacheXMLParser()
 *     try! parser.end(data)
 *     if let xmlDoc = parser.document {
 *       if let pf = xmlDoc.pointee.firstElementWith(name: "propfind") {
 *         ...
 *       }
 *     }
 */
class ApacheXMLParser : WritableByteStreamType {
  
  enum Error : Swift.Error {
    case Failed(apr_status_t, String)
  }
  
  let ownedPool : OpaquePointer?
  let handle    : OpaquePointer
  var document  : UnsafeMutablePointer<apr_xml_doc>? = nil
  
  init(pool: OpaquePointer) {
    ownedPool = nil
    handle    = apr_xml_parser_create(pool)!
  }
  init() {
    var p : OpaquePointer? = nil
    let status = apr_pool_create_ex(&p, nil, nil, nil)
    assert(status == APR_SUCCESS, "could not create APR pool \(status)")
    
    ownedPool = p
    handle    = apr_xml_parser_create(ownedPool!)!
  }
  deinit {
    if let p = ownedPool {
      apr_pool_destroy(p)
    }
  }
  
  
  // MARK: - Errors
  
  func getError(for status: apr_status_t) -> Error? {
    guard status != APR_SUCCESS else { return nil }
    
    var errbuf = Array<Int8>(repeating: 42, count: 512)
    let s : String
    if let cstr = apr_xml_parser_geterror(handle, &errbuf, errbuf.count) {
      s = String(cString: cstr)
    }
    else {
      s = "Generic error"
    }
    return Error.Failed(status, s)
  }
  
  
  // MARK: - WriteableStream
  
  func writev(buckets chunks: [ [ UInt8 ] ], done: DoneCB?) throws {
    var error : Error? = nil
    
    for chunk in chunks {
      guard !chunk.isEmpty else { continue }
      
      let status : apr_status_t = chunk.withUnsafeBufferPointer { bp in
        guard let bpa = bp.baseAddress else { return APR_ENOENT }
        return bpa.withMemoryRebound(to: Int8.self, capacity: bp.count) { p in
          return apr_xml_parser_feed(handle, p, bp.count)
        }
      }
      
      error = getError(for: status)
      if error != nil { break }
    }
    
    // hm, ordering?
    if let cb    = done  { try cb()    }
    if let error = error { throw error }
  }
  
  func end() throws {
    let status = apr_xml_parser_done(handle, &document)
    if let error = getError(for: status) { throw error }
  }
}


// MARK: - Structure Extensions

protocol ApacheXMLElementHolder {
  
  func firstElementWith(name: String) -> UnsafeMutablePointer<apr_xml_elem>?
  func elementsWith    (name: String) -> [ UnsafeMutablePointer<apr_xml_elem> ]
  func forEach(_ cb: ( UnsafeMutablePointer<apr_xml_elem> ) -> Void)
  
  var  count : Int { get }
}

extension ApacheXMLElementHolder {
  
  func firstElementAt(path: String...) -> UnsafeMutablePointer<apr_xml_elem>? {
    guard !path.isEmpty else { return nil }
    
    var cursor = firstElementWith(name: path[0]), idx = 1
    while idx < path.count && cursor != nil {
      cursor = cursor?.pointee.firstElementWith(name: path[idx])
      idx += 1
    }
    return cursor
  }
  
}


extension apr_xml_doc : ApacheXMLElementHolder {
  // Properties:
  //   root:       UnsafeMutablePointer<apr_xml_elem>!
  //   namespaces: UnsafeMutablePointer<apr_array_header_t>!
  
  var allNamespaces : [ String ] {
    guard namespaces != nil else { return [] }
    let count = Int(namespaces.pointee.nelts)
    guard count > 0 else { return [] }
    
    var values = [ String ]()
    let base = namespaces.pointee.elts
    base?.withMemoryRebound(to: UnsafePointer<UInt8>.self, capacity: count) {
      elements in
      
      for i in 0..<count {
        values.append(String(cString: elements[i]))
      }
    }
    return values
  }

  subscript(namespace ns: String) -> Int? {
    guard namespaces != nil else { return nil }
    let count = Int(namespaces.pointee.nelts)
    guard count > 0 else { return nil }
    
    let base = namespaces.pointee.elts
    return base?.withMemoryRebound(to: UnsafePointer<Int8>.self,
                                   capacity: count)
    { elements in
      
      for i in 0..<count {
        if strcmp(elements[i], ns) == 0 {
          return i
        }
      }
      
      return nil
    }
  }
  
  subscript(namespace i: Int32) -> String {
    guard namespaces != nil else { return "" }
    let count = namespaces.pointee.nelts
    guard i >= 0 && i < count else { return "" }
    
    let base = namespaces.pointee.elts
    return base!.withMemoryRebound(to: UnsafePointer<UInt8>.self,
                                   capacity: Int(count)) {
      elements in
      return String(cString: elements[Int(i)])
    }
  }
  
  
  // MARK: - Element Holder

  func firstElementWith(name: String) -> UnsafeMutablePointer<apr_xml_elem>? {
    guard let n = root?.pointee.name else { return nil }
    guard strcmp(name, n) == 0       else { return nil }
    return root
  }
  
  func elementsWith(name: String) -> [ UnsafeMutablePointer<apr_xml_elem> ] {
    return root != nil ? [ root! ] : []
  }
  
  func forEach(_ cb: ( UnsafeMutablePointer<apr_xml_elem> ) -> Void) {
    guard let root = root else { return }
    cb(root)
  }
  
  var count : Int {
    return root != nil ? 1 : 0
  }
  
}

extension apr_xml_doc : CustomStringConvertible {
  public var description : String {
    var s = "<ApXmlDoc: "
    if let root = root {
      s += " root=\(root.pointee)"
    }
    // TODO: namespaces
    s += ">"
    return s
  }
}

extension apr_xml_elem : ApacheXMLElementHolder {
  // Properties:
  //   parent          : UnsafeMutablePointer<apr_xml_elem>?
  //   next            : UnsafeMutablePointer<apr_xml_elem>?
  //   ns              : Int32
  //   ns_scope        : OpaquePointer? // struct apr_xml_ns_scope
  //   name            : UnsafePointer<Int8>?
  //   attr            : UnsafeMutablePointer<apr_xml_attr>?
  //   first_cdata     : apr_text_header
  //   following_cdata : apr_text_header
  //   first_child     : UnsafeMutablePointer<apr_xml_elem>?
  //   last_child      : UnsafeMutablePointer<apr_xml_elem>?
  
  var oName : String { return String(cString: name) }
  
  var hasChildren   : Bool { return first_child != nil }
  var hasAttributes : Bool { return attr        != nil }
  
  subscript(key: String) -> String? {
    var cursor = attr
    while cursor != nil {
      if let n = cursor?.pointee.name {
        if strcmp(key, n) == 0 {
          guard let v = cursor?.pointee.value else { return "" } // empty
          return String(cString: v)
        }
      }
      cursor = cursor?.pointee.next
    }
    return nil
  }
  
  var attributes : [ String : String ] {
    var dict = [ String : String ]()
    var cursor = attr
    while cursor != nil {
      if let n = cursor?.pointee.name {
        let on = String(cString: n)

        if let v = cursor?.pointee.value {
          dict[on] = String(cString: v)
        }
        else {
          dict[on] = ""
        }
      }
      cursor = cursor?.pointee.next
    }
    return dict
  }
  
  func firstElementWith(name: String) -> UnsafeMutablePointer<apr_xml_elem>? {
    var cursor = first_child
    while cursor != nil {
      if let n = cursor?.pointee.name {
        if strcmp(name, n) == 0 {
          return cursor
        }
      }
      cursor = cursor?.pointee.next
    }
    return nil
  }
  
  func elementsWith(name: String) -> [ UnsafeMutablePointer<apr_xml_elem> ] {
    var results = [ UnsafeMutablePointer<apr_xml_elem> ]()
    var cursor  = first_child
    while cursor != nil {
      if let n = cursor?.pointee.name {
        if strcmp(name, n) == 0 {
          results.append(cursor!)
        }
      }
      cursor = cursor?.pointee.next
    }
    return results
  }
  
  func forEach(_ cb: ( UnsafeMutablePointer<apr_xml_elem> ) -> Void) {
    var cursor = first_child
    while cursor != nil {
      cb(cursor!)
      cursor = cursor?.pointee.next
    }
  }
  
  var count : Int {
    var counter = 0, cursor = first_child
    while cursor != nil {
      counter += 1
      cursor = cursor?.pointee.next
    }
    return counter
  }
  
  var cdata : String {
    return first_cdata.stringValue
  }
  var hasCDATA : Bool {
    return first_cdata.first != nil
  }
}

extension apr_xml_elem : CustomStringConvertible {
  public var description : String {
    var s = "<ApXmlElement: \(oName)[\(ns)]"
    
    if hasAttributes {
      s += " #attrs=\(attr.pointee.count)"
    }
    if hasChildren {
      s += " #children=\(count)"
    }
    
    s += ">"
    return s
  }
}

extension apr_xml_attr {
  // Properties
  //   next  : UnsafeMutablePointer<apr_xml_attr>!
  //   name  : UnsafePointer<Int8>?
  //   ns    : Int32
  //   value : UnsafePointer<Int8>?
  
  var oName  : String { return String(cString: name)  }
  var oValue : String { return String(cString: value) }
  
  var count  : Int {
    var counter = 1
    var cursor = next
    while cursor != nil {
      counter += 1
      cursor = cursor?.pointee.next
    }
    return counter
  }
}

extension apr_text {
  // Properties
  //   text : UnsafePointer<Int8>?
  //   next : UnsafeMutablePointer<apr_text>!
  
  var stringValue : String {
    guard let t = text else { return "" }
    return String(cString: t)
  }
}

extension apr_text_header {
  // Properties
  //   first : UnsafeMutablePointer<apr_text>!
  //   last  : UnsafeMutablePointer<apr_text>!

  var stringValue : String {
    var cursor : UnsafeMutablePointer<apr_text>! = first
    guard cursor != nil else { return "" }
    
    var s = ""
    while cursor != nil {
      s += cursor.pointee.stringValue
      cursor = cursor.pointee.next
    }
    return s
  }
}


// MARK: - Small Test Func

func testXMLParser() {
  let data =
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
    "<A:propfind xmlns:A=\"DAV:\" xmlns:B=\"urn:ietf:params:xml:ns:caldav\">\n" +
    "<A:prop>\n" +
      "<A:principal-URL/>\n" +
      "<B:home/>\n" +
    "</A:prop>\n" +
    "</A:propfind>"
  
  let parser = ApacheXMLParser()
  try! parser.end(data)
  
  if let xml = parser.document {
    print("result: \(xml.pointee)")
    let ns = xml.pointee.namespaces // TODO
    print("  NS: \(ns) \(xml.pointee.allNamespaces)")
    print("    0: \(xml.pointee[namespace: 0])")
    print("    1: \(xml.pointee[namespace: 1])")
    print("  -42: \(xml.pointee[namespace: -42])")
    print("   CD: \(xml.pointee[namespace: "urn:ietf:params:xml:ns:caldav"])")
    print(" Miss: \(xml.pointee[namespace: "urn:404"])")
    
    
    if let root = xml.pointee.root {
      print("  root: \(root.pointee) \(root.pointee.attributes)")
      
      if let pf = root.pointee.firstElementWith(name: "propfind") {
        print("    pf: \(pf.pointee) \(pf.pointee.attributes)")
      }
    }
    if let props = xml.pointee.firstElementAt(path: "propfind", "prop") {
      print("props: \(props.pointee)")
      props.pointee.forEach { prop in
        print("  prop: \(prop.pointee)")
      }
    }
  }
}

