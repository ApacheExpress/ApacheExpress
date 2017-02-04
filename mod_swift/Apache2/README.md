# Module maps for Apache, APR and our own wrapper

Note: Those does not link any library, the API is loaded already
      into Apache.

TBD:  Maybe we should generate the module maps with the right
      pathes when building `mod_swift`.

Also: Those are not quite right. That is, they re-export some
      things resulting in dupe-symbols. This needs a cleanup.

## Linux

hitting this:
- https://bugs.swift.org/browse/SR-1251
  - worked around by hacking /usr/include/apr-1.0/apr.h and
    adding `typedef int pid_t;` at the bottom

    