//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

// MARK: - Public API

// Note: nesting that in the http enum or extension crashes swiftc ...
public typealias RequestEventCB =
            ( IncomingMessage, ServerResponse ) throws -> Void


public enum http { // namespace
  
  open class Server { // careful, this is multithreaded in Apache
    
    // MARK: - Event Handlers
    
    final var requestListeners = [ RequestEventCB ]()
    
    open var log : ConsoleType { return console.defaultConsole }
    
    public init() {}
    
    @discardableResult
    public func onRequest(handler lcb: @escaping RequestEventCB) -> Self {
      requestListeners.append(lcb)
      return self
    }
    
    public func emitOnRequest(request  : IncomingMessage,
                              response : ServerResponse) throws
    {
      for listener in requestListeners {
        try listener(request, response)
      }
    }
  }
  
}
