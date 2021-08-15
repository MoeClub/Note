# Install Deluge
```
bash <()
```

# Nginx
```
    location ^~ /deluge {
        if ($request_uri = "/deluge") { rewrite .* "$scheme://$host$uri/" redirect; }
        auth_basic "\n";
        auth_basic_user_file /etc/nginx/password;
        proxy_set_header Cookie "_session_id=000000000000000000000000000;";
        proxy_cookie_domain $proxy_host $host;
        proxy_pass http://127.0.0.1:8112;
    }

```
