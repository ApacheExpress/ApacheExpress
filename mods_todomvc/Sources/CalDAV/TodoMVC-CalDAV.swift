//
//  TodoMVC-CalDAV.swift
//  mods_todomvc
//
//  Created by Helge Hess on 08/02/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import ApacheExpress
#if os(Linux)
  import Glibc
#endif

// MARK: - CalDAV support

let principalCollectionURL = "/todomvc/principals/"
let defaultPrincipalURL    = "\(principalCollectionURL)kasse7/"
let baseTime               = time_t.now - 1486588945

/**
 * A simple CalDAV middleware.
 *
 * NOT conforming at all, just the stuff to get the demo running :-)
 *
 * Also: Do NOT structure your DAV server like that. A DAV server should be node
 *       based. This is bad design, but well ;->
 */
func CalDAVExpress(prefix: String, todos: VolatileStoreCollection<Todo>)
     -> MiddlewareObject
{
  // TODO: support mount prefixes so that we can avoid the /todomvc/
  let app = Express()
  

  // In something real, this would need to be attached to the model
  var fnToID  = [ String : Int    ]()
  var idToFN  = [ Int    : String ]()
  var idToUID = [ Int    : String ]() // TODO: generate UIDs and keep them here
  
  
  // MARK: - Common Stuff
  
  app.use("/todomvc/*") { req, res, next in
    res.setHeader("DAV", davConformance.joined(separator: ", "))
    try next()
  }

  app.options("/todomvc/*") { req, res, _ in
    res.setHeader("Allow", allowedMethods.joined(separator: ", "))
    res.status(200)
    try res.end()
  }
  
  app.use("/todomvc/*", bodyParser.davQuery())
  
  
  // MARK: - Principal record
  
  app.propfind0("/todomvc/principals") { req, res, _ in
    try res.send([ MakeResponse.forPrincipalCollection(req) ])
  }
  app.propfind1("/todomvc/principals") { req, res, _ in
    try res.send([ MakeResponse.forPrincipalCollection(req),
                   MakeResponse.forPrincipal(req, url: defaultPrincipalURL,
                                             displayName: "Apache Express") ])
  }
  
  app.propfind0("/todomvc/principals/:fn") { req, res, _ in
    guard let _ = req.params["fn"] else { return try res.sendStatus(400) }
    try res.send([ MakeResponse.forPrincipal(req, url: req.url,
                                             displayName: "Apache Express") ])
  }
  
  
  // MARK: - List the calendar home
  
  app.propfind0("/todomvc") { req, res, _ in
    try res.send([ MakeResponse.forHome(req) ])
  }
  app.propfind1("/todomvc") { req, res, _ in
    try res.send([ MakeResponse.forHome    (req),
                   MakeResponse.forCalendar(req, url: "/todomvc/todos/",
                                            todos: todos),
                   MakeResponse.forAddressbook(req, url: "/todomvc/contacts/")])
  }
  
  app.proppatch("/todomvc") { req, res, _ in
    // fake, iCal tries to patch stuff - we don't care
    let s = try req.readBodyAsString()
    res.writeHead(200, [ "Content-Type" : "text/xml" ])
    try res.end()
  }
  
  
  // MARK: - The calendar itself

  app.proppatch("/todomvc/todos") { req, res, _ in
    let s = try req.readBodyAsString()
    res.writeHead(200, [ "Content-Type" : "text/xml" ])
    try res.end()
  }
  
  app.propfind("/todomvc/todos") { req, res, _ in
    var responses = [ DAVResponse ]()
    responses.append(MakeResponse.forCalendar(req, url: req.url, todos: todos))
    
    if req.depth != .Zero {
      for todo in todos.getAll() {
        let fn  = idToFN[todo.id] ?? "\(todo.id)"
        let uid = idToUID[todo.id]
        responses.append(MakeResponse.forTodo(req, collectionURL: req.url,
                                              fn: fn, uid: uid, todo: todo))
      }
    }
    try res.send(responses)
  }
  
  func idFromHRef(_ href: String) -> Int {
    // TODO: cut off last path component
    let slash : Int32 = 47
    guard var p = rindex(href, slash) else { return -42 }
    p = p.advanced(by: 1)
    
    let s = String(cString: p)
    if let id = fnToID[s] { return id }
    
    guard let id = Int(s) else {
      console.error("Could no parse href:", href)
      return -42
    }
    return id
  }
  
  app.report("/todomvc/todos") { req, res, _ in
    if let syncToken = req.davQuery?.syncToken, !syncToken.isEmpty {
      if syncToken == todos.syncToken {
        let emptyDAV = [ DAVResponse ]()
        return try res.send(emptyDAV)
      }
      return try res.sendInvalidSyncToken()
    }
    
    let arrangedObjects : [ Todo ]
    
    if let hrefs = req.davQuery?.hrefs, !hrefs.isEmpty {
      let hrefIDs : [ Int ] = hrefs.map(idFromHRef)
      arrangedObjects = todos.get(ids: hrefIDs)
    }
    else { // TODO: also: apply query filters
      arrangedObjects = todos.getAll()
    }
    
    var responses = [ DAVResponse ]()
    for todo in arrangedObjects {
      let fn  = idToFN[todo.id] ?? "\(todo.id)"
      let uid = idToUID[todo.id]
      responses.append(MakeResponse.forTodo(req, collectionURL: req.url,
                                            fn: fn, uid: uid, todo: todo))
    }
    
    try res.send(responses)
  }
  
  
  
  // MARK: - The Todos
  
  func todoForFN(fn: String?) -> Todo? {
    guard let fn = fn                    else { return nil }
    guard let id = fnToID[fn] ?? Int(fn) else { return nil }
    guard let todo = todos.get(id: id)   else { return nil }
    return todo
  }
  
  app.get("/todomvc/todos/:fn") { req, res, next in
    guard let todo = todoForFN(fn: req.params["fn"])
     else { return try res.sendStatus(404) }

    let iCal = todo.iCalendarStringWith(uid: idToUID[todo.id])
    
    res.writeHead(200, [ "ETag"         : "\"\(todo.etag)\"",
                         "Content-Type" : "text/calendar" ])
    try res.end(iCal)
  }
  
  app.put("/todomvc/todos/:fn") { req, res, next in
    guard req.isTextCalendarRequest else { return try next() }
    guard let fn = req.params["fn"] else { return try res.sendStatus(400) }
    
    let s = try req.readBodyAsString()
    
    guard let vCal  = HackyVersitParser.parse(string: s ?? ""),
          let vTodo = vCal.todos.first
     else {
      return try res.sendStatus(400)
    }
    
    if var todo = todoForFN(fn: fn) { // update
      todo.title     = vTodo.summary
      todo.completed = vTodo.isCompleted
      if let order = vTodo.sortOrder { todo.order = order }
      todos.update(id: todo.id, value: todo) // value type!
      res.writeHead(200)
      try res.end()
    }
    else { // create
      let pkey = todos.nextKey()
      fnToID[fn]    = pkey
      idToFN[pkey]  = fn
      idToUID[pkey] = vTodo.uid
      
      let newTodo = Todo(id: pkey, title: vTodo.summary,
                         completed: vTodo.isCompleted,
                         order:     vTodo.sortOrder ?? 0)
      todos.update(id: pkey, value: newTodo) // value type!
      res.writeHead(201)
      try res.end()
    }
  }
  
  
  // low hanging fruits
  registerCardDAVMiddleware(in: app)
  
  
  // MARK: - generic fallback PROPFIND:0
  
  app.propfind0("/todomvc/*") { req, res, _ in
    // fallback propfind-0 to support queries for current-user-principal
    console.log("fallback propfind0")
    
    let response = DAVResponse(url: req.url, ns.DAV, [
      "current-user-principal"   : .URL(defaultPrincipalURL),
      "principal-collection-set" : .URL(principalCollectionURL)
    ])
    try res.send([ response ])
  }
  
  return app
}


