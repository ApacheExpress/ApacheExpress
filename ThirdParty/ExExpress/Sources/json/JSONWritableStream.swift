//
//  JSONStream.swift
//  Noze.io
//
//  Created by Helge Hess on 10/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

fileprivate struct buckets {
  static let quote       :  [ UInt8 ]  =  [ 34 ]  // "
}
fileprivate struct brigades {
  static let arrayOpen  : [[ UInt8 ]] = [[  91,  32 ]] // [
  static let arrayClose : [[ UInt8 ]] = [[  32,  93 ]] // ]
  static let dictOpen   : [[ UInt8 ]] = [[ 123,  32 ]] // {
  static let dictClose  : [[ UInt8 ]] = [[  32, 125 ]] // }
  static let comma      : [[ UInt8 ]] = [[  44,  32 ]] // ,
  static let colon      : [[ UInt8 ]] = [[  58,  32 ]] // :
  static let jtrue      : [[ UInt8 ]] = [[ 116, 114, 117, 101       ]] // true
  static let jfalse     : [[ UInt8 ]] = [[ 102,  97, 108, 115, 101  ]] // false
  static let jnull      : [[ UInt8 ]] = [[ 110, 117, 108, 108       ]] // null
}

// Well, yes. :-) This is all due to generic-protocols-are-not-a-type. We might
// want to define the methods on both, but then we can end up with ambiguities
// as many objects do implement both?!
//
// public extension GWritableStreamType where WriteType == UInt8 {}
public extension WritableByteStreamType {

  // MARK: - JSON generator

  public func writeJSON(string s: String) throws {
    let utf8 = s.utf8
    
    // Well, in theory we could directly escape into the target buffer? No
    // need to copy? Oh well, all the copying ...
    var bucket = [ UInt8 ]()
    bucket.reserveCapacity(utf8.count + 1)
    
    // Naive, Naive, make much faster
    for c in utf8 {
      let quote : Bool
      var cc    : UInt8 = c
      
      switch c {
        case 0x22: quote = true
        case 0x5C: quote = true
        // case 0x2F: quote = true // /
        case 0x08: quote = true; cc = 0x62 // b
        case 0x0C: quote = true; cc = 0x66 // f
        case 0x0A: quote = true; cc = 0x6E // n
        case 0x0D: quote = true; cc = 0x72 // r
        case 0x09: quote = true; cc = 0x74 // t
        // TBD: %x75 4HEXDIG )  ; uXXXX                U+XXXX
        default:   quote = false
      }
      
      if quote { bucket.append(92 /* \ */) }
      bucket.append(cc)
    }
  
    try writev(buckets: [ buckets.quote, bucket, buckets.quote ], done: nil)
  }
  
  public func writeJSON(object o: JSON) throws {
    // FIXME: This should be an on-demand stream
    
    switch o {
      case .Int   (let v): try write("\(v)")
      case .String(let v): try writeJSON(string: v)
      
      case .Array(let children):
        try writev(buckets: brigades.arrayOpen, done: nil)
        do {
          var isFirst = true
          for child in children {
            if isFirst { isFirst = false }
            else { try writev(buckets: brigades.comma, done: nil) }
              
            try writeJSON(object: child)
          }
        }
        try  writev(buckets: brigades.arrayClose, done: nil)
      
      case .Dictionary(let object):
        try  writev(buckets: brigades.dictOpen, done: nil)
        do {
          var isFirst = true
          for ( key, child ) in object {
            if isFirst { isFirst = false }
            else { try  writev(buckets: brigades.comma, done: nil) }
            
            try writeJSON(string: key)
            try  writev(buckets: brigades.colon, done: nil)
            
            try writeJSON(object: child)
          }
        }
        try  writev(buckets: brigades.dictClose, done: nil)
      
      case .Double(let v):
        try  write("\(v)") // FIXME: quite likely wrong
          
      case .Bool(let v):
        try  writev(buckets: v ? brigades.jtrue : brigades.jfalse, done: nil)
          
      case .Null:
        try  writev(buckets: brigades.jnull, done: nil)
    }
  }
  
}

// MARK: - Need more JSONEncodable

extension Array: JSONEncodable {
  
  public func toJSON() -> JSON {
    let arrayOfJSON : [ JSON ] = self.map { v in
      if let jsonValue = (v as? JSONEncodable) {
        return jsonValue.toJSON()
      }
      else { // hm, hm
        return String(describing: v).toJSON()
      }
    }
    return .Array(arrayOfJSON)
  }
}

extension Dictionary: JSONEncodable { // hh
  
  public func toJSON() -> JSON {
    var jsonDictionary = [String: JSON]()
    
    for (k, v) in self {
      let key = (k as? String) ?? String(describing: k)
      
      if let jsonValue = (v as? JSONEncodable) {
        jsonDictionary[key] = jsonValue.toJSON()
      }
      else {
        jsonDictionary[key] = String(describing: v).toJSON()
      }
    }
    
    return .Dictionary(jsonDictionary)
  }
  
}
