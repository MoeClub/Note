#!/bin/sh

# docker pull alpine:latest
# docker rm -f alpine >/dev/null 2>&1; docker run --name alpine -it -v /mnt:/mnt alpine:latest
# docker exec -it alpine /bin/sh

apk update
apk add wget xz sed openssl gcc coreutils patch file autoconf automake pkgconfig make linux-headers gperf musl-dev gnutls-dev gnutls-utils libbsd-dev protobuf-c-compiler meson


VERSION_OCSERV="1.4.2"
VERSION_DNSMASQ="2.92"
VERSION_LIBEV="4.33"
VERSION_LZ4="1.10.0"
VERSION_LIBSECCOMP="2.5.6"
VERSION_GNUTLS="3.8.11"
VERSION_GMP="6.3.0"
VERSION_NETTLE="3.10.2"
VERSION_IDN2="2.3.8"
VERSION_SNIPROXY="0.7.0"
VERSION_UDNS="0.6"
VERSION_PCRE2="10.47"


TRAPRM=""
TARPKG=""

function musl_cross(){
  muslHome="/usr/local/musl"
  mkdir -p "${muslHome}"
  for arch in "$@" ; do
    PATH="$PATH" which "${arch}-linux-musl-gcc" >/dev/null 2>&1 || wget --no-check-certificate -qO- "http://musl.cc/${arch}-linux-musl-cross.tgz" |tar -zx --overwrite -C "${muslHome}";
  done

  newPATH=""
  for path in `echo "$PATH" |sed 's/:/\n/g'`; do echo "$path" |grep -q "musl" || newPATH="${newPATH}:${path}"; done
  for path in `find "${muslHome}" -name "*-cc" 2>/dev/null`; do newPATH="${newPATH}:$(dirname ${path})"; done
  newPATH="${newPATH#:}"

  [ -f "$HOME/.bashrc" ] && sed -i "s/^PATH=.*/PATH=${newPATH////\\/}/" "$HOME/.bashrc"
  [ -f "/etc/profile" ] && sed -i "s/^export PATH=.*/export PATH=${newPATH////\\/}/" "/etc/profile"
  echo "export PATH=${newPATH}"
}


function meson_cross(){
  pkgPath=`which pkg-config 2>/dev/null`
  ccPath=`which "$CC" 2>/dev/null`
  [ -n "$ccPath" ] && [ -n "$pkgPath" ] || return 1
  ccDir=`dirname "$ccPath"`
  machine=`"$CC" -dumpmachine`
  arch="${machine%%-*}"
  cpu_family="${arch}"
  cpu="${arch}"
  endian="little"

  case "$arch" in arm64) cpu_family="aarch64"; cpu="aarch64" ;; i?86) cpu_family="x86" ;; *) ;; esac
  case "$machine" in *linux*) system="linux" ;; *darwin*) system="darwin" ;; *mingw*|*windows*) system="windows" ;; *) ;; esac

  [ -n "$system" ] || return 1
  corss=`mktemp -u /tmp/meson.cross.XXXXXXXX`
  {
    echo '[binaries]'
    [ -e "${ccDir}/${cpu_family}-linux-musl-gcc" ] && echo "c = '${ccDir}/${cpu_family}-linux-musl-gcc'"
    [ -e "${ccDir}/${cpu_family}-linux-musl-g++" ] && echo "cpp = '${ccDir}/${cpu_family}-linux-musl-g++'"
    [ -e "${ccDir}/${cpu_family}-linux-musl-ar" ] && echo "ar = '${ccDir}/${cpu_family}-linux-musl-ar'"
    [ -e "${ccDir}/${cpu_family}-linux-musl-strip" ] && echo "strip = '${ccDir}/${cpu_family}-linux-musl-strip'"
    [ -e "${ccDir}/${cpu_family}-linux-musl-objcopy" ] && echo "objcopy = '${ccDir}/${cpu_family}-linux-musl-objcopy'"
    [ -e "${ccDir}/${cpu_family}-linux-musl-objdump" ] && echo "objdump = '${ccDir}/${cpu_family}-linux-musl-objdump'"
    [ -e "${ccDir}/${cpu_family}-linux-musl-ld" ] && echo "ld = '${ccDir}/${cpu_family}-linux-musl-ld'"
    echo "pkg-config = '${pkgPath}'"
    echo
    echo '[host_machine]'
    echo "system = '${system}'"
    echo "cpu_family = '${cpu_family}'"
    echo "cpu = '${cpu}'"
    echo "endian = '${endian}'"
    echo
    echo '[properties]'
    echo 'needs_exe_wrapper = true'
    echo "sys_root = '/usr/local/cross/${cpu_family}'"
    echo "pkg_config_libdir = ['/usr/local/cross/${cpu_family}/lib/pkgconfig']"
    echo
    echo '[built-in options]'
    echo 'prefer_static = true'
    echo "default_library = 'static'"
    echo "c_args = ['--sysroot=/usr/local/cross/${cpu_family}', '-I/usr/local/cross/${cpu_family}/include']"
    echo "cpp_args = ['--sysroot=/usr/local/cross/${cpu_family}', '-I/usr/local/cross/${cpu_family}/include']"
    echo "c_link_args = ['--sysroot=/usr/local/cross/${cpu_family}', '-L/usr/local/cross/${cpu_family}/lib', '-static']"
    echo "cpp_link_args = ['--sysroot=/usr/local/cross/${cpu_family}', '-L/usr/local/cross/${cpu_family}/lib', '-static']"
  } > "${corss}"
  echo "${corss}"
}

