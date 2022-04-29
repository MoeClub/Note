```
bash ~/qbittorrent-nox-static.sh all -i -c -qm -n

HOME="/root/qbt-build"
PATH="/root/qbt-build/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PKG_CONFIG_PATH="/root/qbt-build/lib/pkgconfig"

cd /root/qbt-build/qbittorrent

rm -rf build

cmake -Wno-dev -Wno-deprecated \
--graphviz="/root/qbt-build/graphs/master/dep-graph.dot" \
-G Ninja -B build \
-D CMAKE_VERBOSE_MAKEFILE=OFF \
-D CMAKE_BUILD_TYPE=release \
-D QT6=OFF \
-D CMAKE_CXX_STANDARD=17 \
-D CMAKE_PREFIX_PATH="/root/qbt-build;/root/qbt-build/boost" \
-D Boost_NO_BOOST_CMAKE=TRUE \
-D CMAKE_CXX_FLAGS="-std=c++17 -static -w -I/root/qbt-build/include" \
-D Iconv_LIBRARY="/root/qbt-build/lib/libiconv.a" \
-D CMAKE_CXX_STANDARD_LIBRARIES="" \
-D GUI=OFF \
-D CMAKE_INSTALL_PREFIX="/root/qbt-build"

cmake --build build

mv -f /root/qbittorrent /root/qbittorrent.bak; cp build/qbittorrent-nox /root/qbittorrent


```

```
# /src/webui/api/torrentscontroller.cpp:TorrentsController::addAction
const auto *session = BitTorrent::Session::instance();
const int upLimit = parseInt(params()[u"upLimit"_qs]).value_or(session->altGlobalUploadSpeedLimit() <= 0 ? -1 : session->altGlobalUploadSpeedLimit());
const int dlLimit = parseInt(params()[u"dlLimit"_qs]).value_or(session->altGlobalDownloadSpeedLimit() <= 0 ? -1 : session->altGlobalDownloadSpeedLimit());

```
