# 获取媒体文件时长
```
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 <File>
```

# 获取媒体文件大小
```
ffprobe -v error -show_entries format=size -of default=noprint_wrappers=1:nokey=1 <File>
```

# 视频文件切片
```
ffmpeg -i <File> -vcodec copy -acodec aac -hls_list_size 0 -hls_segment_size 3000000 -f hls output.m3u8
ffmpeg -i <File> -vcodec copy -acodec aac -map 0 -f segment -segment_list output.m3u8 -segment_time 10 output_%03d.ts
```
