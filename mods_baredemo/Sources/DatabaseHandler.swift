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
  req.puts("<html><head><title>Hello DBD</title>\(semanticUI)</head>")
  req.puts("<body><div class='ui main container' style='margin-top: 1em;'>")
  req.puts("<h3>Swift Apache DBD Module Demo Handler</h3>")
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
  
  // MARK: - Raw Select
  
  guard let res = dbd.select("SELECT * FROM pets") else {
    req.puts("<p>Query failed. No idea why, check the logs :-)</p>")
    return OK
  }
  
  req.puts(
    "<p>The query returned a result: \(res.columnCount) columns, " +
    "\(res.count) rows:</p>"
  )
  
  req.puts("<table class='ui sortable celled table'>")
  req.puts("<thead><tr><th>Name</th></tr></thead><tbody>")
  // TODO: make this a Swift Iterator (but then we can't use protocols)
  while let row = res.next() {
    req.puts("<tr><td>")
    if let value = row[0] {
      req.puts(value)
      // req.puts(" name(\(row[name: 0]))") // fails
    }
    req.puts("</td></tr>")
  }
  req.puts("</tbody></table>")
  
  
  // MARK: - Wrapped Select - Strongly Typed!
  
  req.puts("<table class='ui sortable celled table'>")
  req.puts("<thead>" +
    "<tr><th colspan='2'>Callback typed fetch, with optionals</th></tr>" +
    "<tr><th>Name</th><th>Count</th></tr></thead><tbody>"
  )
  dbd.select("SELECT * FROM pets") { (name : String, count : Int?) in
    req.puts("<tr><td>\(name)</td><td>\(count)</td></tr>")
  }
  req.puts("</tbody></table>")

  
  // MARK: - Wrapped Select - with model-like access
  
  struct Model {
    struct Pet {
      static let name  = Attribute<String>(name: "name")
      static let count = Attribute<Int>   (name: "count")
    }
  }
  
  req.puts("<table class='ui sortable celled table'>")
  req.puts("<thead>" +
    "<tr><th colspan='2'>Model fetch</th></tr>" +
    "<tr><th>Name</th><th>Count</th></tr></thead><tbody>"
  )
  dbd.select(Model.Pet.name, Model.Pet.count, from: "pets") { name, count in
    req.puts("<tr><td>\(name)</td><td>\(count)</td></tr>")
  }
  req.puts("</tbody></table>")
  
  
  // MARK: - Smarter Model
  
  struct SmartModel {
    struct Pet {
      var name  : String
      var count : Int
    }
  }
  
 
  
  // MARK: - Finish up
  
  req.puts("</div></body></html>")
  return OK
}
