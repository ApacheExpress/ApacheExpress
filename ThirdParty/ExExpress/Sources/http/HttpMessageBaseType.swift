//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

public protocol HttpMessageBaseType : class {

  var log   : ConsoleType      { get }
  var extra : [ String : Any ] { get set }
  
  func setHeader   (_ name: String, _ value: Any)
  func removeHeader(_ name: String)
  func getHeader   (_ name: String) -> Any?

}
