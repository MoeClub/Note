# Build
```
# go build -ldflags "-w -s" -trimpath -o speedtest main.go

CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-w -s' -trimpath -o ./build/linux_amd64/speedtest main.go
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags '-w -s' -trimpath -o ./build/linux_arm64/speedtest main.go

```


# Install
```
wget -qO- https://raw.githubusercontent.com/MoeClub/Note/master/SpeedTest/install.sh |bash
```

# Manual Run
```
# chmod u+x ./speedtest && ./speedtest
# http://IP:8888

```
