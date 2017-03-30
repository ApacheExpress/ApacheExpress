//
//  ApacheResponseWriter.swift
//  mods_echo
//
//  Created by Helge Hess on 30/03/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import Foundation
import Apache2
import ZzApache

class ApacheResponseWriter : HTTPResponseWriter {
  
  var handle : OpaquePointer
  
  init(_ handle: UnsafeMutablePointer<request_rec>) {
    // yes, this is awkward, but we cannot store request_rec or ZzApache in an
    // instance variable, crashes swiftc
    self.handle = OpaquePointer(handle)
  }
  var typedHandle : UnsafeMutablePointer<request_rec> {
    return UnsafeMutablePointer<request_rec>(handle)
  }
  
  
  // MARK: - Proposal Implementation
  
  func abort() {
    fatalError("doesNotRecognize(#selector(\(#function)))")
  }
  func writeTrailer(key: String, value: String) {
    fatalError("doesNotRecognize(#selector(\(#function)))")
  }
  
  
  func writeResponse(status: HTTPResponseStatus,
                     transferEncoding: HTTPTransferEncoding)
  {
    switch status {
      case .ok:       typedHandle.pointee.status = HTTP_OK
      case .created:  typedHandle.pointee.status = HTTP_CREATED
      case .accepted: typedHandle.pointee.status = HTTP_ACCEPTED
      case .gone:     typedHandle.pointee.status = HTTP_GONE
      case .internalServerError:
                      typedHandle.pointee.status = HTTP_INTERNAL_SERVER_ERROR
      case .httpVersionNotSupported:
                      typedHandle.pointee.status = HTTP_VERSION_NOT_SUPPORTED
      
      default:
        // too lazy to do all of them
        typedHandle.pointee.status = HTTP_INTERNAL_SERVER_ERROR
    }
  }
  
  func writeHeader(key: String, value: String) {
    apr_table_set(typedHandle.pointee.headers_out, key, value)
  }
  
  func writeBody(data: DispatchData,
                 completion: @escaping (Result<POSIXErrorCode, ()>) -> Void)
  {
    guard !data.isEmpty else { completion(Result.success()); return }
    
    let th      = typedHandle
    let brigade = apr_brigade_create(th.pointee.pool,
                                     th.pointee.connection.pointee.bucket_alloc)
    
    // move stuff to brigade
    var didFail = false
    data.enumerateBytes { bp, _, stop in
      // This flushes to the filter if the internal write buffer becomes
      // too large.
      let rc = apz_fwrite(th.pointee.output_filters, brigade,
                          bp.baseAddress, apr_size_t(bp.count))
      if rc != OK {
        didFail = true
        stop    = true
      }
    }
    
    guard !didFail else {
      completion(Result.failure(POSIXError.ECANCELED)) // TODO ;->
      return
    }
    
    let rv = ap_pass_brigade(th.pointee.output_filters, brigade)
    if rv != APR_SUCCESS {
      completion(Result.failure(POSIXError.ECANCELED)) // TODO ;->
    }
    else {
      completion(Result.success())
    }
  }
  
  func writeBody(data: Data,
                 completion: @escaping (Result<POSIXErrorCode, ()>) -> Void)
  {
    guard !data.isEmpty else { completion(Result.success()); return }
    
    data.withUnsafeBytes { ( ptr : UnsafePointer<UInt8> ) in
      let bp    = UnsafeBufferPointer(start: ptr, count: data.count)
      let ddata = DispatchData(bytesNoCopy: bp,
                               deallocator: .custom(DispatchQueue.main, {}))
      writeBody(data: ddata, completion: completion)
    }
  }
  
  func done(completion: @escaping (Result<POSIXErrorCode, ()>) -> Void) {
    let th      = typedHandle
    let brigade = apr_brigade_create(th.pointee.pool,
                                     th.pointee.connection.pointee.bucket_alloc)
    
    let eof = apr_bucket_eos_create(brigade?.pointee.bucket_alloc)
    apz_brigade_insert_tail(brigade, eof)
    let rv = ap_pass_brigade(th.pointee.output_filters, brigade)
    
    if rv != APR_SUCCESS {
      completion(Result.failure(POSIXError.ECANCELED)) // TODO ;->
    }
    else {
      completion(Result.success())
    }
  }
  
}
