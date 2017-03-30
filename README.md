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

Open Workspace:

``sh
cd mod_swift
open UseMe.workspace
``

Build & Run in Xcode

Trigger echo handler

``sh
curl -X PUT --data-binary $'Hello\n  Swift\n' http://localhost:8042/echo
``
