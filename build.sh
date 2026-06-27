#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure NDK is available
ANDROID_SDK_DIR="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "${ANDROID_NDK_PATH:-}" && -n "${ANDROID_SDK_DIR}" ]]; then
    export ANDROID_NDK_PATH="${ANDROID_SDK_DIR}/ndk/26.1.10909125"
fi

# Setup environment
export ANDROIDX_MEDIA_ROOT="${ROOT_DIR}/media"
export FFMPEG_MOD_PATH="${ANDROIDX_MEDIA_ROOT}/libraries/decoder_ffmpeg/src/main"
export FFMPEG_PATH="${ROOT_DIR}/ffmpeg"

export ENABLED_DECODERS=(flac alac pcm_mulaw pcm_alaw mp3 aac ac3 eac3 dca mlp truehd mpeg4 msmpeg4v3)

apply_media_patch() {
    local patch_path="$1"

    if git -C "${ANDROIDX_MEDIA_ROOT}" apply --reverse --check "${patch_path}" >/dev/null 2>&1; then
        echo "Media patch already applied: ${patch_path}"
        return
    fi

    git -C "${ANDROIDX_MEDIA_ROOT}" apply --check "${patch_path}"
    git -C "${ANDROIDX_MEDIA_ROOT}" apply "${patch_path}"
}

apply_media_patch "${ROOT_DIR}/patches/androidx-media-ffmpeg-modern-build.patch"

[[ -z "${ANDROID_NDK_PATH:-}" || ! -d "$ANDROID_NDK_PATH" ]] && echo "No NDK found, quitting…" && exit 1

# Create softlink to ffmpeg
ln -sf "${FFMPEG_PATH}" "${FFMPEG_MOD_PATH}/jni/ffmpeg"

# Start build
cd "${FFMPEG_MOD_PATH}/jni"
./build_ffmpeg.sh "${FFMPEG_MOD_PATH}" "${ANDROID_NDK_PATH}" "linux-x86_64" 23 "${ENABLED_DECODERS[@]}"
