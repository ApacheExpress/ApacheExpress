//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

// Note: nesting that in the http enum or extension crashes swiftc ...
public typealias RequestEventCB =
            ( IncomingMessage, ServerResponse ) throws -> Void

public extension http {
  
  public class Server { // careful, this is multithreaded!
    
    // MARK: - Event Handlers
    
    final var requestListeners = [ RequestEventCB ]()
    
    public var log : ConsoleType { return console.defaultConsole }
    
    @discardableResult
    public func onRequest(handler lcb: @escaping RequestEventCB) -> Self {
      requestListeners.append(lcb)
      return self
    }
    
    func emitOnRequest(request: IncomingMessage, response: ServerResponse)
         throws
    {
      for listener in requestListeners {
        try listener(request, response)
      }
    }
  }
  
}

// MARK: - Private API

import Apache2

public extension http_internal { // hm, public internal? :-)
  
  public final class ApacheServer : http.Server {
    
    let handle : UnsafePointer<server_rec>
    let apLog  : ConsoleType
    
    public init(handle: UnsafePointer<server_rec>) {
      self.handle = handle
      apLog = ApacheConsole(server: handle)
    }
    
    public override var log : ConsoleType { return apLog }
  }
}
