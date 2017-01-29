//
//  Express.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

open class Express: SettingsHolder, MiddlewareObject, RouteKeeper {
  
  let router   = Router()
  var settings = [ String : Any ]()
  
  public init() {
    // defaults
    set("view engine", "mustache")
    engine("mustache", mustacheExpress)
    engine("html",     mustacheExpress)
  }
  
  // MARK: - MiddlewareObject
  
  public func handle(request  req : IncomingMessage,
                     response res : ServerResponse,
                     next     cb  : @escaping Next) throws
  {
    let oldApp = req.app
    let oldReq = res.request
    req.extra[appKey] = self
    res.extra[appKey] = self
    res.extra[reqKey] = req
    
    try router.handle(request: req, response: res) { _ in
      req.extra[appKey] = oldApp
      res.extra[appKey] = oldApp
      res.extra[reqKey] = oldReq
      
      // TODO: fixme
      try! cb() // continue
    }
  }
  
  // MARK: - Route Keeper
  
  public func add(route e: Route) {
    router.add(route: e)
  }
  
  // MARK: - SettingsHolder
  
  public func set(_ key: String, _ value: Any?) {
    if let v = value {
      settings[key] = v
    }
    else {
      settings.removeValue(forKey: key)
    }
  }
  
  public func get(_ key: String) -> Any? {
    return settings[key]
  }
  
  // MARK: - Engines
  
  var engines = [ String : ExpressEngine]()
  
  public func engine(_ key: String, _ engine: @escaping ExpressEngine) {
    engines[key] = engine
  }
}

private let appKey    = "io.noze.express.app"
private let reqKey    = "io.noze.express.request"
private let paramsKey = "io.noze.express.params"

public typealias ExpressEngine = (
    _ path:    String,
    _ options: Any?,
    _ done:    @escaping ( Any?... ) throws -> Void
  ) throws -> Void


// MARK: - App access helper

public extension IncomingMessage {
  
  public var app : Express? { return extra[appKey] as? Express }
  
  public var params : [ String : String ] {
    set {
      extra[paramsKey] = newValue
    }
    get {
      // TODO: should be :Any
      return (extra[paramsKey] as? [ String : String ]) ?? [:]
    }
  }
  
}
public extension ServerResponse {
  
  public var app : Express? { return extra[appKey] as? Express }
  
  public var request : IncomingMessage? {
    return extra[reqKey] as? IncomingMessage
  }
  
}

public extension Dictionary where Key : ExpressibleByStringLiteral {
  public subscript(int key : Key) -> Int? {
    guard let v = self[key] else { return nil }
    if let i = (v as? Int) { return i }
    return Int("\(v)")
  }
}
