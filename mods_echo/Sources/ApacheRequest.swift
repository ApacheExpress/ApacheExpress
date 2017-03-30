//
//  ApacheRequest.swift
//  mods_echo
//
//  Created by Helge Hess on 30/03/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import Apache2
import ZzApache

func ApacheRequest(_ handle: UnsafeMutablePointer<request_rec>) -> HTTPRequest {
  
  // derive method
  
  let method : HTTPMethod
  switch handle.pointee.method_number {
    case M_GET    : method = .GET
    case M_POST   : method = .POST
    case M_PUT    : method = .PUT
    case M_DELETE : method = .DELETE
    
    default:
      if strcmp(handle.pointee.method, "HEAD") == 0 {
        method = .HEAD // Hm?
      }
      else {
        method = .PURGE // too lazy to do them all
      }
  }
  
  let target = String(cString: handle.pointee.unparsed_uri)

  // Protocol version number of protocol; 1.1 = 1001
  
  let version : HTTPVersion = ( Int(handle.pointee.proto_num) / 1000,
                                Int(handle.pointee.proto_num) % 1000 )
  
  // transfer headers
  
  var original = [ ( String, String ) ]()
  var storage  = [ String : [ String ] ]()
  
  if let elements = apr_table_elts(handle.pointee.headers_in) {
    let count = Int(elements.pointee.nelts)

    if count > 0 {
      original.reserveCapacity(count)
    
      let ptr = UnsafeRawPointer(elements.pointee.elts)!
      var tptr = ptr.assumingMemoryBound(to: apr_table_entry_t.self)
      
      for _ in 0..<count {
        let key   = String(cString: tptr.pointee.key)
        let value = String(cString: tptr.pointee.val)
        original.append(key, value)
        
        let lowerKey = key.lowercased()
        if var values = storage[lowerKey] {
          values.append(value)
          storage[lowerKey] = values
        }
        else {
          storage[lowerKey] = [ value ]
        }
        
        tptr = tptr.advanced(by: 1)
      }
    }
  }
  
  
  // return result
  
  return HTTPRequest(method: method, target: target,
                     httpVersion: version,
                     headers: HTTPHeaders(storage: storage, original: original))
}
