//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

public protocol IncomingMessage : HttpMessageBaseType {

  var httpVersion : String { get     }
  var method      : String { get set }
  var url         : String { get     }
  
  // hack, use a proper stream
  func readChunks(bufsize: Int,
                  onRead: ( UnsafeBufferPointer<UInt8> ) throws -> Void) throws

}

public extension IncomingMessage {

  public func readBody(bufsize: Int) throws -> [ UInt8 ] {
    var bytes = [ UInt8 ]()
          // TODO: If there is a content-length, reserve capacity
    
    try readChunks(bufsize: bufsize) { bp in
      bytes.append(contentsOf: bp)
    }
    return bytes
  }
  
  func readBody() throws -> [ UInt8 ] { // default args
    return try readBody(bufsize: 4096)
  }
  
  func readBodyAsString() throws -> String? {
    var body = try readBody()
    body.append(0) // oh well, yes this can be done better, but not builtin
    return String(cString: body)
  }
}


// MARK: - Playing with the Pipes (Toy Stuff, do not use)

extension IncomingMessage {
  
  @discardableResult
  public func pipe<T: WritableByteStreamType>(_ target: T) throws -> T {
    // TODO: this should be a generic Input/OutputStream thing
    // TODO: error handling?
    // TODO: presumably this shouldn't start right away, but rather wait until
    //       the whole pipe-stack is setup
    try readChunks(bufsize: 4096) { bp in
      let bucket = [ UInt8 ](bp)
      try target.writev(buckets: [ bucket ], done: nil)
    }
    
    try target.end()
    return target
  }
  
}

@discardableResult
public func |<ReadStream  : IncomingMessage,
              WriteStream : WritableByteStreamType>
             (left: ReadStream, right: WriteStream) -> WriteStream
{
  // TODO: this is toy stuff
  do {
    return try left.pipe(right)
  }
  catch (let error) {
    console.error("pipe error", error)
    return right
  }
}
