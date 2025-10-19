function ffmpeg_extract_audio
    if not command --query ffmpeg
        echo "ffmpeg is not installed, please install ffmpeg first"
        return 1
    end

    if test (count $argv) -lt 2
        echo "Usage: ffmpeg_extract_audio <src_video> <dest_audio> [track_id]"
        return 1
    end

    set -l src $argv[1]
    set -l dest $argv[2]
    set -l track_id 0
    if test (count $argv) -ge 3
        set track_id $argv[3]
    end

    set -l dest_dir (dirname "$dest")
    if not test -d "$dest_dir"
        mkdir -p "$dest_dir"
    end

    ffmpeg -i "$src" -map 0:a:$track_id -vn -acodec copy "$dest"
end

function ffmpeg_remux_video
    if not command --query ffmpeg
        echo "ffmpeg is not installed, please install ffmpeg first"
        return 1
    end

    if test (count $argv) -lt 2
        echo "Usage: ffmpeg_remux_video <src_video_file> <dest_video_file>"
        return 1
    end

    set -l src $argv[1]
    set -l dest $argv[2]

    set -l dest_dir (dirname "$dest")
    if not test -d "$dest_dir"
        mkdir -p "$dest_dir"
    end

    ffmpeg -i "$src" -map 0 -c copy -movflags +faststart "$dest"; or return $status
    rm "$src"
end


# Converts an audio file to a different format using FFmpeg.
# It uses high-quality VBR for lossy formats (like .mp3) and standard settings for lossless formats (like .flac).
#
# Usage:
#   ffmpeg_convert_audio <source_audio_file> <destination_audio_file>
#
# Examples:
#   # Convert a FLAC file to a high-quality MP3
#   ffmpeg_convert_audio "01. My Song.flac" "01. My Song.mp3"
#
#   # Convert an MP3 file to FLAC for format consistency
#   ffmpeg_convert_audio audio.mp3 archive/audio.flac
#
function ffmpeg_convert_audio
    if not command --query ffmpeg
        echo "ffmpeg is not installed, please install ffmpeg first"
        return 1
    end

    if test (count $argv) -lt 2
        echo "Usage: ffmpeg_convert_audio <src_audio_file> <dest_audio_file>"
        return 1
    end

    set -l src $argv[1]
    set -l dest $argv[2]
    set -l dest_ext (string lower -- (path extension "$dest"))

    set -l dest_dir (dirname "$dest")
    if not test -d "$dest_dir"
        mkdir -p "$dest_dir"
    end

    # --- FIX IS HERE ---
    # Define options as a list of arguments, not a single quoted string.
    # This ensures each part is passed as a separate argument to ffmpeg.

    # Default to high-quality variable bitrate for lossy formats.
    set -l ffmpeg_opts -map 0:a -q:a 0

    # For lossless formats, specify the codec directly.
    switch $dest_ext
        case .flac
            set ffmpeg_opts -map 0:a -c:a flac
        case .alac
            set ffmpeg_opts -map 0:a -c:a alac
        case .wav
            set ffmpeg_opts -map 0:a -c:a pcm_s16le
    end

    echo "Converting to '$dest_ext' with options: $ffmpeg_opts"

    ffmpeg -i "$src" $ffmpeg_opts "$dest"; or return $status
end