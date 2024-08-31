#!/bin/sh

# docker pull alpine:latest
# docker rm -f alpine >/dev/null 2>&1; docker run --name alpine -it -v /mnt:/mnt alpine:latest
# docker exec -it alpine /bin/sh

apk update
apk add wget xz sed openssl gcc autoconf automake make linux-headers gperf musl-dev gnutls-dev gnutls-utils

VERSION_OCSERV="1.3.0"
VERSION_GNUTLS="3.8.6"
VERSION_LIBEV="4.33"
VERSION_LIBSECCOMP="2.5.5"
VERSION_LZ4="1.10.0"
VERSION_GMP="6.3.0"
VERSION_NETTLE="3.7.3"
VERSION_IDN2="2.3.4"
VERSION_UNISTRING="1.1"
VERSION_DNSMASQ="2.90"


TRAPRM=""
TARPKG=""

function musl_cross(){
	muslHome="/usr/local/musl"
	mkdir -p "${muslHome}"
	for arch in "$@" ; do
		wget --no-check-certificate -qO- "http://musl.cc/${arch}-linux-musl-cross.tgz" |tar -zx --overwrite -C "${muslHome}";
	done
	
	newPATH=""
	for path in `echo "$PATH" |sed 's/:/\n/g'`; do echo "$path" |grep -q "musl" || newPATH="${newPATH}:${path}"; done
	for path in `find "${muslHome}" -name "*-cc" 2>/dev/null`; do newPATH="${newPATH}:$(dirname ${path})"; done
	newPATH="${newPATH#:}"

	[ -f "$HOME/.bashrc" ] && sed -i '/^PATH=/d' "$HOME/.bashrc"
	echo "PATH=${newPATH}" |tee -a "$HOME/.bashrc"
}

# libev
function build_libev(){
	ARCH="${1:-x86_64}"
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
	wget --no-check-certificate -qO- "http://dist.schmorp.de/libev/Attic/libev-${VERSION_LIBEV}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	CC="${ARCH}-linux-musl-gcc" \
	CXX="${ARCH}-linux-musl-g++" \
	CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0 --static" \
	LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
		--host="${ARCH}-linux-musl" \
		--prefix="/usr/local/cross/${ARCH}" \
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
 	ARCH="${1:-x86_64}"
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
	wget --no-check-certificate -qO- "https://github.com/seccomp/libseccomp/releases/download/v${VERSION_LIBSECCOMP}/libseccomp-${VERSION_LIBSECCOMP}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	CC="${ARCH}-linux-musl-gcc" \
	CXX="${ARCH}-linux-musl-g++" \
	CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0 --static" \
	LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
		--host="${ARCH}-linux-musl" \
		--prefix="/usr/local/cross/${ARCH}" \
		--disable-shared \
		--enable-static
	sed -i 's/in_word_set/_in_word_set/g' src/syscalls.perf.c
	make -j`nproc` install
	return $?
}

# lz4
function build_lz4(){
	ARCH="${1:-x86_64}"
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
	wget --no-check-certificate -qO- "https://github.com/lz4/lz4/archive/refs/tags/v${VERSION_LZ4}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	CC="${ARCH}-linux-musl-gcc" \
	CXX="${ARCH}-linux-musl-g++" \
	make -j`nproc` liblz4.a
	[ $? -eq 0 ] || return 1
	install lib/liblz4.a "/usr/local/cross/${ARCH}/lib"
	install lib/lz4*.h "/usr/local/cross/${ARCH}/include"
	return 0
}

# gmp
function build_gmp(){
	ARCH="${1:-x86_64}"
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
	wget --no-check-certificate -qO- "https://gmplib.org/download/gmp/gmp-${VERSION_GMP}.tar.xz" |tar -xJ -C "$TMP" --strip-components=1
	cd "$TMP"
	CC="${ARCH}-linux-musl-gcc" \
	CXX="${ARCH}-linux-musl-g++" \
	CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0 --static" \
	LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
		--host="${ARCH}-linux-musl" \
		--prefix="/usr/local/cross/${ARCH}" \
		--enable-static=yes --enable-shared=no
	[ $? -eq 0 ] || return 1
	make -j`nproc`
	[ $? -eq 0 ] || return 1
	make install
	return $?
}

# nettle
function build_nettle(){
	ARCH="${1:-x86_64}"
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
	wget --no-check-certificate -qO- "https://ftp.gnu.org/gnu/nettle/nettle-${VERSION_NETTLE}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	CC="${ARCH}-linux-musl-gcc" \
	CXX="${ARCH}-linux-musl-g++" \
	CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0 --static" \
	LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
		--host="${ARCH}-linux-musl" \
		--prefix="/usr/local/cross/${ARCH}" \
		--enable-x86-aesni --enable-arm-neon --enable-static \
		--disable-documentation --disable-shared --disable-rpath
	[ $? -eq 0 ] || return 1
	[ -f ./cnd-memcpy.c ] && sed -i 's/cnd-copy\.c /&cnd-memcpy.c /' Makefile
	[ -f ./shake256.c ] && sed -i 's/cnd-copy\.c /&shake256.c /' Makefile
	make -j`nproc`
	[ $? -eq 0 ] || return 1
	make install
	return $?
}

