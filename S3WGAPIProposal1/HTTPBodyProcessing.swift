//
//  HTTPBodyProcessing.swift
//
//  Created by Helge Hess on 30/03/17.
//

import Dispatch

public enum HTTPBodyProcessing {
  case discardBody
  case processBody(handler: HTTPBodyHandler)
}

public typealias HTTPBodyHandler = ( HTTPBodyChunk ) -> Void

public enum HTTPBodyChunk {
  case chunk  (data  : DispatchData)
  case failed (error : HTTPParserError)
  case trailer(key   : String, value : String)
  case end
}

public enum HTTPParserError: Error {
}
