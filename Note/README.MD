# use sudo with no password
```
# Add rule
sudo sh -c "echo \"$USER\t\tALL = NOPASSWD: /usr/local/bin/exec\" >>/etc/sudoers"
# Delete rule
sudo sh -c "sed -ie \"/\/usr\/local\/bin\/exec/d\" /etc/sudoers"
```

# Run besttrace for linux
```
command -v unzip >/dev/null 2>&1; [ $? -eq 0 ] && { command -v wget >/dev/null 2>&1; [ $? -eq 0 ] && { [ `getconf LONG_BIT` == 32 ] && filename="besttrace32" || filename="besttrace"; wget --no-check-certificate -qO /tmp/besttrace4linux.zip https://cdn.ipip.net/17mon/besttrace4linux.zip && unzip -o /tmp/besttrace4linux.zip "$filename" && { chmod 755 "$filename" && [ "$filename" != "besttrace" ] && mv -f "$filename" besttrace && echo "file: $filename --> besttrace" || echo "file: besttrace"; } || echo "Download error"; } || echo "Not found wget" ; } || echo "Not found unzip";

```
