# use sudo with no password
```
# Add rule
sudo sh -c "echo \"$USER\t\tALL = NOPASSWD: /usr/local/bin/exec\" >>/etc/sudoers"
# Delete rule
sudo sh -c "sed -ie \"/\/usr\/local\/bin\/exec/d\" /etc/sudoers"
```
