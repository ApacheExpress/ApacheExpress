![Apache 2](https://img.shields.io/badge/apache-2-yellow.svg)
![Swift3](https://img.shields.io/badge/swift-3-blue.svg)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![tuxOS](https://img.shields.io/badge/os-tuxOS-green.svg?style=flat)
![Travis](https://travis-ci.org/AlwaysRightInstitute/mod_swift.svg?s3wg-api-proposal-1)

**mod_swift** is a technology demo which shows how to write native modules
for the
[Apache Web Server](https://httpd.apache.org)
in the 
[Swift 3](http://swift.org/)
programming language.

This `s3wg-api-proposal-1` branch contains an Apache implementation of the
proposal.

### How to test

Checkout git repro, branch: s3wg-api-proposal-1

``sh
git clone -b s3wg-api-proposal-1 git@github.com:AlwaysRightInstitute/mod_swift.git
``

Build & Run:

``sh
cd mod_swift
xcodebuild -workspace UseMe.xcworkspace -scheme mods_echo && open UseMe.workspace
httpd -X -D $PWD -f $PWD/apache.conf # or just run in Xcode
``

Test echo handler

``sh
curl -X PUT --data-binary $'Hello\n  Swift\n' http://localhost:8042/echo
``

### Source Setup

- the proposal is contained in the (S3WGAPIProposal1)[S3WGAPIProposal1/] folder
- Johannes demo echo service can be found in
  (mods_echo/Sources/Main.swift)[mods_echo/Sources/Main.swift]
- the Apache implementation of the API is in (mods_echo/Sources/)[mods_echo/Sources/]
  - setup of the request (ApacheRequest.swift)[mods_echo/Sources/ApacheRequest.swift]
  - response writer (ApacheResponseWriter.swift)[mods_echo/Sources/ApacheResponseWriter.swift]

### Notes

- the implementation does synchronous I/O
  - a lot of `@escaping` could be dropped
- it is pretty hacky ;->
- doesn't implement all enum cases for method/status
- no abort/trailers
