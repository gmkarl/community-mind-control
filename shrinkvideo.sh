#!/bin/bash

TARGETSIZE=$((9*1024*1024))
INFILE="$1"
OUTFILE="${INFILE%.*}.shrunk.mkv"

EXTRA_FFMPEG_ARGS="-loglevel error"
AUDIOCODEC="aac"
VIDEOCODEC="h264"

if [ "x$INFILE" = "x" ] || [ "x$2" != "x" ]; then echo Usage: "$0" INFILE; exit -1; fi

# 1. calculate needed bitrate
#   1a. extract video channel from audio.  subtract audio size from 10mb
AUDIOFILE="${INFILE%.*}.audio.mkv"
ffmpeg -i "file:$INFILE" -map 0:a:0 $EXTRA_FFMPEG_ARGS -acodec $AUDIOCODEC -b:a 24k "file:$AUDIOFILE"
TARGETSIZE=$((TARGETSIZE-$(stat -c %s "$AUDIOFILE")))

#   1b. discern target video rate.
# use audio file to find duration because it is always the same format, unlike the user-provided input
#AUDIOSECS=$(ffprobe "file:$AUDIOFILE" -print_format compact -show_entries stream=duration 2>/dev/null | sed 's/stream|duration=//')
AUDIOSECS=$(
  ffprobe "file:$AUDIOFILE" -print_format compact -show_entries stream_tags=duration 2>/dev/null | sed 's/stream|tag:DURATION=\(..\):\(..\):\(..\)\..*/\1 \2 \3/' | {
    read hours mins secs
    echo $((secs + (mins + (hours * 60)) * 60))
  }
)
VIDEORATE=$((8*TARGETSIZE/AUDIOSECS))

# 2. use 2-pass encoding with a codec at least as modern as h.264
ffmpeg -i "file:$INFILE" $EXTRA_FFMPEG_ARGS -vcodec "$VIDEOCODEC" -b:v "$VIDEORATE" -pass 1 -an -f rawvideo -y /dev/null
ffmpeg -i "file:$AUDIOFILE" -i "file:$INFILE" -vcodec "$VIDEOCODEC" $EXTRA_FFMPEG_ARGS -acodec copy -map 0:a:0 -map 1:v:0 -b:v "$VIDEORATE" -pass 2 "file:$OUTFILE"

rm "$AUDIOFILE"