# idn2
function build_idn2(){
	ARCH="${1:-x86_64}"
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
	wget --no-check-certificate -qO- "https://ftp.gnu.org/gnu/libidn/libidn2-${VERSION_IDN2}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	CC="${ARCH}-linux-musl-gcc" \
	CXX="${ARCH}-linux-musl-g++" \
	CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0 --static" \
	LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
		--host="${ARCH}-linux-musl" \
		--prefix="/usr/local/cross/${ARCH}" \
		--enable-static=yes --enable-shared=no --disable-rpath --disable-nls --disable-doc --disable-valgrind-tests
	[ $? -eq 0 ] || return 1
	make -j`nproc`
	[ $? -eq 0 ] || return 1
	make install
	return $?
}

# unistring
function build_unistring(){
	ARCH="${1:-x86_64}"
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
	wget --no-check-certificate -qO- "https://ftp.gnu.org/gnu/libunistring/libunistring-${VERSION_UNISTRING}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	CC="${ARCH}-linux-musl-gcc" \
	CXX="${ARCH}-linux-musl-g++" \
	CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0 --static" \
	LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
		--host="${ARCH}-linux-musl" \
		--prefix="/usr/local/cross/${ARCH}" \
		--enable-static=yes --enable-shared=no --disable-rpath
	[ $? -eq 0 ] || return 1
	make -j`nproc`
	[ $? -eq 0 ] || return 1
	make install
	return $?
}

# gnutls
function build_gnutls(){
	ARCH="${1:-x86_64}"
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
	wget --no-check-certificate -qO- "https://www.gnupg.org/ftp/gcrypt/gnutls/v${VERSION_GNUTLS%.*}/gnutls-${VERSION_GNUTLS}.tar.xz" |tar -xJ -C "$TMP" --strip-components=1
	cd "$TMP"
	CC="${ARCH}-linux-musl-gcc" \
	CXX="${ARCH}-linux-musl-g++" \
	NETTLE_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
	NETTLE_LIBS="-L/usr/local/cross/${ARCH}/lib -lnettle" \
	HOGWEED_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
	HOGWEED_LIBS="-L/usr/local/cross/${ARCH}/lib -lhogweed" \
	GMP_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
	GMP_LIBS="-L/usr/local/cross/${ARCH}/lib -lgmp" \
	LIBIDN2_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
	LIBIDN2_LIBS="-L/usr/local/cross/${ARCH}/lib -lidn2" \
	CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0 --static" \
	LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
	./configure \
	    --host="${ARCH}-linux-musl" \
		--prefix="/usr/local/cross/${ARCH}" \
		--enable-static=yes --enable-shared=no \
		--enable-openssl-compatibility \
		--with-included-libtasn1 \
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
	ARCH="${1:-x86_64}"
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
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
	"${ARCH}-linux-musl-gcc" -xc - -c -o "$TMP/readline.o" -ffloat-store -O0 <<EOF
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
	install "$TMP/libreadline.a" "/usr/local/cross/${ARCH}/lib"
	install "$TMP/readline.h" "/usr/local/cross/${ARCH}/include"
}

