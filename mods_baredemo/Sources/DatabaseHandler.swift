//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import ZzApache
import Apache2
import ApachePortableRuntime

// Just a handler that logs a little info about a request and delivers
// the file when appropriate
func DatabaseHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  var req = ZzApacheRequest(raw: p!) // var because we set the contentType
    
  guard req.handler == "database" else { return DECLINED }
  guard req.method  == "GET"      else { return HTTP_METHOD_NOT_ALLOWED }

  req.contentType = "text/html; charset=ascii"
  req.puts("<html><head><title>Hello</title></head>")
  req.puts("<body><h3>Swift Apache DBD Module Demo Handler</h3>")
  defer { req.puts("</body></html>") }
  
  req.puts("<a href='/'>[Server Root]</a>")
  
  req.puts(
    "<p>" +
    "This handler can access a mod_dbd database as configured in the " +
    "apache.conf." +
    "</p>"
  )
  
  // dbd test
  
  guard let dbd = req.dbdAcquire() else {
    print("got no DB handle ...")
    req.puts("<p>Could not acquire database connection. Configure the " +
      "relevant section in the apache.conf (load mod_dbd and set the absolute" +
      "path to the database in the data directory).</p>"
    )
    return OK
  }
  
  let preStyle =
        "margin: 0 1em 1em 1em; padding: 0.8em; border: 1px dotted #AAA;"
  req.puts(
    "<p>Acquired database connection successfully.</p>" +
    "<p>Run:</p>" +
    "<pre style='\(preStyle)'>" +
    "dbd.select(\"SELECT * FROM pets\")</pre>"
  )
  
  guard let res = dbd.select("SELECT * FROM pets") else {
    req.puts("<p>Query failed. No idea why, check the logs :-)</p>")
    return OK
  }
  
  req.puts(
    "<p>The query returned a result: \(res.columnCount) columns, " +
    "\(res.count) rows:</p>"
  )
  
  req.puts("<ul>")
  // TODO: make this a Swift Iterator
  while let row = res.next() {
    req.puts("<li>")
    if let value = row[0] {
      req.puts(value)
      // req.puts(" name(\(row[name: 0]))") // fails
    }
    req.puts("</li>")
  }
  
  req.puts("</ul>")
  
  return OK
}
