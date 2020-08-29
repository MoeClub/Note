#!/bin/bash -e

cd /tmp

CC=/usr/bin/gcc

ver_nettle=3.4.1
ver_gnutls=3.6.7
ver_libev=4.25
ver_ocserv=1.1.0

#################
#################
#################

cores=$(grep -c '^processor' /proc/cpuinfo)
instprefix="$PWD/_inst"

rm -rf $instprefix
mkdir -p $instprefix
ln -s . $instprefix/usr
ln -s . $instprefix/local

export CC
export PKG_CONFIG_SYSROOT_DIR="$instprefix"
export PKG_CONFIG_LIBDIR="$instprefix/lib/pkgconfig"

# Nettle
[ -f nettle.tar.gz ] || wget https://ftp.gnu.org/gnu/nettle/nettle-${ver_nettle}.tar.gz -O nettle.tar.gz
[ -d nettle ] && rm -rf nettle
mkdir nettle; tar -xz -f nettle.tar.gz -C nettle --strip-components=1;
cd nettle
cat >>mini-gmp.c <<"HEREDOC"
void mpz_div_2exp(mpz_t quotient, mpz_t dividend, unsigned long int exponent_of_2)
{
	mpz_tdiv_q_2exp(quotient, dividend, exponent_of_2);
}
void mpz_mod_2exp(mpz_t remainder, mpz_t dividend, unsigned long int exponent_of_2)
{
	mpz_tdiv_r_2exp(remainder, dividend, exponent_of_2);
}
HEREDOC
./configure \
	--enable-mini-gmp --enable-x86-aesni \
	--disable-{documentation,shared}
sed 's|cnd-copy\.c |&cnd-memcpy.c |' Makefile -i
make -j$cores
make DESTDIR=$instprefix install
cd ..

# GnuTLS
wget -O gnutls.tar.xz ftp://ftp.gnutls.org/gcrypt/gnutls/v${ver_gnutls%.*}/gnutls-${ver_gnutls}.tar.xz
[ -d gnutls ] && rm -rf gnutls
mkdir gnutls; tar -xJ -f gnutls.tar.xz -C gnutls --strip-components=1;
cd gnutls
CFLAGS=-I$instprefix/include LDFLAGS=-L$instprefix/lib \
./configure \
	--with-nettle-mini --with-included-{libtasn1,unistring} \
	--without-p11-kit --disable-shared \
	--disable-{doc,tools,cxx,tests,nls,guile}
make -j$cores
make DESTDIR=$instprefix install
cd ..

# libev
wget -O libev.tar.gz http://dist.schmorp.de/libev/Attic/libev-${ver_libev}.tar.gz
[ -d libev ] && rm -rf libev
mkdir libev; tar -xz -f libev.tar.gz -C libev --strip-components=1;
cd libev
./configure --disable-shared
make -j$cores
make DESTDIR=$instprefix install
cd ..

# Readline stub
cat >$instprefix/include/readline.h <<"HEREDOC"
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
HEREDOC
$CC -xc - -c -o tmp.o -O2 <<"HEREDOC"
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
HEREDOC
ar rcs $instprefix/lib/libreadline.a tmp.o
rm tmp.o

# OpenConnect server
wget ftp://ftp.infradead.org/pub/ocserv/ocserv-${ver_ocserv}.tar.xz -O ocserv.tar.xz
[ -d ocserv ] && rm -rf ocserv
mkdir ocserv; tar -xJ -f ocserv.tar.xz -C ocserv --strip-components=1;
cd ocserv
CFLAGS="-I$instprefix/include" \
LDFLAGS="-L$instprefix/lib -static -s" \
LIBNETTLE_LIBS="-lnettle -lhogweed" LIBREADLINE_LIBS=-lreadline \
./configure --prefix=/ \
	--without-{protobuf,pam,radius,http-parser,lz4,gssapi,pcl-lib}
make -j$cores
make DESTDIR=$PWD/../output install
cd ..