function build_ocserv(){
	ARCH="${1:-x86_64}"
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
	wget --no-check-certificate -qO- "ftp://ftp.infradead.org/pub/ocserv/ocserv-${VERSION_OCSERV}.tar.xz" |tar -xJ -C "$TMP" --strip-components=1
	cd "$TMP"
	sed -i 's/#define DEFAULT_CONFIG_ENTRIES 96/#define DEFAULT_CONFIG_ENTRIES 200/' src/vpn.h
	sed -i 's/login_end = OC_LOGIN_END;/&\n\t\tif (ws->req.user_agent_type == AGENT_UNKNOWN) {\n\t\t\tcstp_cork(ws);\n\t\t\tret = (cstp_printf(ws, "HTTP\/1.%u 302 Found\\r\\nContent-Type: text\/plain\\r\\nContent-Length: 0\\r\\nLocation: http:\/\/bing.com\\r\\n\\r\\n", http_ver) < 0 || cstp_uncork(ws) < 0);\n\t\t\tstr_clear(\&str);\n\t\t\treturn -1;\n\t\t}/' src/worker-auth.c
	sed -i 's/c_isspace/isspace/' src/occtl/occtl.c
	#sed -i 's/case AC_PKT_DPD_OUT:/&\n\t\tws->last_nc_msg = now;/' src/worker-auth.c
	
	sed -i '/AC_CHECK_FILE/d' ./configure.ac
	autoreconf -fvi
	
	CC="${ARCH}-linux-musl-gcc" \
	CXX="${ARCH}-linux-musl-g++" \
	LIBREADLINE_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
	LIBREADLINE_LIBS="-L/usr/local/cross/${ARCH}/lib -lreadline" \
	LIBNETTLE_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
	LIBNETTLE_LIBS="-L/usr/local/cross/${ARCH}/lib -lgmp -lnettle -lhogweed" \
	LIBGNUTLS_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
	LIBGNUTLS_LIBS="-L/usr/local/cross/${ARCH}/lib -lgnutls -lgmp -lnettle -lhogweed -lidn2 -lunistring" \
	LIBLZ4_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
	LIBLZ4_LIBS="-L/usr/local/cross/${ARCH}/lib -llz4" \
	CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0 --static" \
	LDFLAGS="-L/usr/local/cross/${ARCH}/lib -s -w -static" \
	./configure \
		--host="${ARCH}-linux-musl" \
		--prefix="/usr" \
		--with-local-talloc \
		--disable-dependency-tracking \
		--without-root-tests --without-docker-tests --without-nuttcp-tests --without-tun-tests \
		--without-protobuf --without-maxmind --without-geoip --without-liboath --without-pam --without-radius --without-utmp --without-http-parser --without-gssapi --without-pcl-lib --without-libwrap

	[ $? -eq 0 ] || return 1
	make -j`nproc`
	[ $? -eq 0 ] || return 1
	TARGET=`mktemp -d`; TRAPRM="${TRAPRM} ${TARGET}"; trap "rm -rf ${TRAPRM# }" EXIT
	make DESTDIR="${TARGET}" install
	[ $? -eq 0 ] || return 1
	cd "${TARGET}"
	FILE="/mnt/ocserv_${ARCH}_v${VERSION_OCSERV}.tar.gz"
	tar -czvf "${FILE}" ./
	[ $? -eq 0 ] || return 1
	TARPKG="${TARPKG} ${FILE}"
	return 0
}

function build_dnsmasq(){
	ARCH="${1:-x86_64}"
	[ -n "$VERSION_DNSMASQ" ] || return 0
	TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
	wget --no-check-certificate -qO- "http://www.thekelleys.org.uk/dnsmasq/dnsmasq-${VERSION_DNSMASQ}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
	cd "$TMP"
	make CC="${ARCH}-linux-musl-gcc" CXX="${ARCH}-linux-musl-g++" CFLAGS="-I. -Wall -W -fPIC -O2" LDFLAGS="-L. -static -s" -j`nproc`
	[ $? -eq 0 ] || return 1
	TARGET=`mktemp -d`; TRAPRM="${TRAPRM} ${TARGET}"; trap "rm -rf ${TRAPRM# }" EXIT
	make CC="${ARCH}-linux-musl-gcc" CXX="${ARCH}-linux-musl-g++" PREFIX="/usr" DESTDIR="${TARGET}" install
	[ $? -eq 0 ] || return 1
	cd "${TARGET}"
	FILE="/mnt/dnsmasq_${ARCH}_v${VERSION_DNSMASQ}.tar.gz"
	tar -czvf "${FILE}" ./
	[ $? -eq 0 ] || return 1
	TARPKG="${TARPKG} ${FILE}"
	return 0
}

function build() {
	ARCH="${1:-x86_64}"
	build_dnsmasq "${ARCH}"
	[ $? -eq 0 ] || return 1
	build_libev "${ARCH}"
	[ $? -eq 0 ] || return 1
	build_libseccomp "${ARCH}"
	[ $? -eq 0 ] || return 1
	build_lz4 "${ARCH}"
	[ $? -eq 0 ] || return 1
	build_gmp "${ARCH}"
	[ $? -eq 0 ] || return 1
	build_nettle "${ARCH}"
	[ $? -eq 0 ] || return 1
	build_idn2 "${ARCH}"
	[ $? -eq 0 ] || return 1
	build_unistring "${ARCH}"
	[ $? -eq 0 ] || return 1
	build_gnutls "${ARCH}"
	[ $? -eq 0 ] || return 1
	build_readline "${ARCH}"
	[ $? -eq 0 ] || return 1
	build_ocserv "${ARCH}"
	[ $? -eq 0 ] || return 1
}


for arch in "x86_64" "aarch64"; do
	eval `musl_cross "${arch}"`
	build "${arch}"
	[ "$?" -eq 0 ] || exit 1
done

for tarpkg in `echo "${TARPKG# }"`; do
	echo "--> ${tarpkg}"
done


