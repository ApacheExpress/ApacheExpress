//
//  DatabaseAPI.swift
//  mods_baredemo
//
//  Created by Helge Hess on 05/02/2017.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import ZzApache
import Apache2
import ApachePortableRuntime

// apr_dbd_results_t is opaque

extension ZzApacheRequest {
  
  // Note: func types with UnsafeMutablePointer<request_rec>? coredump swiftc
  // own typealias w/o request_rec
  fileprivate typealias aprz_OFN_ap_dbd_acquire_t = @convention(c)
    ( UnsafeMutableRawPointer? ) -> UnsafeMutablePointer<ap_dbd_t>?
  
  func dbdAcquire() -> ZzDBDConnection? {
    let ap_dbd_acquire : aprz_OFN_ap_dbd_acquire_t? =
                           APR_RETRIEVE_OPTIONAL_FN("ap_dbd_acquire")
    if ap_dbd_acquire == nil { return nil }
    guard let dbd = ap_dbd_acquire?(self.raw) else { return nil }
    
    return ZzApacheRequestDBD(request: OpaquePointer(self.raw), connection: dbd)
  }
  
}


// MARK: - Generic Interfaces

protocol ZzDBDConnection {
  func select(_ sql: String) -> ZzDBDResults?
}

protocol ZzDBDResults { // this does not fly: ": IteratorProtocol {"
  
  func next() -> ZzDBDRow?
  
  var columnCount : Int { get }
  var count       : Int { get }
}

protocol ZzDBDRow {
  
  /**
   * Return a raw C pointer for the result of the given column index.
   */
  subscript(raw  index: Int) -> UnsafePointer<Int8>! { get }
  
  /**
   * Return the column as a String.
   */
  subscript(index: Int) -> String? { get }

  /**
   * Lookup a column by name, return value as String.
   */
  subscript(name index: Int) -> String? { get }
}


// MARK: - Typesafe Wrapper

/**
 * The core idea is that SQL does return typesafe tuples as per select. What if
 * we could use generics to expand to exactly that:
 * Summary: I don't think it is possible as we can't reflect on the type? Well?
 *          We could provide multiple signatures? select<T1,T2,T3,T4>
 *
 * This is what I'd want:
 *
 *     db.select<(Int,String,String)>
 *         ("SELECT id::int,name::text,login::text FROM account")
 *     { tuple in ... }
 *
 * or if we have a model
 *
 *     db.select(Attr.ID, Attr.Name, Attr.Login) { tuple in }
 *
 */

protocol ZzDBDValueConvertible {
  static func from(rawDBValue: UnsafePointer<Int8>?) -> Self
}
extension String : ZzDBDValueConvertible {
  static func from(rawDBValue: UnsafePointer<Int8>?) -> String {
    guard let cstr = rawDBValue else { fatalError("DB type mismatch") }
    return String(cString: cstr)
  }
}
extension Int : ZzDBDValueConvertible {
  static func from(rawDBValue: UnsafePointer<Int8>?) -> Int {
    guard let v = Int(String.from(rawDBValue: rawDBValue)) else {
      fatalError("DB type mismatch")
    }
    return v
  }
}
extension Optional where Wrapped : ZzDBDValueConvertible {
  // this is not picked
  // For this: you’ll need conditional conformance. Swift 4, hopefully
  static func from(rawDBValue: UnsafePointer<Int8>?) -> Optional<Wrapped> {
    guard let raw = rawDBValue else { return .none }
    return Wrapped.from(rawDBValue: raw)
  }
}
extension Optional : ZzDBDValueConvertible {
  static func from(rawDBValue v: UnsafePointer<Int8>?) -> Optional<Wrapped> {
    guard let c = Wrapped.self as? ZzDBDValueConvertible.Type
     else { return nil }
    
    return c.from(rawDBValue: v) as? Wrapped
  }
}

extension ZzDBDConnection {
  // Note: there would need to be one func for each argument-count (I think)

  /**
   * Select columns in a type-safe way.
   *
   * Example, not how the type is derived from what the closure expects:
   *
   *     dbd.select("SELECT * FROM pets") { (name : String, count : Int?) in
   *       req.puts("<li>\(name) (\(count))</li>")
   *     }
   */
  func select<T0, T1>(_ sql: String, cb : ( T0, T1 ) -> Void)
         where T0 : ZzDBDValueConvertible, T1 : ZzDBDValueConvertible
  {
    guard let results = select(sql) else { return }
    
    while let result = results.next() {
      cb(T0.from(rawDBValue: result[raw: 0]),
         T1.from(rawDBValue: result[raw: 1]))
    }
  }
  
}


// MARK: - Model Based Typesafe Wrapper

struct Attribute<T: ZzDBDValueConvertible> {
  
  let name : String
  
  func from(rawDBValue: UnsafePointer<Int8>?) -> T {
    // This is not strictly necessary, but a 'real' attribute class may want to
    // transform the value somehow.
    return T.from(rawDBValue: rawDBValue)
  }
}

