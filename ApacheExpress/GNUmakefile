# GNUmakefile

PACKAGE_DIR=..

include $(PACKAGE_DIR)/mod_swift/xcconfig/config.make

# Funny, order of the Swift files is relevant here, wildcard doesn't do it
module_http_SWIFT_FILES = \
	Sources/http/http_module.swift \
	Sources/http/Server.swift \
	Sources/http/MessageBase.swift \
	Sources/http/ServerResponse.swift \
	Sources/http/IncomingMessage.swift \
	Sources/http/ApacheExpressHandler.swift \
	Sources/http/Cookies.swift \
	Sources/http/HttpMisc.swift \
	Sources/http/QueryString.swift \
	Sources/http/URL.swift

ApacheExpress_SWIFT_FILES = \
	$(wildcard Sources/xsys/*.swift)    \
	$(wildcard Sources/leftpad/*.swift) \
	$(wildcard Sources/streams/*.swift) \
	$(wildcard Sources/process/*.swift) \
	$(wildcard Sources/fs/*.swift)      \
	$(wildcard Sources/json/*.swift)    \
	$(wildcard Sources/console/*.swift) \
	$(module_http_SWIFT_FILES)          \
	$(wildcard Sources/connect/*.swift) \
	$(wildcard Sources/express/*.swift)


# This behaves like an Apache module, it uses Apache2 and hence needs
# to defer linking to the runtime
ApacheExpress_LDFLAGS = -undefined dynamic_lookup
ApacheExpress_INCLUDE_DIRS = $(APACHE_MODULE_MAPS) $(APR_INCLUDE_DIRS) $(APACHE_INCLUDE_DIRS)

ApacheExpress_LIBS = mustache Freddy

include $(PACKAGE_DIR)/mod_swift/xcconfig/rules.make