# libev
function build_libev(){
  ARCH="${1:-x86_64}"
  TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
  wget --no-check-certificate -qO- "http://dist.schmorp.de/libev/Attic/libev-${VERSION_LIBEV}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
  cd "$TMP"
  CC="${ARCH}-linux-musl-gcc" \
  CXX="${ARCH}-linux-musl-g++" \
  CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0" \
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
  CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0" \
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
  make -j`nproc` BUILD_STATIC=yes BUILD_SHARED=no prefix="/usr/local/cross/${ARCH}" libdir="/usr/local/cross/${ARCH}/lib" includedir="/usr/local/cross/${ARCH}/include" pkgconfigdir="/usr/local/cross/${ARCH}/lib/pkgconfig" install
  return $?
}

# gmp
function build_gmp(){
  ARCH="${1:-x86_64}"
  TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
  wget --no-check-certificate -qO- "https://gmplib.org/download/gmp/gmp-${VERSION_GMP}.tar.xz" |tar -xJ -C "$TMP" --strip-components=1
  cd "$TMP"
  CC="${ARCH}-linux-musl-gcc" \
  CXX="${ARCH}-linux-musl-g++" \
  CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0" \
  LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
  ./configure \
    --host="${ARCH}-linux-musl" \
    --prefix="/usr/local/cross/${ARCH}" \
    --enable-static=yes \
    --enable-shared=no
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
  CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0" \
  LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
  ./configure \
    --host="${ARCH}-linux-musl" \
    --prefix="/usr/local/cross/${ARCH}" \
    --enable-x86-aesni --enable-arm-neon --enable-static \
    --disable-documentation --disable-shared --disable-rpath
  [ $? -eq 0 ] || return 1
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
  CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0" \
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
  CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0" \
  LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -static-libgcc -static-libstdc++ -s -pthread -lpthread" \
  ./configure \
    --host="${ARCH}-linux-musl" \
    --prefix="/usr/local/cross/${ARCH}" \
    --enable-static=yes --enable-shared=no \
    --with-included-libtasn1 --with-included-unistring \
    --without-brotli --without-zstd --without-zlib \
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
  TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; # trap "rm -rf ${TRAPRM# }" EXIT
  # history.h
  cat >"$TMP/history.h" <<EOF
#ifndef HISTORY_H
#define HISTORY_H
void add_history(const char *string);
#endif
EOF
  # readline.h
  cat >"$TMP/readline.h" <<EOF
#ifndef READLINE_H
#define READLINE_H
#include <ctype.h>
typedef char *rl_compentry_func_t(const char*, int);
typedef char **rl_completion_func_t(const char*, int, int);
extern char *rl_line_buffer;
extern char *rl_readline_name;
extern rl_completion_func_t *rl_attempted_completion_function;
extern rl_compentry_func_t *rl_completion_entry_function;
extern int rl_completion_query_items;
char *readline(const char *prompt);
void add_history(const char *string);
void rl_reset_line_state(void);
int rl_reset_terminal(const char *terminal_name);
int rl_replace_line(const char *text, int clear_undo);
int rl_crlf(void);
int rl_clear_signals(void);
char **rl_completion_matches(const char *text, void *entry_func);
void rl_reset_screen_size(void);
void rl_redisplay(void);
#ifndef whitespace
# define whitespace(c) isspace((unsigned char)(c))
#endif

#ifndef c_isspace
# define c_isspace(c) isspace((unsigned char)(c))
#endif
#endif
EOF
  # readline.c
  "${ARCH}-linux-musl-gcc" -xc - -c -o "$TMP/readline.o" -ffloat-store -O0 <<EOF
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
char *rl_line_buffer = NULL;
char *rl_readline_name;
void *rl_attempted_completion_function;
void *rl_completion_entry_function;
int rl_completion_query_items;
int rl_replace_line(const char *text, int clear_undo) {
  (void)clear_undo;
  free(rl_line_buffer);
  rl_line_buffer = strdup(text ? text : "");
  return 0;
}
char *readline(const char *prompt) {
  char buf[512], *ptr;
  if(prompt) printf("%s", prompt);
  fflush(stdout); ptr = buf;
  while((*ptr = getchar()) != '\n') ptr++;
  *ptr = '\0';

  free(rl_line_buffer);
  rl_line_buffer = strdup(buf);
  return strdup(buf);
}
int rl_crlf(void) {
  putchar('\n');
  fflush(stdout);
  return 0;
}
void add_history(const char *string) {}
int rl_reset_terminal(const char *terminal_name) {return 0;}
int rl_clear_signals(void) {return 0;}
char **rl_completion_matches(const char *text, void *entry_func) {return NULL;}
void rl_redisplay(void) {}
void rl_reset_line_state(void) {}
void rl_reset_screen_size(void) {}
EOF
  # readline.a
  ar rcs "$TMP/libreadline.a" "$TMP/readline.o"
  install -d "/usr/local/cross/${ARCH}/lib" "/usr/local/cross/${ARCH}/include/readline"
  install "$TMP/libreadline.a" "/usr/local/cross/${ARCH}/lib"
  install "$TMP/readline.h" "/usr/local/cross/${ARCH}/include"
  install "$TMP/readline.h" "/usr/local/cross/${ARCH}/include/readline"
  install "$TMP/history.h" "/usr/local/cross/${ARCH}/include"
  install "$TMP/history.h" "/usr/local/cross/${ARCH}/include/readline"
}

