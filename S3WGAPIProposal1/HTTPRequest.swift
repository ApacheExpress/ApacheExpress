//
//  HTTPRequest.swift
//
//  Created by Helge Hess on 30/03/17.
//

public typealias HTTPVersion = ( Int, Int )

public struct HTTPRequest {
  public let method      : HTTPMethod
  public let target      : String /* e.g. "/foo/bar?buz=qux" */
  public let httpVersion : HTTPVersion
  public let headers     : HTTPHeaders
}
