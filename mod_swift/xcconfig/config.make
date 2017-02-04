# GNUmakefile

debug=on
swiftv=3
timeswiftc=no
spm=no
xcodebuild=no
brew=yes

NOZE_DID_INCLUDE_CONFIG_MAKE=yes

# Common configurations

SHARED_LIBRARY_PREFIX=lib

UNAME_S := $(shell uname -s)

# Apache stuff

APXS=$(shell which apxs)
ifneq ($(APXS),)
  HAVE_APXS=yes
  ifeq ($(UNAME_S),Darwin)
    ifeq (/usr/sbin/apxs,$(APXS)) # this one is utterly b0rked
      HAVE_APXS=no
    endif
  endif
else
  HAVE_APXS=no
endif
USE_APXS=$(HAVE_APXS)

ifeq ($(USE_APXS),yes)
  APACHE_INCLUDE_DIRS += $(shell $(APXS) -q INCLUDEDIR)
  APACHE_CFLAGS       += $(shell $(APXS) -q CFLAGS)
  APACHE_CFLAGS_SHLIB += $(shell $(APXS) -q CFLAGS_SHLIB)
  APACHE_LD_SHLIB     += $(shell $(APXS) -q LD_SHLIB)

  APXS_EXTRA_CFLAGS=
  APXS_EXTRA_LDFLAGS=
endif


# System specific configuration

USE_BREW=no

ifeq ($(UNAME_S),Darwin)
  ifeq ($(USE_APXS),no)
    xcodebuild=yes
  endif

  # lookup toolchain

  SWIFT_TOOLCHAIN_BASEDIR=/Library/Developer/Toolchains
  SWIFT_TOOLCHAIN=$(SWIFT_TOOLCHAIN_BASEDIR)/swift-latest.xctoolchain/usr/bin
  ifeq ("$(wildcard $(SWIFT_TOOLCHAIN))","")
    SWIFT_TOOLCHAIN=$(shell dirname $(shell xcrun --toolchain swift-latest -f swiftc))
  endif

  # platform settings

  SHARED_LIBRARY_SUFFIX=.dylib
  DEFAULT_SDK=$(shell xcrun -sdk macosx --show-sdk-path)

  DEPLOYMENT_TARGET=x86_64-apple-macosx10.11
  SWIFT_INTERNAL_MAKE_BUILD_FLAGS += -sdk $(DEFAULT_SDK)
  SWIFT_INTERNAL_MAKE_BUILD_FLAGS += -target $(DEPLOYMENT_TARGET)

  ifeq ($(USE_APXS),yes)
    APXS_EXTRA_CFLAGS += -Wno-nullability-completeness

    ifneq ($(brew),no)
      BREW=$(shell which brew)
      ifneq (,$(BREW)) # use Homebrew locations
        BREW_APR_LOCATION=$(shell $(BREW) --prefix apr)
        BREW_APU_LOCATION=$(shell $(BREW) --prefix apr-util)
        APR_CONFIG=$(wildcard $(BREW_APR_LOCATION)/bin/apr-1-config)
        APU_CONFIG=$(wildcard $(BREW_APU_LOCATION)/bin/apu-1-config)
        USE_BREW=yes
      endif
    endif
  endif

  SWIFT_RUNTIME_LIBS = swiftFoundation swiftDarwin swiftCore
else # Linux
  xcode=no

  # determine linux version
  OS=$(shell lsb_release -si | tr A-Z a-z)
  VER=$(shell lsb_release -sr)

  SHARED_LIBRARY_SUFFIX=.so

  SWIFT_RUNTIME_LIBS = Foundation swiftCore
endif


ifeq ($(xcodebuild),yes)
  USE_XCODEBUILD=yes
endif


# APR/APU default setup (Homebrew handled above)

ifeq (,$(APR_CONFIG))
  APR_CONFIG=$(shell which apr-1-config)
  ifeq (,$(APU_CONFIG))
    APU_CONFIG=$(shell which apu-1-config)
  endif
endif
ifneq (,$(APR_CONFIG))
  APR_INCLUDE_DIRS = $(shell $(APR_CONFIG) --includedir)
  APR_CFLAGS       = $(shell $(APR_CONFIG) --cflags)
  APR_LDFLAGS      = $(shell $(APR_CONFIG) --ldflags)
  APR_LIBS         = $(shell $(APR_CONFIG) --libs)

  ifneq (,$(APU_CONFIG))
    APR_INCLUDE_DIRS += $(shell $(APU_CONFIG) --includedir)
    # APU has no --cflags
    APR_LDFLAGS += $(shell $(APU_CONFIG) --ldflags)
    APR_LIBS    += $(shell $(APU_CONFIG) --libs)
  endif