function build_ocserv(){
  ARCH="${1:-x86_64}"
  TMP=`mktemp -d`; # TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
  wget --no-check-certificate -qO- "ftp://ftp.infradead.org/pub/ocserv/ocserv-${VERSION_OCSERV}.tar.xz" |tar -xJ -C "$TMP" --strip-components=1
  cd "$TMP"
  sed -i 's/#define DEFAULT_CONFIG_ENTRIES 96/#define DEFAULT_CONFIG_ENTRIES 200/' src/vpn.h
  sed -i 's/login_end = OC_LOGIN_END;/&\n\t\tif (ws->req.user_agent_type == AGENT_UNKNOWN) {\n\t\t\tcstp_cork(ws);\n\t\t\tret = (cstp_printf(ws, "HTTP\/1.%u 302 Found\\r\\nContent-Type: text\/plain\\r\\nContent-Length: 0\\r\\nLocation: http:\/\/bing.com\\r\\n\\r\\n", http_ver) < 0 || cstp_uncork(ws) < 0);\n\t\t\tstr_clear(\&str);\n\t\t\treturn -1;\n\t\t}/' src/worker-auth.c
  sed -i 's/^#define WORKER_MAINTENANCE_TIME .*/#define WORKER_MAINTENANCE_TIME (4.)/' src/worker-vpn.c
  sed -i 's/^#define PERIODIC_CHECK_TIME .*/#define PERIODIC_CHECK_TIME 3/' src/worker-vpn.c

  TARGET=`mktemp -d`; TRAPRM="${TRAPRM} ${TARGET}"; trap "rm -rf ${TRAPRM# }" EXIT
  if [ -f "meson.build" ]; then
    corss=`CC="${ARCH}-linux-musl-gcc" meson_cross`
    echo "cross: ${corss}"
    PKG_CONFIG_LIBDIR="/usr/local/cross/${ARCH}/lib/pkgconfig" meson setup build \
      --prefix "/usr" --cross-file "$corss" \
      -Db_pie=false -Dstrip=true -Dbuildtype=release \
      -Dlocal-talloc=true -Dlocal-llhttp=true -Dlocal-protobuf=true -Dlocal-pcl=true \
      -Droot-tests=false -Dtun-tests=false -Dkerberos-tests=false -Dradius=disabled -Dgssapi=disabled -Dliboath=disabled -Dlibnl=disabled -Dmaxmind=disabled -Dgeoip=disabled -Dsystemd=disabled \
      -Danyconnect-compat=enabled -Dcompression=enabled -Dseccomp=enabled -Dlz4=enabled
    [ $? -eq 0 ] || return 1
    meson compile -C build
    [ $? -eq 0 ] || return 1
    DESTDIR="${TARGET}" meson install -C build
    [ $? -eq 0 ] || return 1
  else
    autoreconf -fvi
    CC="${ARCH}-linux-musl-gcc" \
    CXX="${ARCH}-linux-musl-g++" \
    LIBREADLINE_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
    LIBREADLINE_LIBS="-L/usr/local/cross/${ARCH}/lib -lreadline" \
    LIBSECCOMP_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
    LIBSECCOMP_LIBS="-L/usr/local/cross/${ARCH}/lib -lseccomp" \
    LIBNETTLE_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
    LIBNETTLE_LIBS="-L/usr/local/cross/${ARCH}/lib -lgmp -lnettle -lhogweed" \
    LIBGNUTLS_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
    LIBGNUTLS_LIBS="-L/usr/local/cross/${ARCH}/lib -lgnutls -lgmp -lnettle -lhogweed -lidn2" \
    LIBLZ4_CFLAGS="-I/usr/local/cross/${ARCH}/include" \
    LIBLZ4_LIBS="-L/usr/local/cross/${ARCH}/lib -llz4" \
    CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0" \
    LDFLAGS="-L/usr/local/cross/${ARCH}/lib -s -w -static -no-pie" \
    ac_cv_file__proc_self_exe=yes \
    ./configure \
      --host="${ARCH}-linux-musl" \
      --prefix="/usr" \
      --with-local-talloc \
      --disable-dependency-tracking \
      --without-root-tests --without-docker-tests --without-nuttcp-tests --without-tun-tests \
      --without-protobuf --without-maxmind --without-geoip --without-liboath --without-pam --without-radius --without-utmp --without-http-parser --without-gssapi --without-pcl-lib --without-libwrap --without-llhttp
    [ $? -eq 0 ] || return 1
    make -j`nproc`
    [ $? -eq 0 ] || return 1
    make DESTDIR="${TARGET}" install
    [ $? -eq 0 ] || return 1
  fi

  cd "${TARGET}"
  FILE="/mnt/ocserv_${ARCH}_v${VERSION_OCSERV}.tar.gz"
  [ -f "${FILE}" ] && rm -rf "${FILE}"
  tar -czvf "${FILE}" ./
  [ $? -eq 0 ] || return 1
  TARPKG="${TARPKG} ${FILE}"
  return 0
}

