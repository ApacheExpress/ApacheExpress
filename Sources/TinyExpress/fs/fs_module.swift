//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

import Darwin
import Foundation

public enum fs {
  
  public typealias DataCB   = ( Swift.Error?, [ UInt8 ]? ) -> Void
  public typealias StringCB = ( Swift.Error?, String?    ) -> Void
  public typealias ErrorCB  = ( Swift.Error?             ) -> Void
  
  public enum Error : Swift.Error {
    case ReadError // lame
    case StatError // lame
  }
  
  public static func readFile(_ path: String, cb: DataCB) {
    guard let data = readFileSync(path) else {
      cb(Error.ReadError, nil)
      return
    }
    cb(nil, data)
  }
  public static func readFile(_ path: String, _ enc: String, cb: StringCB) {
    guard let data = readFileSync(path, enc) else {
      cb(Error.ReadError, nil)
      return
    }
    cb(nil, data)
  }
  
  public static func readFileSync(_ path: String) -> [ UInt8 ]? {
    do {
      let url  = Foundation.URL(fileURLWithPath: path)
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
  
  public static func readFileSync(_ path: String, _ enc: String) -> String? {
    // TODO: enc
    let enc = enc.lowercased()
    guard enc == "utf8" else { return nil }
    
    guard let s = try? String(contentsOfFile: path) else { return nil }
    return s
  }
  
  
  // MARK: - Stat
  
  public typealias stat_struct = Darwin.stat

  public static func stat(_ path: String,
                          cb: ( Swift.Error?, stat_struct? ) -> Void)
  {
    do {
      let info = try statSync(path)
      cb(nil, info)
    }
    catch (let error) {
      cb(error, nil)
    }
  }
  
  public static func statSync(_ path: String) throws -> stat_struct {
    var info = stat_struct()
    let rc   = Darwin.stat(path, &info)
    if rc != 0 { throw Error.StatError }
    return info
  }
  
}

public extension fs.stat_struct {
  
  // could be properties, but for consistency with Node ...
  public func isFile()         -> Bool { return (st_mode & S_IFMT) == S_IFREG  }
  public func isDirectory()    -> Bool { return (st_mode & S_IFMT) == S_IFDIR  }
  public func isBlockDevice()  -> Bool { return (st_mode & S_IFMT) == S_IFBLK  }
  public func isSymbolicLink() -> Bool { return (st_mode & S_IFMT) == S_IFLNK  }
  public func isFIFO()         -> Bool { return (st_mode & S_IFMT) == S_IFIFO  }
  public func isSocket()       -> Bool { return (st_mode & S_IFMT) == S_IFSOCK }
  
  public func isCharacterDevice() -> Bool {
    return (st_mode & S_IFMT) == S_IFCHR
  }
  
  
  public var size : Int { return Int(st_size) }
  
  
  // TODO: we need a Date object, then we can do:
  //   var atime : Date { return Date(st_atime) }
}
