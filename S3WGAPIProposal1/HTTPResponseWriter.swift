//
//  HTTPResponseWriter.swift
//
//  Created by Helge Hess on 30/03/17.
//

import Foundation

public struct Result<ET, VT> {
  let error : ET
  let value : VT
}

public protocol HTTPResponseWriter: class {
  func writeResponse(status: HTTPResponseStatus, transferEncoding: HTTPTransferEncoding)
  
  func writeHeader(key: String, value: String)
  
  func writeTrailer(key: String, value: String)
  
  func writeBody(data: DispatchData) /* convenience */
  func writeBody(data: Data) /* convenience */
  func writeBody(data: DispatchData, completion: @escaping (Result<POSIXError, ()>) -> Void)
  func writeBody(data: Data, completion: @escaping (Result<POSIXError, ()>) -> Void)
  
  func done() /* convenience */
  func done(completion: @escaping (Result<POSIXError, ()>) -> Void)
  func abort()
}
