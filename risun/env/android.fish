set -l ndk_builds "$HOME/.local/share/android-sdk/ndk"/*/ndk-build
if set -q ndk_builds[1]
    set -gx NDK (path dirname $ndk_builds | sort -V)[-1]
end
