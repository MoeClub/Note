# docker pull alpine:latest
# docker rm -f alpine >/dev/null 2>&1; docker run --name alpine -it -v /mnt:/mnt alpine 
# docker exec -it alpine /bin/sh

apk update
apk add musl-dev gnutls-dev gnutls-utils lz4-dev
apk add libidn2-static libunistring-static libnl3-static
apk add wget xz openssl gcc autoconf make linux-headers gperf


TARGET="/mnt/ocserv"

VERSION_LIBEV="4.33"
VERSION_LIBSECCOMP="2.5.5"
VERSION_LZ4="1.10.0"
VERSION_NETTLE="3.10"
VERSION_GNUTLS="3.7.11"
VERSION_OCSERV="1.1.7"


# libev
function build_libev(){
	TMP=`mktemp -d`; trap "rm -rf $TMP" EXIT
	wget --no-check-certificate -qO- "http://dist.schmorp.de/libev/Attic/libev-${VERSION_LIBEV}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	CFLAGS="-ffloat-store -O0 --static" \
	LDFLAGS="-static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
		--prefix=/usr \
		--enable-static \
		--disable-shared
	[ $? -eq 0 ] || return 1
	make -j`nproc`
	[ $? -eq 0 ] || return 1
	make install
	return $?
}

# libseccomp
function build_libseccomp(){
	TMP=`mktemp -d`; trap "rm -rf $TMP" EXIT
	wget --no-check-certificate -qO- "https://github.com/seccomp/libseccomp/releases/download/v${VERSION_LIBSECCOMP}/libseccomp-${VERSION_LIBSECCOMP}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	CFLAGS="-ffloat-store -O0 --static" \
	LDFLAGS="-static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
		--prefix=/usr \
		--disable-shared \
		--enable-static
	sed -i 's/in_word_set/_in_word_set/g' src/syscalls.perf.c
	make -j`nproc` install
	return $?
}

# lz4
function build_lz4(){
	TMP=`mktemp -d`; trap "rm -rf $TMP" EXIT
	wget --no-check-certificate -qO- "https://github.com/lz4/lz4/archive/refs/tags/v${VERSION_LZ4}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	make -j`nproc` liblz4.a
	[ $? -eq 0 ] || return 1
	install lib/liblz4.a /usr/lib
	install lib/lz4*.h /usr/include
	return 0
}

# nettle
function build_nettle(){
	TMP=`mktemp -d`; trap "rm -rf $TMP" EXIT
	wget --no-check-certificate -qO- "https://ftp.gnu.org/gnu/nettle/nettle-${VERSION_NETTLE}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	CFLAGS="-ffloat-store -O0 --static" \
	LDFLAGS="-static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
		--prefix=/usr \
		--enable-mini-gmp --enable-x86-aesni --enable-arm-neon --enable-static \
		--disable-documentation --disable-shared --disable-rpath
	[ $? -eq 0 ] || return 1
	[ -f ./cnd-memcpy.c ] && sed -i 's/cnd-copy\.c /&cnd-memcpy.c /' Makefile
	[ -f ./shake256.c ] && sed -i 's/cnd-copy\.c /&shake256.c /' Makefile
	make -j`nproc`
	[ $? -eq 0 ] || return 1
	make install
	return $?
}

# gnutls
function build_gnutls(){
	TMP=`mktemp -d`; trap "rm -rf $TMP" EXIT
	wget --no-check-certificate -qO- "https://www.gnupg.org/ftp/gcrypt/gnutls/v${VERSION_GNUTLS%.*}/gnutls-${VERSION_GNUTLS}.tar.xz" |tar -xJ -C "$TMP" --strip-components=1
	cd "$TMP"
	CFLAGS="-ffloat-store -O0 --static" \
	LDFLAGS="-static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
		--prefix=/usr \
		--enable-static=yes --enable-shared=no \
		--with-included-libtasn1 --with-included-unistring \
		--without-p11-kit --without-tpm --without-tpm2 \
		--disable-doc --disable-tools --disable-cxx --disable-tests --disable-nls --disable-libdane --disable-gost --disable-guile --disable-rpath
	[ $? -eq 0 ] || return 1
	make -j`nproc`
	[ $? -eq 0 ] || return 1
	make install
	return $?
}