// MARK: - Setup WebDAV response objects

enum MakeResponse {

  static func forPrincipal(_ req: IncomingMessage, url: String,
                           displayName: String) -> DAVResponse
  {
    var r = DAVResponse(url: req.url, ns.DAV, [
      "current-user-principal"   : .URL(url), // well ;-)
      "principal-URL"            : .URL(url), // well ;-)
      "principal-collection-set" : .URL(principalCollectionURL),
      "displayname"              : "Apache Express",
      "resourcetype"             : .TagArray([ ( ns.DAV, "principal" ) ])
    ], query: req.davQuery)
    r.add(ns.CalDAV, [
      "calendar-user-address-set" : .URL(url),
      "calendar-home-set" :         .URL("/todomvc/"),
    ])
    r.add(ns.CardDAV, [
      "addressbook-home-set" :      .URL("/todomvc/"),
    ])
    return r
  }

  static func forPrincipalCollection(_ req: IncomingMessage) -> DAVResponse {
    return DAVResponse(url: req.url, ns.DAV, [
      "current-user-principal"   : .URL(defaultPrincipalURL),
      "principal-collection-set" : .URL(req.url),
      "resourcetype"             : .TagArray([ ( ns.DAV, "collection" ) ])
    ], query: req.davQuery)
  }

