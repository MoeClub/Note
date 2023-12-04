# frpc.ini
```
[common]
server_addr = 
server_port = 
token = 
login_fail_exit = false
use_encryption = false
use_compression = false

[ssh]
type = "tcp"
local_ip = "127.0.0.1"
local_port = 22
remote_port = 8022

[web]
type = "tcp"
local_ip = "127.0.0.1"
local_port = 80
remote_port = 8080

```
