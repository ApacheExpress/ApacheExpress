# makefile

all :
	xcodebuild -scheme mods_demo build

clean :
	rm -f httpd.pid
	rm -rf .libs Debug Release

clean-derived:
	rm -rf $(HOME)/Library/Developer/Xcode/DerivedData

distclean : clean 

run : all
	httpd -X -d $(PWD) -f apache.conf
	
