# GNUmakefile

# Variables to set:
#   xyz_SWIFT_MODULES          - modules in the same package
#   xyz_EXTERNAL_SWIFT_MODULES - modules in a different package
#   xyz_SWIFT_FILES            - defaults to *.swift */*.swift
#   xyz_TYPE - [tool / library]
#   xys_INCLUDE_DIRS
#   xys_LIB_DIRS
#   xys_LIBS

ifeq ($($(PACKAGE)_TYPE),ApacheCModule)
  ifeq ($(USE_APXS),no)
    ifeq ($(UNAME_S),Darwin)
      $(error missing Apache apxs)
    else
      $(error missing Apache apxs, did you install apache2-dev?)
    endif
  else
    LIBTOOL_CPREFIX=-Wc,
    LIBTOOL_LDPREFIX=-Wl,
    APXS_EXTRA_CFLAGS_LIBTOOL  = $(addprefix $(LIBTOOL_CPREFIX),$(APXS_EXTRA_CFLAGS))
    APXS_EXTRA_LDFLAGS_LIBTOOL = $(addprefix $(LIBTOOL_LDPREFIX),$(APXS_EXTRA_LDFLAGS))
    APXS_LIBTOOL_BUILD_RESULT  = .libs/$(PACKAGE).so
  endif
endif


ifeq ($($(PACKAGE)_TYPE),ApacheSwiftModule)
  APACHE_INCLUDE_FLAGS = $(addprefix -I ,$(APR_INCLUDE_DIRS)) $(addprefix -I ,$(APACHE_INCLUDE_DIRS))

  APACHE_SWIFT_MODULE_INTERNAL_LINK_FLAGS = -undefined dynamic_lookup

  APACHE_SWIFT_MODULE_INTERNAL_LINK_FLAGS += -rpath "$(realpath $(SWIFT_BUILD_DIR))"
  ifeq ($(UNAME_S),Darwin)
    TOOLCHAIN_DIR=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
    APACHE_SWIFT_MODULE_INTERNAL_LINK_FLAGS += -rpath $(TOOLCHAIN_DIR)/usr/lib/swift/macosx
  endif

  SWIFT_INTERNAL_LINK_FLAGS += $(addprefix -Xlinker ,$(APACHE_SWIFT_MODULE_INTERNAL_LINK_FLAGS))
  SWIFT_INTERNAL_LINK_FLAGS += $(addprefix -l, $(SWIFT_RUNTIME_LIBS))
endif


ifeq ($($(PACKAGE)_TYPE),library)
  ifeq ($(UNAME_S),Darwin)
    LIBRARY_SWIFT_MODULE_INTERNAL_LINK_FLAGS += -install_name @rpath/$(SHARED_LIBRARY_PREFIX)$(PACKAGE)$(SHARED_LIBRARY_SUFFIX)
  endif
  SWIFT_INTERNAL_LINK_FLAGS += $(addprefix -Xlinker ,$(LIBRARY_SWIFT_MODULE_INTERNAL_LINK_FLAGS))
endif


# link against all Noze modules, if the user didn't explicitly specify modules
ifeq ($($(PACKAGE)_SWIFT_MODULES),)
ifneq ($(NOZE_DIR),)
$(PACKAGE)_SWIFT_MODULES = $(NOZE_ALL_MODULES)
endif
endif

# linked modules
$(PACKAGE)_LIBS += \
	$($(PACKAGE)_SWIFT_MODULES) \
	$($(PACKAGE)_EXTERNAL_SWIFT_MODULES)

# lookup modules in parent directory (the directory above the Package.swift dir)
ifneq ($($(PACKAGE)_EXTERNAL_SWIFT_MODULES),)
EXT_DIR=$(PACKAGE_DIR)/..
$(PACKAGE)_INCLUDE_DIRS += \
  $(addsuffix /$(SWIFT_REL_BUILD_DIR),$(addprefix $(EXT_DIR)/,$($(PACKAGE)_EXTERNAL_SWIFT_MODULES)))
$(PACKAGE)_LIB_DIRS     += \
  $(addsuffix /$(SWIFT_REL_BUILD_DIR),$(addprefix $(EXT_DIR)/,$($(PACKAGE)_EXTERNAL_SWIFT_MODULES)))
endif

# lookup modules in Noze directory (when set)
ifneq ($(NOZE_DIR),)
$(PACKAGE)_INCLUDE_DIRS += $(NOZE_DIR)/$(SWIFT_REL_BUILD_DIR)
$(PACKAGE)_LIB_DIRS     += $(NOZE_DIR)/$(SWIFT_REL_BUILD_DIR)
endif


# Linking flags (TODO: name is bad)
$(PACKAGE)_SWIFT_LINK_FLAGS = \
  $(addprefix -Xlinker ,$($(PACKAGE)_LDFLAGS)) \
  $(addprefix -I,$($(PACKAGE)_INCLUDE_DIRS)) \
  $(addprefix -L,$($(PACKAGE)_LIB_DIRS)) \
  $(SWIFT_INTERNAL_LINK_FLAGS) $(SWIFT_INTERNAL_INCLUDE_FLAGS) \
  $(addprefix -l,$($(PACKAGE)_LIBS))


