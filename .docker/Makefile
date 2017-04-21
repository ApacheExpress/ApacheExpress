# Makefile

all : demo

demo :
	time docker build \
		-t modswift/mod_swift-demo:latest \
		-t modswift/mod_swift-demo:3.1.0 \
		-f mod_swift-demo.dockerfile \
		$(PWD)

demo-dev :
	time docker build \
		-t modswift/mod_swift-demo-dev:latest \
		-t modswift/mod_swift-demo-dev:3.1.0 \
		-f mod_swift-demo-dev.dockerfile \
		$(PWD)
