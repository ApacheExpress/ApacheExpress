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


### Who

**mod_swift** is brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We like feedback, GitHub stars, cool contract work,
presumably any form of praise you can think of.
We don't like people who are wrong.

There is a `#mod_swift` channel on the [Noze.io Slack](http://slack.noze.io).
