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
export LIBYUV_PATH="${FFMPEG_MOD_PATH}/jni/libyuv"
export LIBYUV_REV="${LIBYUV_REV:-d23308a2a7442be8e559b1b471862fd7588d6a57}"

export ENABLED_DECODERS=(
    flac alac pcm_mulaw pcm_alaw mp3 aac ac3 eac3 dca mlp truehd
    mpeg4 msmpeg4 msmpeg4v2 msmpeg4v3
)

apply_legacy_media_patch_if_needed() {
    local patch_path="$1"
    local ffmpeg_library="${ANDROIDX_MEDIA_ROOT}/libraries/decoder_ffmpeg/src/main/java/androidx/media3/decoder/ffmpeg/FfmpegLibrary.java"

    if git -C "${ANDROIDX_MEDIA_ROOT}" apply --reverse --check "${patch_path}" >/dev/null 2>&1; then
        echo "Media patch already applied: ${patch_path}"
        return
    fi

    if grep -q "case MimeTypes.VIDEO_DIVX:" "${ffmpeg_library}"; then
        echo "Media FFmpeg video MIME mapping already present; skipping legacy patch."
        return
    fi

    git -C "${ANDROIDX_MEDIA_ROOT}" apply --check "${patch_path}"
    git -C "${ANDROIDX_MEDIA_ROOT}" apply "${patch_path}"
}

remove_deprecated_ffmpeg_configure_flags() {
    local build_ffmpeg="${FFMPEG_MOD_PATH}/jni/build_ffmpeg.sh"
    perl -0pi -e 's/\n\s*--disable-postproc//g' "${build_ffmpeg}"
}

prepare_libyuv() {
    if [[ -d "${LIBYUV_PATH}/.git" ]]; then
        git -C "${LIBYUV_PATH}" fetch --depth 1 origin "${LIBYUV_REV}"
        git -C "${LIBYUV_PATH}" checkout --detach "${LIBYUV_REV}"
        return
    fi

    rm -rf "${LIBYUV_PATH}"
    git clone --no-checkout https://chromium.googlesource.com/libyuv/libyuv "${LIBYUV_PATH}"
    git -C "${LIBYUV_PATH}" fetch --depth 1 origin "${LIBYUV_REV}"
    git -C "${LIBYUV_PATH}" checkout --detach "${LIBYUV_REV}"
}

apply_legacy_media_patch_if_needed "${ROOT_DIR}/patches/androidx-media-ffmpeg-modern-build.patch"
remove_deprecated_ffmpeg_configure_flags

[[ -z "${ANDROID_NDK_PATH:-}" || ! -d "$ANDROID_NDK_PATH" ]] && echo "No NDK found, quitting…" && exit 1

# Create softlink to ffmpeg
ln -sf "${FFMPEG_PATH}" "${FFMPEG_MOD_PATH}/jni/ffmpeg"

if [[ -f "${FFMPEG_MOD_PATH}/jni/build_yuv.sh" ]]; then
    prepare_libyuv
    cd "${FFMPEG_MOD_PATH}/jni"
    ./build_yuv.sh "${FFMPEG_MOD_PATH}" "${ANDROID_NDK_PATH}" 23
fi

# Start build
cd "${FFMPEG_MOD_PATH}/jni"
./build_ffmpeg.sh "${FFMPEG_MOD_PATH}" "${ANDROID_NDK_PATH}" "linux-x86_64" 23 "${ENABLED_DECODERS[@]}"
