#!/bin/bash

echo "📥 Please enter the MP4 URL or local file path:"
read INPUT_VIDEO

if [ ! -f "$INPUT_VIDEO" ]; then
  echo "❌ File not found. Please enter a valid file path."
  exit 1
fi

OUTPUT_FOLDER="hls_output"
mkdir -p $OUTPUT_FOLDER

# Step 1: List audio tracks
echo "🔍 Checking available audio tracks..."
AUDIO_COUNT=0
for STREAM in $(ffprobe -i "$INPUT_VIDEO" -show_streams -select_streams a -loglevel error | grep index | cut -d= -f2); do
  echo "🎵 Audio Track $AUDIO_COUNT: Stream Index $STREAM"
  AUDIO_COUNT=$((AUDIO_COUNT+1))
done

if [ "$AUDIO_COUNT" -eq 0 ]; then
  echo "⚠️ No audio tracks found in this file!"
  exit 1
fi

echo "❓ Do you want to proceed with HLS conversion? (y/n)"
read CONFIRM

if [ "$CONFIRM" != "y" ]; then
  echo "❌ Conversion canceled."
  exit 1
fi

# Step 2: Extract and convert all audio tracks to MPEG-4 AAC (mp4a.40.2)
echo "🔹 Extracting and converting audio tracks..."
AUDIO_MAPS=""
AUDIO_PLAYLISTS=""
for (( i=0; i<$AUDIO_COUNT; i++ )); do
  ffmpeg -i "$INPUT_VIDEO" -map 0:a:$i -c:a aac -b:a 128k -ac 2 -ar 48000 "$OUTPUT_FOLDER/audio_$i.m4a"
  AUDIO_MAPS+=" -i $OUTPUT_FOLDER/audio_${i}.m4a -map $(($i+1)):a:0 -c:a aac -b:a 128k -ac 2 -ar 48000"
  AUDIO_PLAYLISTS+=" a:${i},name:audio_${i},group:aac,language:eng"
  if [ $i -eq 0 ]; then
    AUDIO_PLAYLISTS+=",default:yes"
  fi
done

# Step 3: Encode MP4 to HLS with MPEG-4 AAC
echo "🔹 Encoding video to HLS..."
VIDEO_OPTS="-map 0:v:0 -c:v libx264 -preset fast -g 48 -sc_threshold 0 -b:v 4M"
HLS_OPTS="-hls_segment_type fmp4 -hls_flags independent_segments -hls_time 6 -hls_playlist_type vod"
VAR_MAP="v:0"

ffmpeg -i "$INPUT_VIDEO" $AUDIO_MAPS \
  $VIDEO_OPTS $HLS_OPTS \
  -hls_segment_filename "$OUTPUT_FOLDER/video_%03d.m4s" \
  -master_pl_name master.m3u8 \
  -var_stream_map "$VAR_MAP,$AUDIO_PLAYLISTS" "$OUTPUT_FOLDER/output.m3u8"

echo "✅ HLS conversion complete. Files saved in $OUTPUT_FOLDER"

# Step 4: Open output folder
if [[ "$OSTYPE" == "darwin"* ]]; then
  open "$OUTPUT_FOLDER"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  xdg-open "$OUTPUT_FOLDER"
else
  echo "📂 Please check the folder manually: $OUTPUT_FOLDER"
fi
