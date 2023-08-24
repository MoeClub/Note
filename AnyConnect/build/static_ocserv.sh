#!/bin/bash -e

# Build static ocserv 
#                   by MoeClub

# apt install -y gcc bison gawk make autoconf pkg-config xz-utils

#################
#################

ver_glibc=2.31
ver_libev=4.33
ver_nettle=3.7.3
ver_gnutls=3.6.16
ver_ocserv=1.2.1

#################
#################

cores=$(grep -c '^processor' /proc/cpuinfo)
installPrefix="/tmp/build"

export CC=/usr/bin/gcc
export PKG_CONFIG_SYSROOT_DIR="$installPrefix"
export PKG_CONFIG_LIBDIR="$installPrefix/lib/pkgconfig:$installPrefix/lib64/pkgconfig"


#################
#################

rm -rf $installPrefix
mkdir -p $installPrefix
ln -s . $installPrefix/usr
ln -s . $installPrefix/local

#################
#################

# glibc
cd /tmp
wget --no-check-certificate -4 -O glibc.tar.gz https://ftp.gnu.org/pub/gnu/glibc/glibc-${ver_glibc}.tar.gz
[ -d glibc ] && rm -rf glibc
mkdir -p glibc; tar -xz -f glibc.tar.gz -C glibc --strip-components=1;
mkdir -p glibc/build; cd glibc/build
CFLAGS="-I$installPrefix/include -ffloat-store -O2 --static" \
LDFLAGS="-L$installPrefix/lib -L$installPrefix/lib64 -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
../configure \
  --prefix=$installPrefix \
  --enable-static --enable-static-nss \
	--disable-nscd --disable-sanity-checks
[ $? -eq 0 ] || exit 1 
make -j$cores
[ $? -eq 0 ] || exit 1 
make install
find "$installPrefix/lib" ! -type d ! -name "*.a" -delete

# libev
cd /tmp
wget --no-check-certificate -4 -O libev.tar.gz http://dist.schmorp.de/libev/Attic/libev-${ver_libev}.tar.gz
[ -d libev ] && rm -rf libev
mkdir -p libev; tar -xz -f libev.tar.gz -C libev --strip-components=1;
cd libev
CFLAGS="-I$installPrefix/include -ffloat-store -O0 --static" \
LDFLAGS="-L$installPrefix/lib -L$installPrefix/lib64 -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
./configure \
  --enable-static \
	--disable-shared
[ $? -eq 0 ] || exit 1 
make -j$cores
[ $? -eq 0 ] || exit 1 
make DESTDIR=$installPrefix install

# Nettle
cd /tmp
wget --no-check-certificate -4 -O nettle.tar.gz https://ftp.gnu.org/gnu/nettle/nettle-${ver_nettle}.tar.gz
[ -d nettle ] && rm -rf nettle
mkdir -p nettle; tar -xz -f nettle.tar.gz -C nettle --strip-components=1;
cd nettle
CFLAGS="-I$installPrefix/include -ffloat-store -O0 --static" \
LDFLAGS="-L$installPrefix/lib -L$installPrefix/lib64 -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
./configure \
  --enable-mini-gmp --enable-x86-aesni --enable-arm-neon --enable-static \
	--disable-{documentation,shared,rpath}
[ -f ./cnd-memcpy.c ] && sed -i 's/cnd-copy\.c /&cnd-memcpy.c /' Makefile
[ -f ./shake256.c ] && sed -i 's/cnd-copy\.c /&shake256.c /' Makefile
[ $? -eq 0 ] || exit 1 
make -j$cores
[ $? -eq 0 ] || exit 1 
make DESTDIR=$installPrefix install

# GnuTLS
cd /tmp
wget --no-check-certificate -4 -O gnutls.tar.xz https://www.gnupg.org/ftp/gcrypt/gnutls/v${ver_gnutls%.*}/gnutls-${ver_gnutls}.tar.xz
[ -d gnutls ] && rm -rf gnutls
mkdir -p gnutls; tar -xJ -f gnutls.tar.xz -C gnutls --strip-components=1;
cd gnutls
CFLAGS="-I$installPrefix/include -ffloat-store -O0 --static" \
LDFLAGS="-L$installPrefix/lib -L$installPrefix/lib64 -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
./configure \
  --with-nettle-mini --with-included-{libtasn1,unistring} \
	--without-p11-kit --enable-static --enable-openssl-compatibility \
	--disable-{doc,tools,cxx,tests,nls,guile,rpath,shared}
