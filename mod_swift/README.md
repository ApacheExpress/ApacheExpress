<h2>mod_swift
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

This project/sourcedir contains the actual C-language `mod_swift`.
It is a straight Apache module which is then used to load Swift based Apache 
modules (mods_xyz).

Also included are Xcode base configurations, module maps for Apache and APR
as well as a few API wrappers that are used to workaround `swiftc` crashers
and Swift-C binding limitations.

### How to use the module in Apache

Before you can load a Swift Apache module, you need to load mod_swift into
Apache:

```Swift
LoadModule swift_module .libs/mod_swift.so
```

This exposes a new Apache directive called `LoadSwiftModule` which is used to
load Swift based Apache modules into the server. Example:

```Swift

LoadSwiftModule ApacheMain .libs/mods_demo.so
```

### What is an Apache module?

Well, Apache is a highly modular and efficient server framework. The httpd
daemon itself is quite tiny and pretty much all webserver functionality is
actually implemented in the form of
[modules](https://httpd.apache.org/docs/2.4/mod/).
Be it thread handling, access control, mime detection or content negotation -
all of that is implemented as modules. And can be replaced by own modules!

The Apache core modules are written in portable C. Some modules are built
right into the server, but most are loaded as
[dynamic libraries](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/DynamicLibraries/000-Introduction/Introduction.html).
Which ones is specified by the user in the
[configuration file](https://httpd.apache.org/docs/2.4/configuring.html), e.g.:

    LoadModule authz_core_module /usr/libexec/apache2/mod_authz_core.so
    LoadModule mime_module       /usr/libexec/apache2/mod_mime.so

Now with **mod_swift** you can write such modules using the
[Swift](http://swift.org/)
programming language. Enter:

    LoadSwiftModule ApacheMain /usr/libexec/apache2/mods_demo.so

This is a little different to something like `mod_php` which enables Apache
to directly interpret PHP scripts. `mod_php` itself is C software and a single
module.
Since Swift compiles down to regular executable binaries,
and because Swift has excellent 
[C integration](https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithCAPIs.html#//apple_ref/doc/uid/TP40014216-CH8-ID17),
you can write arbitrary modules with **mod_swift** which behave just like the
regular C modules.


### Notes of interest

- The code is 
  [properly formatted](http://www.alwaysrightinstitute.com/swifter-space/),
  max width 80 chars, 2-space indent.
- This doesn't use `apxs` because that is badly b0rked on both 10.11 and 10.12.
- It uses a lot of hardcoded load and lookup pathes, remember, it is a demo!
- It has some leaks and issues, e.g. modules are not properly unloaded.
- Sure, you can link against arbitrary Swift dylibs, 
  [mustache](Sources/mustache/) is an example for exactly that.
- However, you currently cannot use the Swift Package Manager to create
  dylibs (AFAIK). So while in theory that would work, you need to do the
  final linking step separately.
- Yes `mod_swift` itself could be avoided by including the .c in the Swift
  module. Yes, you can even statically link Swift including its runtime. Let
  me know if this is interesting, I have a branch which does exactly that.
- There is one big bet in the code: Officially there is no way to invoke a
  Swift function from C, only the other way around!
  In other words: it is pure luck that 
  [this works](Sources/mod_swift/mod_swift.c#L47) and is ABI compatible with C.
- If you would want to debug the stuff in Xcode - `/usr/sbin/httpd` is under
  [macOS SIP](https://support.apple.com/en-us/HT204899).
- On macOS 10.11 starting Apache with -X crashes a few seconds after the last
  request was received. Maybe just SIGPIPE or sth. 10.12 looks fine.
- Unloading is an issue. I think the Apple and GNUstep Objective-C
  runtimes cannot be properly unloaded (I've heard there is a great runtime
  that can).
  No idea what the situation with 'pure Swift' is.
- Would be cool if Swift 4 would get a proper `extern C {}`.
- Yes, Apache content handlers are not [Noze.io](http://noze.io/) like 
  asynchronous but run in a traditional, synchronous thread-setup.
- Apache varargs funcs are not available since Swift doesn't support such. We
  provide a wrapper for `ap_log_rerror_`, other funcs would need to be wrapped
  the same way.
- Apache also uses quite a few `#define`s, e.g. `ap_fwrite`
- The Apache C headers are prone to crash `swiftc`. Which is why we wrap the
  Apache `request_rec` in an additional struct.

              (__)
            /  .\/.     ______
           |  /\_|     |      \
           |  |___     |       |
           |   ---@    |_______|
        *  |  |   ----   |    |
         \ |  |_____
          \|________|
    [CompuCow Discovers Bug in Compiler](http://zeezide.com/en/products/codecows/index.html)

Oh, ages ago I did
[mod_objc](https://github.com/AlwaysRightInstitute/mod_objc1)
for Apache 1.3.

### Status

This is a demo. Do not use it for realz. At least not w/o our help ;->

### Who

**mod_swift** is brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We like feedback, GitHub stars, cool contract work,
presumably any form of praise you can think of.
We don't like people who are wrong.

There is a `#mod_swift` channel on the [Noze.io Slack](http://slack.noze.io).
