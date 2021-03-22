#!/bin/sh

while read -r video_id; do
    ln -s /videofiles/thevideo /videofiles/"$video_id"
    ln -s /videofiles/thevideo.tar.gz /videofiles/"$video_id.tar"
done < /tmp/foo

# tar -cvf /videofiles/$1.tar -C /videofiles/ $1/




while read -r video_id; do
    ln -s /videofiles/thevideo.tar.gz /videofiles/"$video_id.tar"
done < /tmp/foo


# https://github.com/unifiedstreaming/streaming-load-testing/blob/master/docs/MMSys2020-paper.pdf


# http://localhost:3000/samples/dash-if-reference-player-api-metrics-push/index.html?url=https://dash.akamaized.net/akamai/bbb_30fps/bbb_30fps.mpd&autoplay=true&apiUrl=http://video-metrics-collector.zion.alessandrodistefano.eu:8080/v1/video-reproduction