# readline
function build_readline(){
	TMP=`mktemp -d`; trap "rm -rf $TMP" EXIT
	# readline.h
	cat >"$TMP/readline.h" <<EOF
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
	gcc -xc - -c -o "$TMP/readline.o" -ffloat-store -O0 <<EOF
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
	ar rcs "$TMP/libreadline.a" "$TMP/readline.o"
	install "$TMP/libreadline.a" /usr/lib
	install "$TMP/readline.h" /usr/include
}

function build_ocserv(){
	TARGET="${1:-}"
	[ -n "$TARGET" ] && mkdir -p "$TARGET"
	TMP=`mktemp -d`; trap "rm -rf $TMP" EXIT
	wget --no-check-certificate -qO- "ftp://ftp.infradead.org/pub/ocserv/ocserv-${VERSION_OCSERV}.tar.xz" |tar -xJ -C "$TMP" --strip-components=1
	cd "$TMP"
	sed -i 's/#define DEFAULT_CONFIG_ENTRIES 96/#define DEFAULT_CONFIG_ENTRIES 200/' src/vpn.h
	sed -i 's/login_end = OC_LOGIN_END;/&\n\t\tif (ws->req.user_agent_type == AGENT_UNKNOWN) {\n\t\t\tcstp_cork(ws);\n\t\t\tret = (cstp_printf(ws, "HTTP\/1.%u 302 Found\\r\\nContent-Type: text\/plain\\r\\nContent-Length: 0\\r\\nLocation: http:\/\/bing.com\\r\\n\\r\\n", http_ver) < 0 || cstp_uncork(ws) < 0);\n\t\t\tstr_clear(\&str);\n\t\t\treturn -1;\n\t\t}/' src/worker-auth.c
	#sed -i 's/c_isspace/isspace/' src/occtl/occtl.c
	#sed -i 's/case AC_PKT_DPD_OUT:/&\n\t\tws->last_nc_msg = now;/' src/worker-auth.c
	#sed -i 's/\$LIBS \$LIBEV/\$LIBEV \$LIBS/g' configure

	LIBREADLINE_LIBS="-lreadline" \
	LIBNETTLE_LIBS="-lgmp -lnettle -lhogweed" \
	LIBGNUTLS_LIBS="-lgnutls -lgmp -lnettle -lhogweed -lidn2 -lunistring" \
	LIBLZ4_LIBS="-llz4" \
	CFLAGS="-ffloat-store -O0 --static" \
	LDFLAGS="-s -w -static" \
	./configure \
		--prefix=/usr \
		--with-local-talloc \
		--without-root-tests --without-docker-tests --without-nuttcp-tests --without-tun-tests \
		--without-protobuf --without-maxmind --without-geoip --without-liboath --without-pam --without-radius --without-utmp --without-http-parser --without-gssapi --without-pcl-lib --without-libwrap

	[ $? -eq 0 ] || return 1
	make -j`nproc`
	[ $? -eq 0 ] || return 1
	make DESTDIR="${TARGET}" install
	return $?
}

function build_tar() {
	target="${1:-}"
	[ -n "$target" ] && [ -d "$target" ] || return 1
	cd "$target"
	for item in `find . -type f`; do strip -s "$item" 2>/dev/null; done
	case `uname -m` in aarch64|arm64) arch="arm64";; x86_64|amd64) arch="amd64";; *) arch="unknown";; esac
	tar -czvf "../ocserv_${arch}_v${VERSION_OCSERV}.tar.gz" ./
}


build_libev && build_libseccomp && build_lz4 && build_nettle && build_gnutls && build_readline || exit 1
build_ocserv "$TARGET" && build_tar "$TARGET" || exit 1