endif


# Profile compile performance?

ifeq ($(timeswiftc),yes)
# http://irace.me/swift-profiling
SWIFT_INTERNAL_MAKE_BUILD_FLAGS += -Xfrontend -debug-time-function-bodies
endif


# Lookup Swift binary, decide whether to use SPM

ifneq ($(SWIFT_TOOLCHAIN),)
  SWIFT_TOOLCHAIN_PREFIX=$(SWIFT_TOOLCHAIN)/
  SWIFT_BIN=$(SWIFT_TOOLCHAIN_PREFIX)swift
  SWIFT_BUILD_TOOL_BIN=$(SWIFT_BIN)-build
  ifeq ("$(wildcard $(SWIFT_BUILD_TOOL_BIN))", "")
    HAVE_SPM=no
  else
    HAVE_SPM=yes
  endif
else
  SWIFT_TOOLCHAIN_PREFIX=
  SWIFT_BIN=swift
  SWIFT_BUILD_TOOL_BIN=$(SWIFT_BIN)-build
  WHICH_SWIFT_BUILD_TOOL_BIN=$(shell which $(SWIFT_BUILD_TOOL_BIN))
  ifeq ("$(wildcard $(WHICH_SWIFT_BUILD_TOOL_BIN))", "")
    HAVE_SPM=no
  else
    HAVE_SPM=yes
  endif
endif

ifeq ($(spm),no)
  USE_SPM=no
else
  ifeq ($(spm),yes)
    USE_SPM=yes
  else # detect
    USE_SPM=$(HAVE_SPM)
  endif
endif


ifeq ($(USE_SPM),no)
SWIFT_INTERNAL_BUILD_FLAGS += $(SWIFT_INTERNAL_MAKE_BUILD_FLAGS)
endif

SWIFTC=$(SWIFT_BIN)c


# Tests

SWIFT_INTERNAL_TEST_FLAGS := # $(SWIFT_INTERNAL_BUILD_FLAGS)

# Debug or Release?

ifeq ($(debug),on)
  APXS_EXTRA_CFLAGS  += -g
  APXS_EXTRA_LDFLAGS += -g

  ifeq ($(USE_SPM),yes)
    SWIFT_INTERNAL_BUILD_FLAGS += --configuration debug
    SWIFT_REL_BUILD_DIR=.build/debug
  else
    SWIFT_INTERNAL_BUILD_FLAGS += -g
    SWIFT_REL_BUILD_DIR=.libs
  endif
else
  ifeq ($(USE_SPM),yes)
    SWIFT_INTERNAL_BUILD_FLAGS += --configuration release
    SWIFT_REL_BUILD_DIR=.build/release
  else
    SWIFT_REL_BUILD_DIR=.libs
  endif
endif
SWIFT_BUILD_DIR=$(PACKAGE_DIR)/$(SWIFT_REL_BUILD_DIR)


# Include/Link pathes

SWIFT_INTERNAL_INCLUDE_FLAGS += -I$(SWIFT_BUILD_DIR)
SWIFT_INTERNAL_LINK_FLAGS    += -L$(SWIFT_BUILD_DIR)


# Note: the invocations must not use swift-build, but 'swift build'
SWIFT_BUILD_TOOL=$(SWIFT_BIN) build $(SWIFT_INTERNAL_BUILD_FLAGS)
SWIFT_TEST_TOOL =$(SWIFT_BIN) test  $(SWIFT_INTERNAL_TEST_FLAGS)
SWIFT_CLEAN_TOOL=$(SWIFT_BIN) build --clean


# Module Maps

ifeq ($(UNAME_S),Darwin)
  ifeq ($(USE_BREW),yes) # use Homebrew locations
    APACHE_MODULE_MAPS=$(PACKAGE_DIR)/mod_swift/Apache2/brew
  else
    APACHE_MODULE_MAPS=$(PACKAGE_DIR)/mod_swift/Apache2/xcode8
  endif
else
  APACHE_MODULE_MAPS=$(PACKAGE_DIR)/mod_swift/Apache2/linux
endif
