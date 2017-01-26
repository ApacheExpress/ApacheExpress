//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import Foundation

public enum fs {
  
  public typealias DataCB   = ( Swift.Error?, [ UInt8 ]? ) -> Void
  public typealias StringCB = ( Swift.Error?, String?    ) -> Void
  public typealias ErrorCB  = ( Swift.Error?             ) -> Void
  
  public enum Error : Swift.Error {
    case ReadError // lame
  }
  
  public static func readFile(_ path: String, cb: DataCB) {
    guard let data = readFileSync(path) else {
      cb(Error.ReadError, nil)
      return
    }
    cb(nil, data)
  }
  
  public static func readFileSync(_ path: String) -> [ UInt8 ]? {
    do {
      let url = URL(fileURLWithPath: path)
      let data = try Data(contentsOf: url)
      
      // TODO: Yes, yes. Very lame.
      var array = [ UInt8 ](repeating: 42, count: data.count)
      _ = array.withUnsafeMutableBufferPointer { bp in
        data.copyBytes(to: bp)
      }
      return array
    }
    catch {
      return nil
    }
  }
}
