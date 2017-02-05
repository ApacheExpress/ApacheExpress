//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import ZzApache
import Apache2

// Just a handler that logs a little info about a request and delivers
// the file when appropriate
func RequestInfoHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  // the print crashes swiftc (Xcode 8.2.1 8C1002)
  //   print("handle request: \(p)")
  // this too:
  //   guard p != nil else { return DECLINED }
  
  var req = ZzApacheRequest(raw: p!) // var because we set the contentType
    
  req.log(level: APLOG_DEBUG,
          "SWIFT \(#function): handler \(req.handler)" +
          " (\(req.method) on \(req.uri)[\(req.unparsedURI)])")
  
  guard req.handler == "helloworld" else { return DECLINED }
  guard req.method  == "GET"        else { return HTTP_METHOD_NOT_ALLOWED }
  
  req.contentType = "text/html; charset=ascii"
  req.puts("<html><head><title>Hello</title></head>")
  req.puts("<body><h3>Swift Apache Module Demo Handler</h3>")
  
  req.puts("<a href='/'>[Server Root]</a>")
  
  req.puts("<pre>")
  
  req.puts("Request line:   \(req.theRequest)\r\n")
  req.puts("Protocol:       \(req.protocol)\r\n")
  req.puts("Hostname:       \(req.hostname)\r\n")
  req.puts("Method:         \(req.method)\r\n")
  req.puts("Startstamp:     \(req.requestTime)\r\n")
  req.puts("Handler:        \(req.handler)\r\n")
  req.puts("Filename:       \(req.filename)\r\n")
  req.puts("CanFilename:    \(req.canonicalFilename)\r\n")
  req.puts("ContentType:    \(req.contentType)\r\n")
  req.puts("ContentEnc:     \(req.contentEncoding)\r\n")
  req.puts("User:           \(req.user)\r\n")
  req.puts("AuthType:       \(req.apAuthType)\r\n")
  req.puts("URI:            \(req.uri)\r\n")
  req.puts("PathInfo:       \(req.pathInfo)\r\n")
  req.puts("Args:           \(req.args)\r\n")
  req.puts("User-Agent:     \(req.headersIn["User-agent"] ?? "-")\r\n")
  req.puts("Depth:          \(req.headersIn["Depth"]      ?? "-")\r\n")

  // module configuration
  req.puts("Answer:         \(req.ourConfig["answer"]     ?? "-")\r\n")

  // TODO: need HTML escape here
  // req.puts("Config:         \(p!.pointee.ourConfig)\r\n")
  
  if let fn = req.filename {
    req.puts("  Valid:        \(req.finfo.valid)\r\n") // bitmask
    if (req.finfo.valid & APR_FINFO_SIZE) != 0 {
      req.puts("  Size:         \(req.finfo.size)\r\n")
    }
    if (req.finfo.valid & APR_FINFO_TYPE) != 0 {
      req.puts("  Type:         \(req.finfo.filetype)\r\n")
    }
    if (req.finfo.valid & APR_FINFO_NAME) != 0 {
      req.puts("  Name:         \(req.finfo.name)\r\n")
    }

    if let cstr = req.finfo.fname {
      req.puts("  FName:        \(String(cString: cstr))\r\n")
    }
  }
  req.puts("</pre>")
  
  if let fn = req.filename, req.finfo.filetype.rawValue == 1 {
    var fh : OpaquePointer? = nil
    let rc = apr_file_open(&fh, fn,
                           APR_READ | APR_SHARELOCK /*| APR_SENDFILE_ENABLED*/,
                           APR_OS_DEFAULT,
                           req.pool)
    defer { if fh != nil { apr_file_close(fh) } }
    
    if rc == APR_SUCCESS {
      req.puts("<h5>File below: \(fn)</h5><hr /")
      var sentSize : apr_size_t = 0
      let rc = ap_send_fd(fh, req.raw, 0, apr_size_t(req.finfo.size), &sentSize)
      if rc != 0 { req.puts("<br />Error: \(rc)") }
      req.puts("<hr />")
    }
    else {
      req.puts("<h3>Could not open file: \(fn)</h3>")
    }
  }
  
  req.puts("</body></html>")

  // works, not needed here
  //   func rqPoolDealloc(object: UnsafeMutableRawPointer?) -> apr_status_t
  // apr_pool_cleanup_register(req.pointee.pool, req,
  //                           rqPoolDealloc, rqPoolChildDealloc)
    
  return OK
}
