# Build
```
# go build -ldflags "-w -s" -trimpath -o speedtest main.go

CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-w -s' -trimpath -o ./build/linux_amd64/speedtest main.go
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags '-w -s' -trimpath -o ./build/linux_arm64/speedtest main.go

```