  static func forHome(_ req: IncomingMessage) -> DAVResponse {
    var r =  DAVResponse(url: req.url, ns.DAV, [
      "current-user-principal"   : .URL(defaultPrincipalURL),
      "principal-URL"            : .URL(defaultPrincipalURL),
      "principal-collection-set" : .URL(principalCollectionURL),
      "owner"                    : .URL(defaultPrincipalURL),
      "resourcetype"             : .TagArray([ ( ns.DAV, "collection" ) ])
    ], query: req.davQuery)
    r.add(ns.CalDAV, [
      "calendar-user-address-set"     : .URL(defaultPrincipalURL),
      "calendar-home-set"             : .URL("/todomvc/"),
      "default-alarm-vevent-date"     : .Text(defaultAlarms.vEventDate),
      "default-alarm-vevent-datetime" : .Text(defaultAlarms.vEventDateTime)
    ])

    // FIXME: remove me, should not be necessary
    let ctag = "zztag-\(time_t.now)-home"
    r.add(ns.CalServer, [ "getctag": .Text(ctag) ])
    return r
  }

  static func forCalendar(_ req: IncomingMessage, url: String,
                          todos: VolatileStoreCollection<Todo>) -> DAVResponse
  {
    let privileges =
      [ "read", "read-current-user-privilege-set",
        "write", "write-properties", "write-content",
        "bind", "unbind"]
    
    var r = DAVResponse(url: "/todomvc/todos/", ns.DAV, [
      "displayname"                : .Text("TodoMVC"),
      "current-user-principal"     : .URL(defaultPrincipalURL),
      "principal-collection-set"   : .URL(principalCollectionURL),
      "owner"                      : .URL(defaultPrincipalURL),
      "current-user-privilege-set" : .TagSubset(ns.DAV, "privilege", privileges),
      "resourcetype"               : .TagArray([ ( ns.DAV,    "collection" ),
                                                 ( ns.CalDAV, "calendar"   ) ])
    ], query: req.davQuery)

    let rawSupportSet =
      "<supported-calendar-component-set " +
      "xmlns='urn:ietf:params:xml:ns:caldav'>" +
      "<comp name='VTODO' /></supported-calendar-component-set>"
    r.add(ns.CalDAV, [
      "supported-calendar-component-set":
        .PropSubset(ns.CalDAV, "comp", "name", ["VTODO"]),
      "supported-calendar-component-sets": .Raw(rawSupportSet), // Hm?
      "calendar-timezone": .Text(iCalTimeZones.Europe.Berlin)
    ])
    r.add(ns.ICal, [
      "calendar-order": "1", // yes, some genius didn't know about RFC 3648
      "calendar-color": "#1D9BF6FF" // also the symbolic-color=\"blue\" abuse
    ])
  
    r.add(ns.CalServer, [ "getctag"    : .Text(todos.ctag) ])
    r.add(ns.DAV,       [ "sync-token" : .Text(todos.syncToken) ])
    
    let reports = [ ( ns.CalDAV,  "calendar-multiget"    ),
                    ( ns.CardDAV, "addressbook-multiget" ),
                    ( ns.DAV,     "sync-collection"      )
                  ]
    let rawReportSet = reports.reduce("") { xml, pair in
      let ( ns, name ) = pair
      return xml + "<supported-report><report>" +
                   "<\(name) xmlns='\(ns)' />"  +
                   "</report></supported-report>"
    }
    r.add(ns.DAV, [ "supported-report-set" : .Raw(rawReportSet) ])
    
    return r
  }

  static func forTodo(_ req: IncomingMessage, collectionURL: String,
                      fn: String, uid: String? = nil, todo: Todo) -> DAVResponse
  {
    let privileges = [ "read-content", "write-content" ]
    
    var r = DAVResponse(url: collectionURL + fn, ns.DAV, [
      "getetag"        : .Text("\"\(todo.etag)\""),
      "getcontenttype" : .Text("text/calendar"),
      "current-user-privilege-set" : .TagSubset(ns.DAV, "privilege", privileges)
    ], query: req.davQuery)
    
    if let query = req.davQuery {
      if query.isPropertySelected(ns: ns.CalDAV, name: "calendar-data") {
        let iCal = todo.iCalendarStringWith(uid: uid)
        r.add(ns.CalDAV, [ "calendar-data": .Text(iCal) ])
      }
    }
    
    return r
  }
}


