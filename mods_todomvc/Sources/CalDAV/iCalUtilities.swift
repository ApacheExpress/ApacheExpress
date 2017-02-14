//
//  iCalUtilities.swift
//  mods_todomvc
//
//  Created by Helge Hess on 10/02/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

import ApacheExpress

protocol ICalendarRepresentable {
  var iCalendarString          : String { get }
  var iCalendarComponentString : String { get }
}

enum PRODID {
  static let vendor  = "ZeeZide GmbH"
  static let product = "todo_mvc ApacheExpress"
  static let version = "1.33.7"
  
  static let iCalendarString =
               "PRODID:-//\(vendor)//\(product) \(version)//EN\r\n"
}

extension ICalendarRepresentable {
  
  var iCalendarString : String {
    return
      "BEGIN:VCALENDAR\r\n" +
      "VERSION:2.0\r\n" +
      PRODID.iCalendarString +
      "CALSCALE:GREGORIAN\r\n" +
      iCalendarComponentString +
      "END:VCALENDAR\r\n"
    ;
  }
  
}

extension time_t {
  var iCalendarTime : String { return self.format("%Y%m%dT%H%M%SZ") }
}

enum iCalTimeZones {

  enum Europe {
    static let Berlin =
      "BEGIN:VCALENDAR\r\n" +
        "VERSION:2.0\r\n" +
        PRODID.iCalendarString +
        "CALSCALE:GREGORIAN\r\n" +
        "BEGIN:VTIMEZONE\r\n" +
          "TZID:Europe/Berlin\r\n" +
          "BEGIN:DAYLIGHT\r\n" +
            "TZOFFSETFROM:+0100\r\n" +
            "RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU\r\n" +
            "DTSTART:19810329T020000\r\n" +
            "TZNAME:GMT+2\r\n" +
            "TZOFFSETTO:+0200\r\n" +
          "END:DAYLIGHT\r\n" +
          "BEGIN:STANDARD\r\n" +
            "TZOFFSETFROM:+0200\r\n" +
            "RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU\r\n" +
            "DTSTART:19961027T030000\r\n" +
            "TZNAME:GMT+1\r\n" +
            "TZOFFSETTO:+0100\r\n" +
          "END:STANDARD\r\n" +
        "END:VTIMEZONE\r\n" +
      "END:VCALENDAR\r\n"
  }
}


// MARK: - Parser

/**
 * A VERY HACKISH iCalendar parser
 *
 * DO NOT USE, this is not only expensive and slow, it is WRONG for any real use 
 * you can think of. It just serves for demo purposes.
 */
final class HackyVersitParser {
  
  static func parse(string s: String) -> VCalendar? {
    let parser = HackyVersitParser(iCalendar: s)
    parser.parse()
    return parser.results.first as? VCalendar
  }
  
  let ical : String
  
  init(iCalendar: String) {
    self.ical = iCalendar
  }
  
  var results = [ VComponent ]()
  var stack   = [ VComponent ]()
  var cursor  : VComponent? {
    return stack.last
  }
  
  func parse() {
    let lines = ical.components(separatedBy: "\r\n") // TODO: proper unfold
    
    for line in lines {
      if line.hasPrefix("BEGIN:") {
        if let component = componentForStartLine(line) {
          stack.append(component)
        }
        else {
          console.error("invalid begin line: \(line)")
        }
      }
      else if line.hasPrefix("END:") {
        if let component = stack.popLast() {
          if stack.isEmpty {
            results.append(component)
          }
          else {
            cursor?.contents.append(.Component(component))
          }
        }
      }
      else if let prop = propertyForLine(line) {
        cursor?.contents.append(.Property(prop))
      }
      else if !line.isEmpty {
        cursor?.contents.append(.Junk(line))
        console.error("junk line: \(line)")
      }
    }
  }
  
  func componentForStartLine(_ line: String) -> VComponent? {
    let colon = line.characters.index(of: ":")!
    let name  = line.substring(from: line.index(after: colon))
    
    switch name {
      case "VCALENDAR": return VCalendar()
      case "VTODO":     return VTodo()
      case "VCARD":     return VCard()
      
      default: return VComponent(name: name)
    }
  }
  
  func propertyForLine(_ line: String) -> VProperty? {
    guard let colon = line.characters.index(of: ":") else { return nil }
    
    let value = line.substring(from: line.index(after: colon))
    let nameAndAttrs = line.substring(to: colon)
    
    let name : String
    if let semiColon = nameAndAttrs.characters.index(of: ";") {
      name = nameAndAttrs.substring(to: semiColon)
    }
    else {
      name = nameAndAttrs // no attrs
    }
    
    return VProperty(name: name, value: value)
  }

}


// Whether you want those to be classes or structs really depends on whether
// you plan to modify them afterwards (well, I guess you could box a var).

class VComponent {
  
  enum Content {
    case Component(VComponent)
    case Property(VProperty)
    case Junk(String)
  }
  
  let name     : String
  var contents = [ Content ]()
  
  init(name: String) {
    self.name = name
  }
  
  subscript(property name: String) -> VProperty? {
    for child in contents {
      guard case let .Property(property) = child else { continue }
      if property.name == name { return property }
    }
    return nil
  }
  subscript(properties name: String) -> [ VProperty ] {
    var matches = [ VProperty ]()
    for child in contents {
      guard case let .Property(property) = child else { continue }
      if property.name == name { matches.append(property) }
    }
    return matches
  }
  
  subscript(component name: String) -> VComponent? {
    for child in contents {
      guard case let .Component(component) = child else { continue }
      if component.name == name { return component }
    }
    return nil
  }
  subscript(components name: String) -> [ VComponent ] {
    var matches = [ VComponent ]()
    for child in contents {
      guard case let .Component(component) = child else { continue }
      if component.name == name { matches.append(component) }
    }
    return matches
  }
  
  subscript(name: String) -> String? {
    return self[property: name]?.value
  }
  subscript(int name: String) -> Int? {
    guard let s = self[property: name] else { return nil }
    return Int(s.value)
  }
}

class VCalendar : VComponent {
  init() { super.init(name: "VCALENDAR") }
  
  var todos : [ VTodo ] {
    return (self[components: "VTODO"] as? [ VTodo ]) ?? []
  }
}

class VTodo : VComponent {
  init() { super.init(name: "VTODO") }
  
  var uid       : String { return self["UID"] ?? "ERROR-NO-UID" } // must-have
  
  var summary   : String { return self["SUMMARY"] ?? "Untitled" }
  var sortOrder : Int?   { return self[int: "X-APPLE-SORT-ORDER"] }
  
  var isCompleted : Bool {
    guard let status = self["STATUS"] else { return false }
    return status == "COMPLETED"
  }
}

class VCard : VComponent {
  init() { super.init(name: "VCARD") }
}

class VProperty {
  let name  : String
  let value : String
  
  init(name: String, value: String) {
    self.name  = name
    self.value = value
  }
}
