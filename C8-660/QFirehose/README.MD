# Run in CPE
```
chmod 777 ./QFirehose-arm
./QFirehose-arm -p 9008

```

# Run in Ubuntu
```
chmod 777 ./QFirehose-ubuntu
./QFirehose-ubuntu -f RM520NCN-20231129A -p 192.168.1.1:9008

```

# Run Ubuntu in Docker
```
docker pull ubuntu:latest
docker run  -v "$HOME/Downloads:/home/Downloads" --privileged=true --name ubuntu -itd ubuntu:latest

docker exec -it ubuntu /bin/bash


docker ps -a
docker stop ubuntu

docker ps -q -f status=exited -f status=dead |xargs docker rm 

```