// MARK: - ETag & iCalendar Support

extension Todo : ETaggable {
  var etag : String {
    let hexHash = String(title.hash, radix: 16, uppercase: true)
    let ci = completed ? "Y" : "N"
    return "Zz\(ci)\(order)x\(hexHash)"
  }
}

extension Todo : ICalendarRepresentable {

  var iCalendarComponentString : String {
    let now          = time_t.now
    let lastModified = now.iCalendarTime
    let uid          = "\(id)" // TODO: remap!
    let status       = completed ? "COMPLETED" : "NEEDS-ACTION"
    
    let completedExtra = completed
      ? "PERCENT-COMPLETE:100\r\nCOMPLETED:\(now.iCalendarTime)\r\n"
      : ""
    
    return
      "BEGIN:VTODO\r\n" +
      "STATUS:\(status)\r\n" + completedExtra +
      "CREATED:20151115T124437Z\r\n" +
      "UID:\(uid)\r\n" +
      "SUMMARY:\(title)\r\n" +
      "X-APPLE-SORT-ORDER:\(order)\r\n" +
        // yes, some genius didn't know about RFC 3648
      "LAST-MODIFIED:\(lastModified)\r\n" +
      "DTSTAMP:\(lastModified)\r\n" +
      "SEQUENCE:0\r\n" +
      "END:VTODO\r\n"
    ;
  }
 
  func iCalendarStringWith(uid: String?) -> String {
    let iCal = iCalendarString
    guard let uid = uid else { return iCal }
    
    // Hack in client assigned UIDs.
    return iCal.replacingOccurrences(of: "UID:\(id)", with: "UID:\(uid)")
  }
}

fileprivate enum defaultAlarms {
  static let vEventDate =
    "BEGIN:VALARM\r\n" +
    "X-WR-ALARMUID:zz-default-vevent-date-alarm\r\n" +
    "UID:ALARMUID:zz-default-vevent-date-alarm\r\n" +
    "TRIGGER:-T15H\r\n" +
    "ATTACH;VALUE=URI:Basso\r\n" +
    "ACTION:AUDIO\r\n" +
    "END:VALARM\r\n"
  static let vEventDateTime =
    "BEGIN:VALARM\r\n" +
    "X-WR-ALARMUID:zz-default-vevent-datetime-alarm\r\n" +
    "UID:ALARMUID:zz-default-vevent-datetime-alarm\r\n" +
    "TRIGGER;VALUE=DATE-TIME:19760401T005545Z\r\n" +
    "ACTION:NONE\r\n" +
    "END:VALARM\r\n"
}

extension VolatileStoreCollection where T : ICalendarRepresentable {
  // Too sad we can't make this conform to ICalendarRepresentable
  
  var iCalendarComponentString : String {
    return getAll().reduce("") { body, todo in
      return body + todo.iCalendarComponentString
    }
  }
  
}

extension VolatileStoreCollection : CTaggable {
  var ctag : String { return "zztag-\(baseTime)-\(changeCounter)" }
}


// MARK: - Handler for .well-known redirects

import Apache2

/**
 * A (very) raw Apache handler which runs first and captures .well-known
 * queries and redirects them to our todomvc API. Plain C, no wrapping.
 * Also: redirect PROPFIND on / to our principal. iCal bootstrap is, well, ...
 */
func dotWellKnownHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  guard let uri = p?.pointee.uri else { return DECLINED }
  
  guard (strcmp(uri, "/.well-known/caldav")  == 0 ||
         strcmp(uri, "/.well-known/carddav") == 0 ||
         (strcmp(uri, "/") == 0 && p?.pointee.method_number == M_PROPFIND))
   else { return DECLINED }
  
  // Nothing else matters. https://www.youtube.com/watch?v=tAGnKpE4NCI
  //apr_table_set(p?.pointee.headers_out, "location", "/todomvc/principals/")
  // This looks wrong but makes it work.
  apr_table_set(p?.pointee.headers_out, "location", defaultPrincipalURL)
  return HTTP_SEE_OTHER
}
