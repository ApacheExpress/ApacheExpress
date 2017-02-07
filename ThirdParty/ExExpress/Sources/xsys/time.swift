//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

#if os(Linux)
  import Glibc

  public typealias struct_tm = Glibc.tm
#else
  import Darwin

  public typealias struct_tm = Darwin.tm
#endif

// MARK: - Time Helpers

/// Unix timestamp. `time_t` has the Y2038 issue and its granularity is limited
/// to seconds.
/// Unix timestamps are counted in seconds starting Jan 1st 1970 00:00:00, UTC.
public extension time_t {
  
  /// Returns the current time.
  public static var now : time_t { return time(nil) }
  
  /// Initialize the `time_t` value from Unix `tm` value (date components).
  /// Assumes the values are given in *local time*.
  /// Remember that the `time_t` itself is in UTC.
  public init(_ tm: struct_tm) {
    self = tm.localTime
  }
  /// Initialize the `time_t` value from Unix `tm` value (date components).
  /// Assumes the values are given in *UTC time*.
  /// Remember that the `time_t` itself is in UTC.
  public init(utc tm: struct_tm) {
    self = tm.utcTime
  }
  
  /// Converts the `time_t` timestamp into date components (`tz` struct) living
  /// in the UTC timezone.
  /// Remember that the `time_t` itself is in UTC.
  public var componentsInUTC : struct_tm {
    var t  = self
    var tm = struct_tm()
    _ = gmtime_r(&t, &tm)
    return tm
  }
  
  /// Converts the `time_t` timestamp into date components (`tz` struct) living
  /// in the local timezone of the Unix environment.
  /// Remember that the `time_t` itself is in UTC.
  public var componentsInLocalTime : struct_tm {
    var t  = self
    var tm = struct_tm()
    _ = localtime_r(&t, &tm)
    return tm
  }
  
  /// Example `strftime` format:
  ///   "%a, %d %b %Y %H:%M:%S GMT"
  ///
  /// This function converts the timestamp into UTC time components to format
  /// the value.
  ///
  /// Example call:
  ///
  ///     xsys.time(nil).format("%a, %d %b %Y %H:%M:%S %Z")
  ///
  public func format(_ sf: String) -> String {
    return self.componentsInUTC.format(sf)
  }
}

/// The Unix `tm` struct is essentially NSDateComponents PLUS some timezone
/// information (isDST, offset, tz abbrev name).
public extension struct_tm {
  
  /// Create a Unix date components structure from a timestamp. This variant
  /// creates components in the local timezone.
  public init(_ tm: time_t) {
    self = tm.componentsInLocalTime
  }
  
  /// Create a Unix date components structure from a timestamp. This variant
  /// creates components in the UTC timezone.
  public init(utc tm: time_t) {
    self = tm.componentsInUTC
  }
  
  public var utcTime : time_t {
    var tm = self
    return timegm(&tm)
  }
  public var localTime : time_t {
    var tm = self
    return mktime(&tm)
  }
  
  /// Example `strftime` format (`man strftime`):
  ///   "%a, %d %b %Y %H:%M:%S GMT"
  ///
  public func format(_ sf: String, defaultCapacity: Int = 100) -> String {
    var tm = self
    
    // Yes, yes, I know.
    let attempt1Capacity = defaultCapacity
    let attempt2Capacity = defaultCapacity > 1024 ? defaultCapacity * 2 : 1024
    var capacity = attempt1Capacity
    
    var buf = UnsafeMutablePointer<CChar>.allocate(capacity: capacity)
    defer { buf.deallocate(capacity: capacity) }
    
    let rc = strftime(buf, capacity, sf, &tm)
    
    if rc == 0 {
      buf.deallocate(capacity: capacity)
      capacity = attempt2Capacity
      buf = UnsafeMutablePointer<CChar>.allocate(capacity: capacity)
      
      let rc = strftime(buf, capacity, sf, &tm)
      assert(rc != 0)
      guard rc != 0 else { return "" }
    }
    
    return String(cString: buf);
  }
  
}
