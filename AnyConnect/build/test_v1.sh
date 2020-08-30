cd /tmp && wget ftp://ftp.infradead.org/pub/ocserv/ocserv-1.1.0.tar.xz -O ocserv.tar.xz

cd /tmp
[ -d ocserv ] && rm -rf ocserv
mkdir ocserv; tar -xJ -f ocserv.tar.xz -C ocserv --strip-components=1;
cd ocserv

# autoreconf -fvi

LIBGNUTLS_LIBS="-llibgnutls" \
CFLAGS="-I." \
LDFLAGS="-L. -static" \
./configure --without-{protobuf,pam,radius,http-parser,lz4,gssapi,pcl-lib}

