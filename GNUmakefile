# makefile

PACKAGE_DIR=.
debug=on

include mod_swift/xcconfig/config.make

ifeq ($(USE_XCODEBUILD),yes)

all :
	xcodebuild -scheme mods_echo -workspace UseMe.xcworkspace build

clean-derived:
	rm -rf $(HOME)/Library/Developer/Xcode/DerivedData

run : all
	( EXPRESS_VIEWS=mods_expressdemo/views httpd -X -d $(PWD) -f apache.conf )

else # apxs based build (e.g. Linux or brew on macOS)

all :
	@$(MAKE) -C mod_swift  all
	@$(MAKE) -C ThirdParty all
	@$(MAKE) -C mods_echo  all

clean ::
	@$(MAKE) -C mod_swift  clean
	@$(MAKE) -C ThirdParty clean
	@$(MAKE) -C mods_echo  clean

clean-derived:

ifeq ($(USE_BREW),yes)
run : all
	( httpd -X -d $(PWD) -f apache-brew.conf )
else
run : all
	( LD_LIBRARY_PATH="$(PWD)/.libs:$(LD_LIBRARY_PATH)" apache2 -X -d $(PWD) -f apache-ubuntu.conf )
endif

endif

clean ::
	rm -f httpd.pid
	rm -rf .libs .build Debug Release *.o

distclean :: clean