extension ZzDBDConnection {

  /**
   * The idea here is that you rarely want to select full tables aka models.
   * E.g. you may just want to have the first & lastname of a Person. Yet,
   * we still want to use strongly typed data on the client side.
   *
   * Example:
   *
   *     struct Model {
   *       struct Pet {
   *         static let name  = Attribute<String>(name: "name")
   *         static let count = Attribute<Int>   (name: "count")
   *       }
   *     }
   *     dbd.select(Model.Pet.name, Model.Pet.count, from: "pets") { 
   *       name, count in // types are derived from Attribute
   *       req.puts("<tr><td>\(name)</td><td>\(count)</td></tr>")
   *     }
   */
  func select<T0, T1>(_ a0: Attribute<T0>, _ a1: Attribute<T1>,
                      from: String, where w: String? = nil,
                      cb: ( T0, T1 ) -> Void)
  {
    var sql = "SELECT \(a0.name), \(a1.name) FROM \(from)"
    if let w = w { sql += " WHERE \(w)" }
    
    guard let results = select(sql) else { return }
    
    while let result = results.next() {
      cb(a0.from(rawDBValue: result[raw: 0]),
         a1.from(rawDBValue: result[raw: 1]))
    }
  }
  
}


// MARK: - Apache Connection

fileprivate class ZzApacheRequestDBD : ZzDBDConnection {
  
  let req : OpaquePointer // request_rec
  let con : UnsafeMutablePointer<ap_dbd_t>
  
  init(request: OpaquePointer, connection: UnsafeMutablePointer<ap_dbd_t>) {
    req = request
    con = connection
  }

  var pool : OpaquePointer {
    return UnsafeMutablePointer<request_rec>(req).pointee.pool
  }
  
  func select(_ sql: String) -> ZzDBDResults? {
    var res : OpaquePointer? = nil // UnsafePointer<apr_dbd_results_t>
    
    let rc = apr_dbd_select(con.pointee.driver, pool, con.pointee.handle,
                            &res, sql, 0)
    guard rc == APR_SUCCESS, res != nil else { return nil }
    
    return ZzApacheRequestDBDResults(request: req, connection: con,
                                     results: res!)
  }
  
  func message(for error: Int32) -> String? {
    let cstr = apr_dbd_error(con.pointee.driver, con.pointee.handle, error)
    return cstr != nil ? String(cString: cstr!) : nil
  }
}

fileprivate class ZzApacheRequestDBDResults : ZzDBDResults {

  let req : OpaquePointer // request_rec
  let con : UnsafeMutablePointer<ap_dbd_t>
  let res : OpaquePointer
  
  init(request: OpaquePointer, connection: UnsafeMutablePointer<ap_dbd_t>,
       results: OpaquePointer)
  {
    req = request
    con = connection
    res = results
  }
  
  var pool : OpaquePointer {
    return UnsafeMutablePointer<request_rec>(req).pointee.pool
  }
  
  func next() -> ZzDBDRow? {
    var row : OpaquePointer? = nil // UnsafePointer<apr_dbd_row_t>
    let rc  = apr_dbd_get_row(con.pointee.driver, pool, res, &row, -1)
    guard rc == APR_SUCCESS, row != nil else { return nil }
    
    return ZzApacheRequestDBDRow(connection: con, row: row!)
  }
  
  var columnCount : Int {
    return Int(apr_dbd_num_cols(con.pointee.driver, res))
  }
  var count : Int {
    return Int(apr_dbd_num_tuples(con.pointee.driver, res))
  }
}

fileprivate class ZzApacheRequestDBDRow : ZzDBDRow {
  
  let con : UnsafeMutablePointer<ap_dbd_t>
  let row : OpaquePointer // UnsafePointer<apr_dbd_row_t>
  
  init(connection: UnsafeMutablePointer<ap_dbd_t>, row: OpaquePointer) {
    self.con = connection
    self.row = row
  }
  
  subscript(raw index: Int) -> UnsafePointer<Int8>! {
    return apr_dbd_get_entry(con.pointee.driver, row, Int32(index))
  }
  subscript(index: Int) -> String? {
    guard let cstr = self[raw: index] else { return nil }
    return String(cString: cstr)
  }

  subscript(name index: Int) -> String? {
    /* this aborts with SQlite, instead of returning nil?
    guard let cstr = apr_dbd_get_name(con.pointee.driver, row, Int32(index))
     else { return nil }
    print("cstr: \(cstr)")
    Darwin.puts(cstr)
    return String(cString: cstr)
     */
    return nil
  }
}


// MARK: - Extensions to the Raw API

extension ap_dbd_t {
  
  func select(_ sql: String, _ pool: OpaquePointer,
              _ res: UnsafeMutablePointer<OpaquePointer?>!)
    -> Int32
  {
    // var res : OpaquePointer? = nil // UnsafePointer<apr_dbd_results_t>
    return apr_dbd_select(driver, pool, handle, res, sql, 0)
  }
}