function build_dnsmasq(){
  ARCH="${1:-x86_64}"
  [ -n "$VERSION_DNSMASQ" ] || return 0
  TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; TARGET=`mktemp -d`; TRAPRM="${TRAPRM} ${TARGET}"; trap "rm -rf ${TRAPRM# }" EXIT
  wget --no-check-certificate -qO- "http://www.thekelleys.org.uk/dnsmasq/dnsmasq-${VERSION_DNSMASQ}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
  cd "$TMP"
  # wget --no-check-certificate -qO- "http://lib.mk/dnsmasq/${VERSION_DNSMASQ}.patch" 2>/dev/null |patch -p1 -N
  make CC="${ARCH}-linux-musl-gcc" CXX="${ARCH}-linux-musl-g++" CFLAGS="-I. -Wall -W -fPIC -O2" LDFLAGS="-L. -static -no-pie -s" PREFIX="/usr" DESTDIR="${TARGET}" -j`nproc` install
  [ $? -eq 0 ] || return 1
  cd "${TARGET}"
  FILE="/mnt/dnsmasq_${ARCH}_v${VERSION_DNSMASQ}.tar.gz"
  [ -f "${FILE}" ] && rm -rf "${FILE}"
  file ./usr/sbin/dnsmasq
  tar -czvf "${FILE}" ./
  [ $? -eq 0 ] || return 1
  TARPKG="${TARPKG} ${FILE}"
  return 0
}

function build_udns(){
  ARCH="${1:-x86_64}"
  [ -n "$VERSION_UDNS" ] || return 0
  TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
  wget --no-check-certificate -qO- "https://www.corpit.ru/mjt/udns/udns-${VERSION_UDNS}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
  cd "$TMP"
  ./configure && make CC="${ARCH}-linux-musl-gcc" CXX="${ARCH}-linux-musl-g++" CFLAGS="-I. -Wall -W -fPIC -O2" LDFLAGS="-L. -static -no-pie -s" -j`nproc`
  [ $? -eq 0 ] || return 1
  [ -d "/usr/local/cross/${ARCH}/include" ] || mkdir -p "/usr/local/cross/${ARCH}/include"
  [ -d "/usr/local/cross/${ARCH}/lib" ] || mkdir -p "/usr/local/cross/${ARCH}/lib"
  cp -rf *.h "/usr/local/cross/${ARCH}/include"
  cp -rf *.a "/usr/local/cross/${ARCH}/lib"
}

