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

# 获取视频文件编码
```
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 <File>
```

# 视频文件直接切片
```
ffmpeg -i <File> -vcodec copy -acodec aac -bsf:v h264_mp4toannexb -map 0 -f segment -segment_list output.m3u8 -segment_time 10 output_%03d.ts
```

# M3U8合成视频文件
```
ffmpeg -allowed_extensions ALL -i "meida.m3u8" -c copy "media.mp4"
```

# 分片时长计算(VBR, 大约)
```
分片时间 = (文件限制大小[M] * 1024 * 1024) / (媒体文件比特率[b] * 突发码率比率 / 8)
突发码率比率: 1.35 (视情况取值, 大于等于1) 
```
