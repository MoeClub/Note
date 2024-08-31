# Build

```
ver=1.3.0 && rm -rf ./ocserv/tmp/* && sed -i "s/^Version: .*/Version: ${ver}/" ./ocserv/DEBIAN/control &&  cp -rf dnsmasq_*.tar.gz ./ocserv/tmp && mv ./ocserv/tmp/dnsmasq_aarch64_v2.90.tar.gz ./ocserv/tmp/dnsmasq_arm64.tar.gz && mv ./ocserv/tmp/dnsmasq_x86_64_v2.90.tar.gz ./ocserv/tmp/dnsmasq_amd64.tar.gz && cp -rf ocserv_*_v${ver}.tar.gz ./ocserv/tmp && mv ./ocserv/tmp/ocserv_x86_64_v${ver}.tar.gz ./ocserv/tmp/ocserv_amd64.tar.gz && mv ./ocserv/tmp/ocserv_aarch64_v${ver}.tar.gz ./ocserv/tmp/ocserv_arm64.tar.gz && chmod -R 755 ocserv && find ocserv |xargs touch && dpkg -b ocserv ../ocserv_v${ver}.deb && cat ./ocserv/DEBIAN/control


```


