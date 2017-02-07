//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

// Basic Noze.io like stream protocols. But those in here are not
// asynchronous.
public enum streams {
  
  // TBD: protocols cannot be nested?

}

public typealias DoneCB = () throws -> Void

public protocol StreamType {
}

public protocol WritableStreamType : StreamType {
  func end() throws
}

