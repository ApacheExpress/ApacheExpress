//
//  Misc.swift
//  Noze.io
//
//  Created by Helge Heß on 4/29/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Darwin

public let HTTPDateFormat = "%a, %d %b %Y %H:%M:%S GMT" // TBD: %Z emits UTC

// Generate an HTTP date header value
func generateDateHeader(timestamp ts: time_t = time(nil)) -> String {
  return ts.componentsInUTC.format(HTTPDateFormat)
}
