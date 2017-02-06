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
  
  func dbdAcquire() -> ZzApacheRequestDBD? {
    let ap_dbd_acquire : aprz_OFN_ap_dbd_acquire_t? =
                           APR_RETRIEVE_OPTIONAL_FN("ap_dbd_acquire")
    if ap_dbd_acquire == nil { return nil }
    guard let dbd = ap_dbd_acquire?(self.raw) else { return nil }
    
    return ZzApacheRequestDBD(request: OpaquePointer(self.raw), connection: dbd)
  }
  
}

protocol ZzDBDConnection {
  func select(_ sql: String) -> ZzDBDResults?
}

protocol ZzDBDResults {
  func next() -> ZzDBDRow?
  
  var columnCount : Int { get }
  var count       : Int { get }
}

protocol ZzDBDRow {
  subscript(raw  index: Int) -> UnsafePointer<Int8>! { get }
  subscript(     index: Int) -> String?              { get }

  subscript(name index: Int) -> String? { get }
}

class ZzApacheRequestDBD : ZzDBDConnection {
  
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

class ZzApacheRequestDBDResults : ZzDBDResults {

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

class ZzApacheRequestDBDRow : ZzDBDRow {
  
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

extension ap_dbd_t {
  
  func select(_ sql: String, _ pool: OpaquePointer,
              _ res: UnsafeMutablePointer<OpaquePointer?>!)
    -> Int32
  {
    // var res : OpaquePointer? = nil // UnsafePointer<apr_dbd_results_t>
    return apr_dbd_select(driver, pool, handle, res, sql, 0)
  }
}

