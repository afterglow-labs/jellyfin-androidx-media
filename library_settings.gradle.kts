val mediaRootDir = file("media")

val mediaModulePrefix = "androidx-media-"
val mediaProjectPrefix = ":$mediaModulePrefix"
gradle.extra["androidxMediaModulePrefix"] = mediaModulePrefix

if (!gradle.extra.has("androidxMediaSettingsDir")) {
    gradle.extra["androidxMediaSettingsDir"] = mediaRootDir.getCanonicalPath()
}

fun includeMediaModule(name: String, path: String) {
    val projectDir = File(mediaRootDir, path)
    if (!projectDir.isDirectory) {
        return
    }
    val projectPath = mediaProjectPrefix + name
    include(projectPath)
    project(projectPath).projectDir = projectDir
}

includeMediaModule("lib-common", "libraries/common")
includeMediaModule("lib-container", "libraries/container")
includeMediaModule("lib-exoplayer", "libraries/exoplayer")
includeMediaModule("lib-exoplayer-dash", "libraries/exoplayer_dash")
includeMediaModule("lib-database", "libraries/database")
includeMediaModule("lib-datasource", "libraries/datasource")
includeMediaModule("lib-decoder", "libraries/decoder")
includeMediaModule("lib-decoder-ffmpeg", "libraries/decoder_ffmpeg")
includeMediaModule("lib-extractor", "libraries/extractor")
includeMediaModule("lib-effect", "libraries/effect")
includeMediaModule("lib-inspector", "libraries/inspector")
includeMediaModule("lib-inspector-frame", "libraries/inspector_frame")
includeMediaModule("lib-muxer", "libraries/muxer")
includeMediaModule("lib-transformer", "libraries/transformer")

includeMediaModule("test-utils-robolectric", "libraries/test_utils_robolectric")
includeMediaModule("test-data", "libraries/test_data")
includeMediaModule("test-utils", "libraries/test_utils")
