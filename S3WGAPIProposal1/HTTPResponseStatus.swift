//
//  HTTPResponseStatus.swift
//
//  Created by Helge Hess on 30/03/17.
//

public enum HTTPResponseStatus {
  /* use custom if you want to use a non-standard response code or
   have it available in a (UInt, String) pair from a higher-level web 
   framework. */
  case custom(code: UInt, reasonPhrase: String)
  
  /* all the codes from http://www.iana.org/assignments/http-status-codes */
  case `continue`
  case switchingProtocols
  case processing
  case ok
  case created
  case accepted
  case nonAuthoritativeInformation
  case noContent
  case resetContent
  case partialContent
  case multiStatus
  case alreadyReported
  case imUsed
  case multipleChoices
  case movedPermanently
  case found
  case seeOther
  case notModified
  case useProxy
  case temporaryRedirect
  case permanentRedirect
  case badRequest
  case unauthorized
  case paymentRequired
  case forbidden
  case notFound
  case methodNotAllowed
  case notAcceptable
  case proxyAuthenticationRequired
  case requestTimeout
  case conflict
  case gone
  case lengthRequired
  case preconditionFailed
  case payloadTooLarge
  case uriTooLong
  case unsupportedMediaType
  case rangeNotSatisfiable
  case expectationFailed
  case misdirectedRequest
  case unprocessableEntity
  case locked
  case failedDependency
  case upgradeRequired
  case preconditionRequired
  case tooManyRequests
  case requestHeaderFieldsTooLarge
  case unavailableForLegalReasons
  case internalServerError
  case notImplemented
  case badGateway
  case serviceUnavailable
  case gatewayTimeout
  case httpVersionNotSupported
  case variantAlsoNegotiates
  case insufficientStorage
  case loopDetected
  case notExtended
  case networkAuthenticationRequired
}
