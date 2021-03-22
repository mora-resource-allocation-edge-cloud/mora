#
# https://stackoverflow.com/questions/48256686/how-to-create-multi-bit-rate-dash-content-using-ffmpeg-dash-muxer

mkdir /tmp/out
ffmpeg -i video.mp4 \
  -map 0:v:0 -map 0:a\?:0 -map 0:v:0 -map 0:a\?:0 -map 0:v:0 -map 0:a\?:0 -map 0:v:0 -map 0:a\?:0 -map 0:v:0 -map 0:a\?:0 -map 0:v:0 -map 0:a\?:0  \
  -b:v:0 350k  -c:v:0 libx264 -filter:v:0 "scale=640:-1"  \
  -b:v:1 1000k -c:v:1 libx264 -filter:v:1 "scale=854:-1"  \
  -b:v:2 1500k -c:v:2 libx264 -filter:v:2 "scale=1280:-1" \
  -b:v:2 2000k -c:v:2 libx264 -filter:v:2 "scale=1920:-1" \
  -use_timeline 1 -use_template 1 -window_size 30 \
  -adaptation_sets "id=0,streams=v  id=1,streams=a" \
  -hls_playlist true -f dash output/output.mpd


#ffmpeg -y -i video.mp4 ^
#  -c:v libx264 -x264opts "keyint=24:min-keyint=24:no-scenecut" -r 24 ^
#  -c:a aac -b:a 128k ^
#  -bf 1 -b_strategy 0 -sc_threshold 0 -pix_fmt yuv420p ^
#  -map 0:v:0 -map 0:a:0 -map 0:v:0 -map 0:a:0 -map 0:v:0 -map 0:a:0 ^
#  -b:v:0 250k  -filter:v:0 "scale=-2:240" -profile:v:0 baseline ^
#  -b:v:1 750k  -filter:v:1 "scale=-2:480" -profile:v:1 main ^
#  -b:v:2 1500k -filter:v:2 "scale=-2:720" -profile:v:2 high ^
#  sample_dash.mp4
#
#ffmpeg -y -re -i sample_dash.mp4 ^
#  -map 0 ^
#  -use_timeline 1 -use_template 1 -window_size 5 -adaptation_sets "id=0,streams=v id=1,streams=a" ^
#  -f dash sample.mpd

ffmpeg -i video.mp4 \
   -filter_complex "[0]split=6[mid0][mid1];[mid0]scale=320:-1[out0];[mid1]scale=640:-1[out1]"\
   -map [out0] -map 0:a -map [out1]\
    -map 0:a -c:a aac \
    -c:v:0 libx264 \
    -c:v:1 libx264 \
    -use_timeline 1 -use_template 1 -window_size 6 \
    -adaptation_sets "id=0,streams=v  id=1,streams=a" \
    -hls_playlist true -f dash thevideo/video.mpd


ffmpeg -hide_banner -y -i video.mp4 \
  -c:v libx264 -profile:v main -sc_threshold 0 -strict -2 -g 30 -keyint_min 30 \
  -map 0:v -b:v:0 10000k -s:v:0 1920x1080 -maxrate:0 10000k -bufsize:0 7500k -an \
  -map 0:v -b:v:1  5000k -s:v:1 1280x720  -maxrate:1  5000k -bufsize:1 4200k -an \
  -map 0:v -b:v:2  2500k -s:v:2 842x480   -maxrate:2  2500k -bufsize:2 2100k -an \
  -map 0:v -b:v:3   800k -s:v:3 640x360   -maxrate:3   800k -bufsize:3 1200k -an \
  -f dash -use_timeline 1 -use_template 1 -seg_duration 2 -y \
  thevideo2/video.mpd



ffmpeg -hide_banner -y -i video.mp4 \
  -c:v libx264 -profile:v main -sc_threshold 0 -strict -2 -g 30 -keyint_min 30 \
  -map 0:v -b:v:0 10000k -s:v:0 1920x1080 -bufsize:0 7500k -an \
  -map 0:v -b:v:1  5000k -s:v:1 1280x720  -bufsize:1 4200k -an \
  -map 0:v -b:v:2  2500k -s:v:2 842x480   -bufsize:2 2100k -an \
  -map 0:v -b:v:3   800k -s:v:3 640x360   -bufsize:3 1200k -an \
  -f dash -use_timeline 1 -use_template 1 -seg_duration 2 -y \
  thevideo3/video.mpd

ffmpeg -rtbufsize 100M -report -re -i "http://cloud-vms-1.master.particles.dieei.unict.it/videofiles/5fbb7d163c05606e12c4c197/video.mpd" o.mp4
ffmpeg -i "http://cloud-vms-1.master.particles.dieei.unict.it/videofiles/5fbb7d163c05606e12c4c197/video.mpd"\
 -i reference.mp4 \
 -filter_complex "[0:v]scale=1920x1080:flags=bicubic[main]; [1:v]scale=1920x1080:flags=bicubic[ref]; [main][ref]libvmaf=psnr=1:ssim=1:ms_ssim=1:log_fmt=json" \
 -f null -


ffmpeg -rtbufsize 0M -re -i "http://cloud-vms-1.master.particles.dieei.unict.it/videofiles/5fbb7d163c05606e12c4c197/video.mpd" o.mp4 -progress out.log



ffmpeg -rtbufsize 0M -report -re -loglevel verbose -i "http://cloud-vms-1.master.particles.dieei.unict.it/videofiles/5fbb7d163c05606e12c4c197/video.mpd" o.mp4 -vstats -timestamp now

 -filter_complex "[0:v]scale=1920x1080:flags=bicubic[main]; [1:v]scale=1920x1080:flags=bicubic,format=pix_fmts=yuv420p,fps=fps=30/1[ref]; [main][ref]libvmaf=psnr=1:ssim=1:ms_ssim=1:log_fmt=json" \

https://jina-liu.medium.com/a-practical-guide-for-vmaf-481b4d420d9c


ffmpeg -rtbufsize 0M -report -re -i "http://cloud-vms-1.master.particles.dieei.unict.it/videofiles/5fbb7d163c05606e12c4c197/video.mpd" o.mp4 -vstats -timestamp now -progress out.log
cat out.log | sed -e 's/=/:"/' -e 's/$/",/' -e  's/progress.*continue.*/}, {/' -e 's/progress.*end.*/}]/' -e 's/\(^.*\):"/"\1":"/' > out.json

#!/bin/bash

docker run  \
    -e "HOST_URL=http://cloud-vms-1.master.particles.dieei.unict.it" \
    -e "MANIFEST_FILE=/videofiles/5fbb7d163c05606e12c4c197/video.mpd" \
    -e "mode=vod" \
    -e "play_mode=full_playback" \
    -e "bitrate=lowest_bitrate" \
    -p 8089:8089 \
    -v "${PWD}"/test-results/:/test-results/ \
    unified-streaming/streaming-load-testing \
    -f /load_generator/locustfiles/vod_dash_hls_sequence.py \
    --no-web -c 1 -r 1 --run-time 10s --only-summary \
    --csv=../test-results/output_example

./configure --static-modules --enable-static-bin --static-mp4box
