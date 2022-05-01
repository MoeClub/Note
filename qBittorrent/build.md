# build
```
bash ~/qbittorrent-nox-static.sh all -i -c -n -qt release-4.4.2 -lt v2.0.6

```

# manual
```
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

XZ_OPT=-9 tar -Jcvf ./qbittorrent_${arch}_qt_v4.4.2_lt_2.0.6.tar.xz qbittorrent

mkdir -p ./qbittorrent && curl -sSL "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-4.4.2.tar.gz" |tar -xz --strip-components=1 -C ./qbittorrent
```

# optimize
```
# /src/webui/api/torrentscontroller.cpp:TorrentsController::addAction
const bool firstLastPiece = parseBool(params()["firstLastPiecePrio"]).value_or(true);
const auto *session = BitTorrent::Session::instance();
const int upLimit = parseInt(params()["upLimit"]).value_or(session->altGlobalUploadSpeedLimit() <= 0 ? -1 : session->altGlobalUploadSpeedLimit());
const int dlLimit = parseInt(params()["dlLimit"]).value_or(session->altGlobalDownloadSpeedLimit() <= 0 ? -1 : session->altGlobalDownloadSpeedLimit());

# /src/base/bittorrent/session.cpp:Session::initializeNativeSession
// lt::settings_pack pack;
lt::settings_pack pack = lt::high_performance_seed();
pack.set_int(lt::settings_pack::torrent_connect_boost, 64);
pack.set_int(lt::settings_pack::tracker_backoff, 128);
pack.set_int(lt::settings_pack::predictive_piece_announce, 32);
pack.set_int(lt::settings_pack::send_not_sent_low_watermark, 16384);
pack.set_int(lt::settings_pack::allowed_fast_set_size, 0);
// 32MiB max queued disk writes
pack.set_int(lt::settings_pack::max_queued_disk_bytes, 32 * 1024 * 1024);
// 16KiB blocks, read 1MiB, write 8MiB
pack.set_int(lt::settings_pack::read_cache_line_size, 64);
pack.set_int(lt::settings_pack::write_cache_line_size, 512);
// cache size, 16KiB blocks, 1GB cache, 128MB volatile
pack.set_int(lt::settings_pack::cache_size, 65536);
pack.set_int(lt::settings_pack::cache_size_volatile, 8192);
pack.set_bool(lt::settings_pack::smooth_connects, false);
pack.set_int(lt::settings_pack::connection_speed, 512);

```
