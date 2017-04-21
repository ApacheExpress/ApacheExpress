# Dockerfile
#
# docker run --name mod_swift-demo -p 8042:8042 -d modswift/mod_swift-demo
#
#	time docker build -t modswift/mod_swift-demo:latest \
#	                  -t modswift/mod_swift-demo:3.1.0  \
#		                -f mod_swift-demo.dockerfile \
#		                .
#
FROM swift:3.1.0

ARG MOD_SWIFT_VERSION=0.7.6

# rpi-swift sets it to swift
USER root

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -q update
RUN apt-get install -y wget curl \
       autoconf libtool pkg-config \
       apache2 apache2-dev

# dirty hack to get Swift module for APR working on Linux
# (Note: I've found a better way, stay tuned.)
RUN bash -c "\
    head -n -6 /usr/include/apr-1.0/apr.h > /tmp/zz-apr.h; \
    echo ''                              >> /tmp/zz-apr.h; \
    echo '// mod_swift build hack'       >> /tmp/zz-apr.h; \
    echo 'typedef int pid_t;'            >> /tmp/zz-apr.h; \
    tail -n 6 /usr/include/apr-1.0/apr.h >> /tmp/zz-apr.h; \
    mv /usr/include/apr-1.0/apr.h /usr/include/apr-1.0/apr-original.h; \
    mv /tmp/zz-apr.h /usr/include/apr-1.0/apr.h"


# fixup Swift docker install, CoreFoundation lacks other-r flags
#   https://github.com/swiftdocker/docker-swift/issues/70
RUN chmod -R o+r /usr/lib/swift


# create Swift user

RUN useradd --create-home --shell /bin/bash swift
USER swift
WORKDIR /home/swift

RUN bash -c "curl -L https://github.com/AlwaysRightInstitute/mod_swift/archive/$MOD_SWIFT_VERSION.tar.gz | tar zx"

WORKDIR /home/swift/mod_swift-$MOD_SWIFT_VERSION

RUN make all

EXPOSE 8042

CMD LD_LIBRARY_PATH="$PWD/.libs:$LD_LIBRARY_PATH" \
    EXPRESS_VIEWS=mods_expressdemo/views apache2 \
    -X -d $PWD -f apache-ubuntu.conf
