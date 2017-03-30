//
//  HTTPHeaders.swift
//
//  Created by Helge Hess on 30/03/17.
//

public enum HTTPTransferEncoding {
  case identity(contentLength: UInt)
  case chunked
}

public struct HTTPHeaders : Sequence, CustomStringConvertible {
  
  private let storage  : [ String : [ String ] ]  // lower keys
  private let original : [ ( String, String ) ]   // original keys
  
  init(storage: [ String : [ String ] ], original: [ ( String, String ) ]) {
    self.storage  = storage
    self.original = original
  }
  
  public  var description : String { return original.description }
  
  public subscript(key: String) -> [ String ] {
    return storage[key] ?? []
  }
  
  public func makeIterator() -> IndexingIterator<Array<(String, String)>> {
    return original.makeIterator()
  }
  
}
