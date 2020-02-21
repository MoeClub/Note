# 获取媒体文件时长
```
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 <File>
```

# 获取媒体文件大小
```
ffprobe -v error -show_entries format=size -of default=noprint_wrappers=1:nokey=1 <File>
```


