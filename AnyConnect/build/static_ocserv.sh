#!/bin/bash -e
cd /tmp

#################
#################

ver_nettle=3.4.1
ver_gnutls=3.6.7
ver_libev=4.25
ver_ocserv=1.1.0

#################
#################

cores=$(grep -c '^processor' /proc/cpuinfo)
instPrefix="/tmp/inst"

rm -rf $instPrefix
mkdir -p $instPrefix
ln -s . $instPrefix/usr
ln -s . $instPrefix/local

export CC=/usr/bin/gcc
export PKG_CONFIG_SYSROOT_DIR="$instPrefix"
export PKG_CONFIG_LIBDIR="$instPrefix/lib/pkgconfig"

# Nettle
wget --no-check-certificate -4 -O nettle.tar.gz https://ftp.gnu.org/gnu/nettle/nettle-${ver_nettle}.tar.gz
[ -d nettle ] && rm -rf nettle
mkdir -p nettle; tar -xz -f nettle.tar.gz -C nettle --strip-components=1;
cd nettle
./configure \
	--enable-mini-gmp --enable-x86-aesni \
	--disable-{documentation,shared}
sed -i 's/cnd-copy\.c /&cnd-memcpy.c /' Makefile
make -j$cores
make DESTDIR=$instPrefix install
cd ..

# GnuTLS
wget --no-check-certificate -4 -O gnutls.tar.xz ftp://ftp.gnutls.org/gcrypt/gnutls/v${ver_gnutls%.*}/gnutls-${ver_gnutls}.tar.xz
[ -d gnutls ] && rm -rf gnutls
mkdir -p gnutls; tar -xJ -f gnutls.tar.xz -C gnutls --strip-components=1;
cd gnutls
CFLAGS=-I$instPrefix/include LDFLAGS=-L$instPrefix/lib \
./configure \
	--with-nettle-mini --with-included-{libtasn1,unistring} \
	--without-p11-kit --disable-shared \
	--disable-{doc,tools,cxx,tests,nls,guile}
make -j$cores
make DESTDIR=$instPrefix install
cd ..

# libev
wget --no-check-certificate -4 -O libev.tar.gz http://dist.schmorp.de/libev/Attic/libev-${ver_libev}.tar.gz
[ -d libev ] && rm -rf libev
mkdir -p libev; tar -xz -f libev.tar.gz -C libev --strip-components=1;
cd libev
./configure --disable-shared
make -j$cores
make DESTDIR=$instPrefix install
cd ..

# readline.h
cat >$instPrefix/include/readline.h <<EOF
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
$CC -xc - -c -o readline.o -O2 <<EOF
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
ar rcs $instPrefix/lib/libreadline.a readline.o
rm -rf readline.o

# OpenConnect server
mkdir -p ./ocserv-bin
wget --no-check-certificate -4 ftp://ftp.infradead.org/pub/ocserv/ocserv-${ver_ocserv}.tar.xz -O ocserv.tar.xz
[ -d ocserv ] && rm -rf ocserv
mkdir -p ocserv; tar -xJ -f ocserv.tar.xz -C ocserv --strip-components=1;
cd ocserv
autoreconf -fvi
sed -i 's/\$LIBS \$LIBEV/\$LIBEV \$LIBS/g' configure
CFLAGS="-I$instPrefix/include" \
LDFLAGS="-L$instPrefix/lib -fPIC -static -pthread -lpthread" \
LIBNETTLE_LIBS="-lnettle -lhogweed" LIBREADLINE_LIBS="-lreadline" \
LIBS="-lm" \
./configure --prefix=/usr \
	--disable-rpath \
	--with-local-talloc \
	--without-{root-tests,docker-tests,nuttcp-tests} \
	--without-{protobuf,maxmind,geoip,liboath,pam,radius,utmp,lz4,http-parser,gssapi,pcl-lib}
make -j$cores
make DESTDIR=./ocserv-bin install
cd ..