function build_prce2(){
  ARCH="${1:-x86_64}"
  [ -n "$VERSION_PCRE2" ] || return 0
  TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; trap "rm -rf ${TRAPRM# }" EXIT
  wget --no-check-certificate -qO- "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${VERSION_PCRE2}/pcre2-${VERSION_PCRE2}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
  cd "$TMP"
  CC="${ARCH}-linux-musl-gcc" \
  CXX="${ARCH}-linux-musl-g++" \
  CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O0" \
  LDFLAGS="-L/usr/local/cross/${ARCH}/lib -s -w -static -no-pie" \
  ./configure \
    --host="${ARCH}-linux-musl" \
    --prefix="/usr/local/cross/${ARCH}" \
    --disable-shared --enable-static \
    --disable-jit --disable-pcre2-16 --disable-pcre2-32 --enable-pcre2-8
  [ $? -eq 0 ] || return 1
  make -j`nproc`
  [ $? -eq 0 ] || return 1
  make install
}

function build_sniproxy(){
  ARCH="${1:-x86_64}"
  [ -n "$VERSION_SNIPROXY" ] || return 0
  TMP=`mktemp -d`; TRAPRM="${TRAPRM} ${TMP}"; TARGET=`mktemp -d`; TRAPRM="${TRAPRM} ${TARGET}"; trap "rm -rf ${TRAPRM# }" EXIT
  wget --no-check-certificate -qO- "https://github.com/dlundquist/sniproxy/archive/refs/tags/${VERSION_SNIPROXY}.tar.gz" |tar -xz -C "$TMP" --strip-components=1
  cd "$TMP"
  mkdir -p "/usr/local/cross/${ARCH}/include/sys"
  cp -rf /usr/include/bsd "/usr/local/cross/${ARCH}/include"
  cp -rf /usr/include/bsd/sys/queue.h "/usr/local/cross/${ARCH}/include/sys"
  [ -f "./setver.sh" ] && sh ./setver.sh
  autoreconf --install
  automake --add-missing --copy > /dev/null 2>&1
  CC="${ARCH}-linux-musl-gcc" \
  CXX="${ARCH}-linux-musl-g++" \
  CFLAGS="-I/usr/local/cross/${ARCH}/include -ffloat-store -O2" \
  LDFLAGS="-L/usr/local/cross/${ARCH}/lib -s -w -static -no-pie" \
  ./configure \
    --host="${ARCH}-linux-musl" \
    --prefix="/usr" \
    --enable-dns
  make CC="${ARCH}-linux-musl-gcc" CXX="${ARCH}-linux-musl-g++" CFLAGS="-I/usr/local/cross/${ARCH}/include -Wall -W -fPIC -O2" LDFLAGS="-L/usr/local/cross/${ARCH}/lib -static -no-pie -s" PREFIX="/usr" DESTDIR="${TARGET}" -j`nproc` install
  [ $? -eq 0 ] || return 1
}


function build() {
  ARCH="${1:-x86_64}"
  build_dnsmasq "${ARCH}"
  [ $? -eq 0 ] || return 1
  build_gmp "${ARCH}"
  [ $? -eq 0 ] || return 1
  build_nettle "${ARCH}"
  [ $? -eq 0 ] || return 1
  build_idn2 "${ARCH}"
  [ $? -eq 0 ] || return 1
  build_gnutls "${ARCH}"
  [ $? -eq 0 ] || return 1
  build_readline "${ARCH}"
  [ $? -eq 0 ] || return 1
  build_libev "${ARCH}"
  [ $? -eq 0 ] || return 1
  build_libseccomp "${ARCH}"
  [ $? -eq 0 ] || return 1
  build_lz4 "${ARCH}"
  [ $? -eq 0 ] || return 1
  build_ocserv "${ARCH}"
  [ $? -eq 0 ] || return 1
}


for arch in "x86_64" "aarch64"; do
  eval `musl_cross "${arch}"`
  build "${arch}"
  [ "$?" -ne 0 ] && exit 1
done

for tarpkg in `echo "${TARPKG# }"`; do
  echo "--> ${tarpkg}"
done