[ $? -eq 0 ] || exit 1 
make -j$cores
[ $? -eq 0 ] || exit 1 
make DESTDIR=$installPrefix install

# readline.h
cat >$installPrefix/include/readline.h <<EOF
#ifndef READLINE_H
#define READLINE_H
typedef char *rl_compentry_func_t(const char*, int);
typedef char **rl_completion_func_t(const char*, int, int);
extern char *rl_line_buffer;
extern char *rl_readline_name;
extern rl_completion_func_t *rl_attempted_completion_function;
extern rl_compentry_func_t *rl_completion_entry_function;
extern int rl_completion_query_items;
char *readline(const char *prompt);
void add_history(const char *string);
int rl_reset_terminal(const char *terminal_name);
char **rl_completion_matches(const char *text, void *entry_func);
void rl_redisplay(void);
#endif
EOF
# readline.c
$CC -xc - -c -o readline.o -ffloat-store -O0 <<EOF
#include <stdio.h>
#include <string.h>
char *rl_line_buffer = NULL;
char *rl_readline_name;
void *rl_attempted_completion_function;
void *rl_completion_entry_function;
int rl_completion_query_items;
char *readline(const char *prompt) {
	char buf[512], *ptr;
	if(prompt) printf("%s", prompt);
	fflush(stdout); ptr = buf;
	while((*ptr = getchar()) != '\n') ptr++;
	*ptr = '\0';
	return strdup(buf);
}
void add_history(const char *string) {}
int rl_reset_terminal(const char *terminal_name) {return 0;}
char **rl_completion_matches(const char *text, void *entry_func) {return NULL;}
void rl_redisplay(void) {}
EOF
# readline.a
ar rcs $installPrefix/lib/libreadline.a readline.o
rm -rf readline.o


# OpenConnect Server
cd /tmp
rm -rf $HOME/ocserv-build
mkdir -p $HOME/ocserv-build
wget --no-check-certificate -4 -O ocserv.tar.xz ftp://ftp.infradead.org/pub/ocserv/ocserv-${ver_ocserv}.tar.xz
[ -d ocserv ] && rm -rf ocserv
mkdir -p ocserv; tar -xJ -f ocserv.tar.xz -C ocserv --strip-components=1;
cd ocserv
#autoreconf -fvi
sed -i 's/#define DEFAULT_CONFIG_ENTRIES 96/#define DEFAULT_CONFIG_ENTRIES 200/' src/vpn.h
sed -i 's/login_end = OC_LOGIN_END;/&\n\t\tif (ws->req.user_agent_type == AGENT_UNKNOWN) {\n\t\t\tcstp_cork(ws);\n\t\t\tret = (cstp_printf(ws, "HTTP\/1.%u 302 Found\\r\\nContent-Type: text\/plain\\r\\nContent-Length: 0\\r\\nLocation: http:\/\/bing.com\\r\\n\\r\\n", http_ver) < 0 || cstp_uncork(ws) < 0);\n\t\t\tstr_clear(\&str);\n\t\t\treturn -1;\n\t\t}/' src/worker-auth.c
#sed -i 's/case AC_PKT_DPD_OUT:/&\n\t\tws->last_nc_msg = now;/' src/worker-auth.c
#sed -i 's/\$LIBS \$LIBEV/\$LIBEV \$LIBS/g' configure
CFLAGS="-I$installPrefix/include -ffloat-store -O0 --static" \
LDFLAGS="-L$installPrefix/lib -L$installPrefix/lib64 -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
LIBS="-lev -lm -lnettle -lhogweed -lreadline" \
./configure --prefix=/usr \
	--disable-rpath \
	--with-local-talloc \
	--without-{root-tests,docker-tests,nuttcp-tests} \
	--without-{protobuf,maxmind,geoip,liboath,pam,radius,utmp,lz4,http-parser,gssapi,pcl-lib}
[ $? -eq 0 ] || exit 1 
make -j$cores
[ $? -eq 0 ] || exit 1 
make DESTDIR=$HOME/ocserv-build install

# Package
cd $HOME/ocserv-build
for item in `find . -type f`; do strip -s "$item" 2>/dev/null; done
case `uname -m` in aarch64|arm64) arch="arm64";; x86_64|amd64) arch="amd64";; *) arch="unknown";; esac
tar -cvf "../ocserv_${arch}_v${ver_ocserv}.tar" ./
# tar --overwrite -xvf "ocserv_${arch}_v${ver_ocserv}.tar" -C /

