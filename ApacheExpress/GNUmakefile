# GNUmakefile

PACKAGE_DIR=..

include $(PACKAGE_DIR)/mod_swift/xcconfig/config.make

# This behaves like an Apache module, it uses Apache2 and hence needs
# to defer linking to the runtime
ApacheExpress_LDFLAGS = -undefined dynamic_lookup
ApacheExpress_INCLUDE_DIRS = $(APACHE_MODULE_MAPS) $(APR_INCLUDE_DIRS) $(APACHE_INCLUDE_DIRS)

ApacheExpress_LIBS = mustache Freddy ExExpress

include $(PACKAGE_DIR)/mod_swift/xcconfig/rules.make
