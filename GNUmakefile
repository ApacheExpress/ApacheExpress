# makefile

all :
	xcodebuild -scheme Demos -workspace UseMe.xcworkspace build

clean :
	rm -f httpd.pid
	rm -rf .libs Debug Release

clean-derived:
	rm -rf $(HOME)/Library/Developer/Xcode/DerivedData

distclean : clean 

run : all
	( EXPRESS_VIEWS=mods_expressdemo/views httpd -X -d $(PWD) -f apache.conf )
	
