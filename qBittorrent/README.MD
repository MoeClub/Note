# build
```
bash <(curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/qBittorrent/qbittorrent-nox-static.sh") all -i -c -qt release-4.4.2 -lt v2.0.6

rm -rf /tmp/qbittorrent && cp ~/qbt-build/bin/qbittorrent-nox /tmp/qbittorrent && cd /tmp
XZ_OPT=-9 tar -Jcvf /tmp/qbittorrent_$(uname -m)_v4.4.2_lt_v2.0.6.tar.xz  qbittorrent


```

# nginx
```
	location /qbt/ {
		gzip on;
		if ($request_method !~ "GET|POST") { return 404; } 
		client_max_body_size 32m;
    
		# access_log /var/log/nginx/access_qbt.log;
		# error_log /var/log/nginx/error_qbt.log;
    
		# auth_basic "qBittorrent";
		# auth_basic_user_file /etc/nginx/passwd;
		## echo "admin:$(openssl passwd -quiet adminadmin)" |tee -a /etc/nginx/passwd
    
		proxy_http_version 1.1;
		proxy_set_header X-Forwarded-For $remote_addr;
		proxy_pass http://127.0.0.1:8080/;
	}

```