# rules

ifeq ($($(PACKAGE)_TYPE),tool)
all : all-tool
endif
ifeq ($($(PACKAGE)_TYPE),library)
all : all-library
endif
ifeq ($($(PACKAGE)_TYPE),testsuite)
all : all-testsuite
endif
ifeq ($($(PACKAGE)_TYPE),ApacheCModule)
all : all-apache-c-module
endif
ifeq ($($(PACKAGE)_TYPE),ApacheSwiftModule)
all : all-apache-swift-module
endif

TOOL_BUILD_RESULT      = $(SWIFT_BUILD_DIR)/$(PACKAGE)
LIBRARY_BUILD_RESULT   = $(SWIFT_BUILD_DIR)/$(SHARED_LIBRARY_PREFIX)$(PACKAGE)$(SHARED_LIBRARY_SUFFIX)
TESTSUITE_BUILD_RESULT = $(SWIFT_BUILD_DIR)/$(SHARED_LIBRARY_PREFIX)$(PACKAGE)TestSuite$(SHARED_LIBRARY_SUFFIX)

APACHE_C_MODULE_BUILD_RESULT     = $(SWIFT_BUILD_DIR)/$(PACKAGE).so
APACHE_SWIFT_MODULE_BUILD_RESULT = $(SWIFT_BUILD_DIR)/$(PACKAGE).so

clean :
	rm -rf $(TOOL_BUILD_RESULT) $(LIBRARY_BUILD_RESULT) \
	       $(APACHE_C_MODULE_BUILD_RESULT) $(APACHE_SWIFT_MODULE_BUILD_RESULT) \
	       *.o *.slo *.la *.lo Sources/*.o Sources/*.slo Sources/*.la Sources/*.lo \
	       .libs Sources/.libs
# rm -rf $(SWIFT_BUILD_DIR)

all-tool : $(TOOL_BUILD_RESULT)

all-library : $(LIBRARY_BUILD_RESULT)

all-testsuite : $(TESTSUITE_BUILD_RESULT)

all-apache-c-module : $(APACHE_C_MODULE_BUILD_RESULT)

all-apache-swift-module : $(APACHE_SWIFT_MODULE_BUILD_RESULT)


# TODO: would be nice to make build dependend on other modules

$(TOOL_BUILD_RESULT) : $($(PACKAGE)_SWIFT_FILES)
	@mkdir -p $(@D)
	$(SWIFTC) $(SWIFT_INTERNAL_BUILD_FLAGS) \
	   -emit-executable \
	   -emit-module -module-name $(PACKAGE) \
           $($(PACKAGE)_SWIFT_FILES) \
           -o $@ $($(PACKAGE)_SWIFT_LINK_FLAGS)

$(LIBRARY_BUILD_RESULT) : $($(PACKAGE)_SWIFT_FILES)
	@mkdir -p $(@D)
	$(SWIFTC) $(SWIFT_INTERNAL_BUILD_FLAGS) \
	   -emit-library \
	   -emit-module -module-name $(PACKAGE) \
           $($(PACKAGE)_SWIFT_FILES) \
           -o $@ $($(PACKAGE)_SWIFT_LINK_FLAGS)


ifeq ($($(PACKAGE)_TYPE),ApacheCModule)
# Note: Cannot change target location via apxs -o, hence
#       we move it over after the build.
$(APACHE_C_MODULE_BUILD_RESULT) : $($(PACKAGE)_C_FILES)
	@mkdir -p $(@D)
	$(APXS) $(APXS_EXTRA_CFLAGS_LIBTOOL) $(APXS_EXTRA_LDFLAGS_LIBTOOL) \
	  -n $(PACKAGE)    \
	  -o $(PACKAGE).so \
          -c $($(PACKAGE)_C_FILES)
	rm -f $(APACHE_C_MODULE_BUILD_RESULT)
	mv $(APXS_LIBTOOL_BUILD_RESULT) $(APACHE_C_MODULE_BUILD_RESULT)
endif

ifeq ($($(PACKAGE)_TYPE),ApacheSwiftModule)

$(APACHE_SWIFT_MODULE_BUILD_RESULT) : $($(PACKAGE)_SWIFT_FILES)
	@mkdir -p $(@D)
	$(SWIFTC) $(SWIFT_INTERNAL_BUILD_FLAGS) \
	   $(APACHE_INCLUDE_FLAGS) \
	   -I $(APACHE_MODULE_MAPS) \
	   $(addprefix -Xcc ,$(APR_CFLAGS)) \
           -Xcc -pthread \
	   -emit-library \
	   -emit-module -module-name $(PACKAGE) \
           $($(PACKAGE)_SWIFT_FILES) \
           -o $@ $($(PACKAGE)_SWIFT_LINK_FLAGS)
endif

# load extra rules

-include rules-$($(PACKAGE)_TYPE).make
