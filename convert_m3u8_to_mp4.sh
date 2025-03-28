#!/bin/bash

echo "📥 Please enter the M3U8 file URL or local path:"
read INPUT_M3U8

OUTPUT_FOLDER="mp4_output"
mkdir -p $OUTPUT_FOLDER

OUTPUT_FILE="$OUTPUT_FOLDER/output.mp4"

echo "🔹 Checking input source..."

# Step 1: Check if the input is a URL or local file
if [[ "$INPUT_M3U8" =~ ^https?:// ]]; then
  echo "🌍 Input is a URL. Downloading playlist..."
  STREAM_URL="$INPUT_M3U8"
else
  if [ ! -f "$INPUT_M3U8" ]; then
    echo "❌ File not found. Please enter a valid M3U8 file."
    exit 1
  fi
  STREAM_URL="file://$INPUT_M3U8"
fi

# Step 2: Convert M3U8 to MP4 with AAC (iOS Compatible)
echo "🎬 Converting M3U8 to MP4 with AAC..."
ffmpeg -protocol_whitelist "file,http,https,tcp,tls" -i "$STREAM_URL" -c:v copy -c:a aac -strict experimental -b:a 128k -bsf:a aac_adtstoasc "$OUTPUT_FILE"

# Step 3: Check if the conversion was successful
if [ $? -eq 0 ]; then
  echo "✅ Conversion complete! File saved at: $OUTPUT_FILE"
  
  # Open the output folder
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$OUTPUT_FOLDER"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "$OUTPUT_FOLDER"
  else
    echo "📂 Please check the folder manually: $OUTPUT_FOLDER"
  fi
else
  echo "❌ Conversion failed. Please check the M3U8 file."
fi