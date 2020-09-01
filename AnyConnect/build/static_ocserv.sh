#!/bin/bash -e
cd /tmp

#################
#################

ver_nettle=3.3
ver_gnutls=3.5.8
ver_libev=4.22
ver_ocserv=0.12.6

#################
#################

cores=$(grep -c '^processor' /proc/cpuinfo)
instPrefix="/tmp/inst"

export CC=/usr/bin/gcc
export PKG_CONFIG_SYSROOT_DIR="$instPrefix"
export PKG_CONFIG_LIBDIR="$instPrefix/lib/pkgconfig"


#################
#################

rm -rf $instPrefix
mkdir -p $instPrefix
ln -s . $instPrefix/usr
ln -s . $instPrefix/local

#################
#################

# Nettle
wget --no-check-certificate -4 -O nettle.tar.gz https://ftp.gnu.org/gnu/nettle/nettle-${ver_nettle}.tar.gz
[ -d nettle ] && rm -rf nettle
mkdir -p nettle; tar -xz -f nettle.tar.gz -C nettle --strip-components=1;
cd nettle
cat >>mini-gmp.c <<EOF
void mpz_div_2exp(mpz_t quotient, mpz_t dividend, unsigned long int exponent_of_2)
{
	mpz_tdiv_q_2exp(quotient, dividend, exponent_of_2);
}
void mpz_mod_2exp(mpz_t remainder, mpz_t dividend, unsigned long int exponent_of_2)
{
	mpz_tdiv_r_2exp(remainder, dividend, exponent_of_2);
}
EOF
CFLAGS="-I$instPrefix/include -fPIC -O2" LDFLAGS="-L$instPrefix/lib" \
./configure \
	--enable-mini-gmp --enable-x86-aesni --enable-static \
	--disable-{documentation,shared,rpath}
#sed -i 's/cnd-copy\.c /&cnd-memcpy.c /' Makefile
make -j$cores
[ $? -eq 0 ] || exit 1 
make DESTDIR=$instPrefix install
cd ..


# GnuTLS
wget --no-check-certificate -4 -O gnutls.tar.xz ftp://ftp.gnutls.org/gcrypt/gnutls/v${ver_gnutls%.*}/gnutls-${ver_gnutls}.tar.xz
[ -d gnutls ] && rm -rf gnutls
mkdir -p gnutls; tar -xJ -f gnutls.tar.xz -C gnutls --strip-components=1;
cd gnutls
sed -i '/gmp\.h/d' lib/nettle/int/dsa-fips.h
CFLAGS="-I$instPrefix/include -fPIC -O2" LDFLAGS="-L$instPrefix/lib" \
./configure \
	--with-nettle-mini --with-included-{libtasn1,unistring} \
	--without-p11-kit --enable-static \
	--disable-{doc,tools,cxx,tests,nls,guile,rpath,shared}
make -j$cores
[ $? -eq 0 ] || exit 1 
make DESTDIR=$instPrefix install
cd ..


# libev
wget --no-check-certificate -4 -O libev.tar.gz http://dist.schmorp.de/libev/Attic/libev-${ver_libev}.tar.gz
[ -d libev ] && rm -rf libev
mkdir -p libev; tar -xz -f libev.tar.gz -C libev --strip-components=1;
cd libev
CFLAGS="-I$instPrefix/include -fPIC -O2" LDFLAGS="-L$instPrefix/lib" \
./configure \
  --enable-static \
	--disable-{shared,rpath} 
make -j$cores
[ $? -eq 0 ] || exit 1 
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
$CC -xc - -c -o readline.o -fPIC -O2 <<EOF
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
rm -rf $HOME/ocserv-bin
mkdir -p $HOME/ocserv-bin
wget --no-check-certificate -4 -O ocserv.tar.xz ftp://ftp.infradead.org/pub/ocserv/ocserv-${ver_ocserv}.tar.xz
[ -d ocserv ] && rm -rf ocserv
mkdir -p ocserv; tar -xJ -f ocserv.tar.xz -C ocserv --strip-components=1;
cd ocserv
#autoreconf -fvi
sed -i 's/#define DEFAULT_CONFIG_ENTRIES 96/#define DEFAULT_CONFIG_ENTRIES 200/' src/vpn.h
sed -i 's/\$LIBS \$LIBEV/\$LIBEV \$LIBS/g' configure
CFLAGS="-I$instPrefix/include -fPIC -O2" \
LDFLAGS="-L$instPrefix/lib -static -s -pthread -lpthread" \
LIBNETTLE_LIBS="-lnettle -lhogweed" LIBREADLINE_LIBS="-lreadline" \
LIBS="-lm" \
./configure --prefix=/usr \
	--disable-rpath \
	--with-local-talloc \
	--without-{root-tests,docker-tests,nuttcp-tests} \
	--without-{protobuf,maxmind,geoip,liboath,pam,radius,utmp,lz4,http-parser,gssapi,pcl-lib}
make -j$cores
[ $? -eq 0 ] || exit 1 
make DESTDIR=$HOME/ocserv-bin install
cd ..

# cd $HOME/ocserv-bin
# tar -cvf "../ocserv_v0.12.6.tar" ./
# tar --overwrite -xvf ocserv_v0.12.6.tar -C /
