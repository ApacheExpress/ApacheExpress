<h2>mod_swift - mods_todomvc
  <img src="http://zeezide.com/img/mod_swift.svg"
       align="right" width="128" height="128" />
</h2>

![Apache 2](https://img.shields.io/badge/apache-2-yellow.svg)
![Swift3](https://img.shields.io/badge/swift-3-blue.svg)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Travis](https://travis-ci.org/AlwaysRightInstitute/mod_swift.svg?branch=develop)

**mod_swift** is a technology demo which shows how to write native modules
for the
[Apache Web Server](https://httpd.apache.org)
in the 
[Swift 3](http://swift.org/)
programming language.
**Server Side Swift the [right](http://www.alwaysrightinstitute.com/) way**.

## mods_todomvc

mods_todomvc implements a
[Todo-Backend](http://todobackend.com)
using mod_swift and [ApacheExpress](../ApacheExpress/README.md).

<img src="http://noze.io/images/screenshot-todo-mvc-redis-1.jpeg" />

NOTE: This one uses an unlocked in-memory todo store. Obviously this isn't the
      correct solution but works well enough for demo purposes :-)
      A proper Apache backend store would need to deal with shared memory,
      locking, and/or an out of process store like Redis.


## CalDAV

TodoMVC is a nice thing, but we thought we take it a little further.
Instead of just implementing the trivial JSON-REST API,
we also added [support for CalDAV](Sources/CalDAV/TodoMVC-CalDAV.swift).
[CalDAV](http://caldav.org/) is the IETF standard
([RFC 4791](https://tools.ietf.org/html/rfc4791)) for managing calendars and
todo lists.

What does that mean? Well it means, you can access *mods_todomvc*
not only using the TodoMVC web frontend shown above, but - wait for it -
with any existing todo list application that supports CalDAV.
Most importantly this covers the iOS Reminders application as well as the macOS
one, there are many more. Look at that:

<img src="http://zeezide.de/img/finished-todo-mvc-iOS-reminders-list-cut.png" />

### Functionality Supported

Everything the TodoMVC web client / API can do is supported.
That is, you can create/delete todos, you can set the todo title,
you can mark them as done/undone, and you can reorder the list of todos.
You can't do other VTODO things, like setting priorities, attaching links, etc.
After all this is still hooked up to the very simple TodoMVC model.

There is only a single account. All people using your server would share the
same todos. Isn't that great?

### How to Configure iOS Reminders for TodoMVC

To configure go this route: 
iOS settings / Calendar / Accounts / Add Account / Other / Add CalDAV Account.
Enter any user/password/description and put `http://yourmac.local:8042/` into
the Server field.

On macOS: System Preferences / Internet Accounts / Add Other Account... /
CalDAV account / Popup 'Advanced'. Enter any user/password,
Server Address is `http://yourmac.local:8042/`,
Server Path is `/todomvc/`, put 8042 into port and deselect 'Use SSL'.

### Bonus: CardDAV Addressbook

Low hanging fruits: a read-only CardDAV addressbook. 
Access it from the iOS 'Contacts' application or any other CardDAV client.
It carries three builtin vCards, great stuff!
To configure go this route: 
iOS settings / Contacts / Accounts / Add Account / Other / Add CardDAV Account.
Enter any user/password/description and put `http://yourmac.local:8042/` into
the Server field. 
(on macOS use `Manual` and `http://yourmac.local:8042/todomvc/`)

### Implementation

**Be warned**:
This is hacked together for the demo, it is by no means a conforming CalDAV 
server. But it gets the job done :-)
Do **not** use it for realz.
It is a little more code that the JSON protocol, but reasonable, especially
considering the gains of supporting an actual standard.
A lot of the code in there is generic and could be moved into a proper
framework.

Some notes:

- The model is not modified, it is the same model the JSON API uses.
  (which would not be suitable for a real implementation)
- This is a pretty standard Middleware setup with some helper extensions.
- Included is a simple bodyParser.davQuery which can parse some relevant info
  out of WebDAV PROPFIND and REPORT requests.
- It uses the Apache XML parser included in the Apache Portable Runtime,
  and comes with a few Swift wrappers for that.
  Advantage: Available everywhere.
- For iCalendar parsing it contains a VERY hackish iCalendar parser. Do not use
  elsewhere, ok for demo but not correct for general application!
- Contains an ExExpress extension which allows you to filter by WebDAV methods,
  like PROPFIND, PROPPATCH.
- A lot of the protocol is built arounds WebDAV properties. There is a
  DAVResponse helper object which is used to setup responses to queries for
  such.
  That part looks a little ugly and needs some refactoring.


### Who

**mod_swift** is brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We like feedback, GitHub stars, cool contract work,
presumably any form of praise you can think of.
We don't like people who are wrong.

There is a `#mod_swift` channel on the [Noze.io Slack](http://slack.noze.io).
