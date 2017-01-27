//
//  JSON.swift
//  Noze.io
//
//  Created by Helge Heß on 6/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension ServerResponse {
  // TODO: add jsonp
  // TODO: be a proper stream
  // TODO: Maybe we don't want to convert to a `JSON`, but rather stream real
  //       object.
  
  public func json(_ object: JSON) throws {
    if canAssignContentType {
      setHeader("Content-Type", "application/json; charset=utf-8")
    }
    try writeJSON(object: object)
    end()
  }
}


// MARK: - Helpers

public extension ServerResponse {

  public func json(_ object: JSONEncodable) throws {
    try json(object.toJSON())
  }
  
  public func json(_ object: Any?) throws {
    if let o = object {
      if let jsonEncodable = (o as? JSONEncodable) {
        try json(jsonEncodable)
      }
      else {
        try json(String(0))
      }
    }
    else {
      try json(.Null)
    }
  }
}

