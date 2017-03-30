//
//  HTTPResponseWriter.swift
//
//  Created by Helge Hess on 30/03/17.
//

import Foundation

public enum Result<Error, Value> {
  case success(Value)
  case failure(Error)
}

public protocol HTTPResponseWriter: class {
  func writeResponse(status: HTTPResponseStatus, transferEncoding: HTTPTransferEncoding)
  
  func writeHeader(key: String, value: String)
  
  func writeTrailer(key: String, value: String)
  
  func writeBody(data: DispatchData,
                 completion: @escaping (Result<POSIXErrorCode, ()>) -> Void)
  func writeBody(data: Data,
                 completion: @escaping (Result<POSIXErrorCode, ()>) -> Void)
  
  func done(completion: @escaping (Result<POSIXErrorCode, ()>) -> Void)
  func abort()
}

public extension HTTPResponseWriter {
  
  func writeBody(data: DispatchData) {
    writeBody(data: data) { result in }
  }
  func writeBody(data: Data) {
    writeBody(data: data) { result in }
  }

  func done() {
    done() { result in }
  }
}
