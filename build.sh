#!/bin/bash

# Ensure NDK is available
export ANDROID_NDK_PATH=$ANDROID_HOME/ndk/26.1.10909125

[[ ! -d "$ANDROID_NDK_PATH" ]] && echo "No NDK found, quitting…" && exit 1

# Setup environment
export ANDROIDX_MEDIA_ROOT="${PWD}/media"
export FFMPEG_MOD_PATH="${ANDROIDX_MEDIA_ROOT}/libraries/decoder_ffmpeg/src/main"
export FFMPEG_PATH="${PWD}/ffmpeg"

# 1. ADDED: Added mpeg4 and msmpeg4v3 video decoders to the array
export ENABLED_DECODERS=(flac alac pcm_mulaw pcm_alaw mp3 aac ac3 eac3 dca mlp truehd mpeg4 msmpeg4v3)

# 2. ADDED: Google's underlying script automatically checks this exact variable name.
# We use it to force enable the AVI container format and its byte-stream parser.
export ADDITIONAL_CONFIGURE_FLAGS="--enable-demuxer=avi --enable-parser=mpeg4video"

# Create softlink to ffmpeg
ln -sf "${FFMPEG_PATH}" "${FFMPEG_MOD_PATH}/jni/ffmpeg"

# Start build
cd "${FFMPEG_MOD_PATH}/jni"
./build_ffmpeg.sh "${FFMPEG_MOD_PATH}" "${ANDROID_NDK_PATH}" "linux-x86_64" 23 "${ENABLED_DECODERS[@]}"
