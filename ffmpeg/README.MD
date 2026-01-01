#
```
https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux-arm64.zip
https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-mac.zip
https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-mac-arm64.zip

```
# 一键切片并发布
```
# 安装 ffmpeg .
# 上传: 修改 upload_xxxx.sh 文件并保存, 然后将文件重命名为 upload.sh 
# 发布: 修改 publish.sh 文件并保存.
# 限制: 修改 media.sh 文件头部 'MaxSize=N' (N 为单文件最大体积, 默认为: 5).
# 将 upload.sh, publish.sh, m3u8.sh, media.sh 放入同一个文件夹中.

# 用法 (相关文件设置好后,可以一键切片并发布到网站上.)
bash media.sh <不含特殊字符的文件名.mp4> [特殊选项]

# 特殊选项: 数字; 可选参数,默认为0;
# 0: 自动根据文件比特率计算合适的切片大小. (目标文件大小小于10M, 一般VBR编码方式下没问题.)
# 1: 强制重新编码. 重新编码比特率为 2400k .(一般用于非H264视频编码的文件切片,速度较慢)
# 2: 自定义切片时间. 当大于等于2时切片时间为特殊选项数字.
# 当在特殊选项前添加负号(如 -0, -1, -2)时: 强制清空切片目录及其他相关缓存, 否则当全部切片完成后再次运行时跳过切片步骤.
```

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

# 字幕格式转换([webvtt.org](https://www.webvtt.org/))
