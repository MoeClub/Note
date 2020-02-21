# 获取媒体文件时长
```
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 <File>
```

# 获取媒体文件大小
```
ffprobe -v error -show_entries format=size -of default=noprint_wrappers=1:nokey=1 <File>
```

# 获取媒体文件比特率
```
ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 <File>
```

# 视频文件切片
```
# 平均码率转换
ffmpeg -i <File> -vcodec copy -acodec aac -bsf:v h264_mp4toannexb -b:v 2000k -bufsize 2000k -maxrate 2250k output.mp4
# 切片
ffmpeg -i output.mp4 -vcodec copy -acodec copy -map 0 -f segment -segment_list output.m3u8 -segment_time 10 output_%03d.ts
```

# 视频文件直接切片
```
ffmpeg -i <File> -vcodec copy -acodec aac -bsf:v h264_mp4toannexb -map 0 -f segment -segment_list output.m3u8 -segment_time 10 output_%03d.ts
```
