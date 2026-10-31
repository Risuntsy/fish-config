# Completions for scrcpy <https://github.com/Genymobile/scrcpy>

function __fish_scrcpy_devices
    adb devices -l 2>/dev/null | string replace -rf '^(\S+)\s+device\s+(.*)$' '$1\t$2'
end

function __fish_scrcpy_packages
    adb shell pm list packages 2>/dev/null | string replace -f 'package:' ''
end

set -l orientations 0 90 180 270 flip0 flip90 flip180 flip270
set -l audio_sources output playback mic mic-unprocessed mic-camcorder mic-voice-recognition mic-voice-communication voice-call voice-call-uplink voice-call-downlink voice-performance

complete -c scrcpy -f

# Device selection and connection
complete -c scrcpy -s s -l serial -x -a '(__fish_scrcpy_devices)' -d 'Device serial number'
complete -c scrcpy -s d -l select-usb -d 'Use USB device'
complete -c scrcpy -s e -l select-tcpip -d 'Use TCP/IP device'
complete -c scrcpy -l tcpip -d 'Configure and connect the device over TCP/IP ([+]ip[:port])'
complete -c scrcpy -s p -l port -x -d 'TCP port (range) the client listens on (port[:port])'
complete -c scrcpy -l force-adb-forward -d 'Do not use "adb reverse"'
complete -c scrcpy -l tunnel-host -x -d 'IP address of the adb tunnel'
complete -c scrcpy -l tunnel-port -x -d 'TCP port of the adb tunnel'
complete -c scrcpy -l kill-adb-on-close -d 'Kill adb when scrcpy terminates'
complete -c scrcpy -l otg -d 'Run in OTG mode'

# Video
complete -c scrcpy -l video-source -x -a 'display camera' -d 'Video source'
complete -c scrcpy -l video-codec -x -a 'h264 h265 av1 vp8 vp9' -d 'Video codec'
complete -c scrcpy -l video-codec-options -x -d 'Video encoder options (key[:type]=value[,...])'
complete -c scrcpy -l video-encoder -x -d 'MediaCodec video encoder'
complete -c scrcpy -s b -l video-bit-rate -x -d 'Video bit rate (e.g. 8M)'
complete -c scrcpy -l video-buffer -x -d 'Video buffering delay (ms)'
complete -c scrcpy -s m -l max-size -x -d 'Limit video width and height'
complete -c scrcpy -l max-fps -x -d 'Limit capture frame rate'
complete -c scrcpy -l min-size-alignment -x -a '1 2 4 8 16' -d 'Minimum video size alignment'
complete -c scrcpy -l ignore-video-encoder-constraints -d 'Ignore video encoder capabilities'
complete -c scrcpy -l no-downsize-on-error -d 'Do not retry with lower definition on error'
complete -c scrcpy -l crop -x -d 'Crop device screen (width:height:x:y)'
complete -c scrcpy -l angle -x -d 'Rotate video content by degrees'
complete -c scrcpy -l capture-orientation -x -a "$orientations @" -d 'Capture video orientation'
complete -c scrcpy -l display-orientation -x -a "$orientations" -d 'Initial display orientation'
complete -c scrcpy -l record-orientation -x -a '0 90 180 270' -d 'Record orientation'
complete -c scrcpy -l orientation -x -a "$orientations" -d 'Display and record orientation'
complete -c scrcpy -l hwdec -x -a 'auto disabled vaapi d3d11va videotoolbox' -d 'Hardware video decoding'
complete -c scrcpy -l no-video -d 'Disable video forwarding'
complete -c scrcpy -l no-video-playback -d 'Disable video playback on the computer'
complete -c scrcpy -l print-fps -d 'Start FPS counter'

# Display
complete -c scrcpy -l display-id -x -d 'Device display id to mirror'
complete -c scrcpy -l new-display -d 'Create a new display ([<width>x<height>][/<dpi>])'
complete -c scrcpy -s x -l flex-display -d 'Resize the virtual display to match the window'
complete -c scrcpy -l display-ime-policy -x -a 'local fallback hide' -d 'Where the IME is displayed'
complete -c scrcpy -l no-vd-destroy-content -d 'Move apps to main display when virtual display closes'
complete -c scrcpy -l no-vd-system-decorations -d 'Disable virtual display system decorations'
complete -c scrcpy -l start-app -x -a '(__fish_scrcpy_packages)' -d 'Start an Android app by package name'

# Camera
complete -c scrcpy -l camera-id -x -d 'Device camera id'
complete -c scrcpy -l camera-facing -x -a 'front back external' -d 'Camera facing direction'
complete -c scrcpy -l camera-size -x -d 'Camera capture size (<width>x<height>)'
complete -c scrcpy -l camera-ar -x -a 'sensor' -d 'Camera aspect ratio'
complete -c scrcpy -l camera-fps -x -d 'Camera capture frame rate'
complete -c scrcpy -l camera-high-speed -d 'High-speed camera capture mode'
complete -c scrcpy -l camera-torch -d 'Turn on the camera torch'
complete -c scrcpy -l camera-zoom -x -d 'Initial camera zoom'

# Audio
complete -c scrcpy -l audio-source -x -a "$audio_sources" -d 'Audio source'
complete -c scrcpy -l audio-codec -x -a 'opus aac flac raw' -d 'Audio codec'
complete -c scrcpy -l audio-codec-options -x -d 'Audio encoder options (key[:type]=value[,...])'
complete -c scrcpy -l audio-encoder -x -d 'MediaCodec audio encoder'
complete -c scrcpy -l audio-bit-rate -x -d 'Audio bit rate (e.g. 128K)'
complete -c scrcpy -l audio-buffer -x -d 'Audio buffering delay (ms)'
complete -c scrcpy -l audio-output-buffer -x -d 'SDL audio output buffer (ms)'
complete -c scrcpy -l audio-dup -d 'Keep playing audio on the device'
complete -c scrcpy -l no-audio -d 'Disable audio forwarding'
complete -c scrcpy -l no-audio-playback -d 'Disable audio playback on the computer'
complete -c scrcpy -l require-audio -d 'Fail if audio does not work'
complete -c scrcpy -s N -l no-playback -d 'Disable video and audio playback'

# Recording and sinks
complete -c scrcpy -s r -l record -r -F -d 'Record screen to file'
complete -c scrcpy -l record-format -x -a 'mp4 mkv m4a mka opus aac flac wav' -d 'Recording format'
complete -c scrcpy -l v4l2-sink -x -a '(path filter /dev/video*)' -d 'Output to v4l2loopback device'
complete -c scrcpy -l v4l2-buffer -x -d 'V4L2 buffering delay (ms)'
complete -c scrcpy -l time-limit -x -d 'Maximum mirroring time (s)'

# Input
complete -c scrcpy -l keyboard -x -a 'disabled sdk uhid aoa' -d 'Keyboard input mode'
complete -c scrcpy -l mouse -x -a 'disabled sdk uhid aoa' -d 'Mouse input mode'
complete -c scrcpy -l gamepad -x -a 'disabled uhid aoa' -d 'Gamepad input mode'
complete -c scrcpy -s K -d 'Same as --keyboard=uhid (aoa with --otg)'
complete -c scrcpy -s M -d 'Same as --mouse=uhid (aoa with --otg)'
complete -c scrcpy -s G -d 'Same as --gamepad=uhid (aoa with --otg)'
complete -c scrcpy -l mouse-bind -x -d 'Secondary click bindings (xxxx[:xxxx])'
complete -c scrcpy -l no-mouse-hover -d 'Do not forward mouse hover events'
complete -c scrcpy -s n -l no-control -d 'Disable device control (read-only)'
complete -c scrcpy -l no-key-repeat -d 'Do not forward repeated key events'
complete -c scrcpy -l prefer-text -d 'Inject alpha characters and space as text'
complete -c scrcpy -l raw-key-events -d 'Inject key events for all input keys'
complete -c scrcpy -l legacy-paste -d 'Inject clipboard as key events on Ctrl+v'
complete -c scrcpy -l no-clipboard-autosync -d 'Disable clipboard synchronization'
complete -c scrcpy -l shortcut-mod -x -a 'lctrl rctrl lalt ralt lsuper rsuper' -d 'Shortcut modifiers'

# Device state
complete -c scrcpy -s S -l turn-screen-off -d 'Turn the device screen off'
complete -c scrcpy -s w -l stay-awake -d 'Keep the device on while plugged in'
complete -c scrcpy -l keep-active -d 'Keep the screen on by simulating activity'
complete -c scrcpy -s t -l show-touches -d 'Enable "show touches"'
complete -c scrcpy -l screen-off-timeout -x -d 'Screen off timeout while running (s)'
complete -c scrcpy -l power-off-on-close -d 'Turn the device screen off on close'
complete -c scrcpy -l no-power-on -d 'Do not power on the device on start'
complete -c scrcpy -l no-cleanup -d 'Do not restore device state on exit'
complete -c scrcpy -l push-target -x -d 'Device directory for drag & drop pushes'

# Window
complete -c scrcpy -s f -l fullscreen -d 'Start in fullscreen'
complete -c scrcpy -l always-on-top -d 'Keep window always on top'
complete -c scrcpy -l window-title -x -d 'Custom window title'
complete -c scrcpy -l window-x -x -d 'Initial window horizontal position'
complete -c scrcpy -l window-y -x -d 'Initial window vertical position'
complete -c scrcpy -l window-width -x -d 'Initial window width'
complete -c scrcpy -l window-height -x -d 'Initial window height'
complete -c scrcpy -l window-borderless -d 'Borderless window'
complete -c scrcpy -l no-window -d 'Disable scrcpy window'
complete -c scrcpy -l no-window-aspect-ratio-lock -d 'Disable window aspect ratio lock'
complete -c scrcpy -l render-fit -x -a 'letterbox stretched unscaled' -d 'How rendering fits the window'
complete -c scrcpy -l render-driver -x -a 'direct3d opengl opengles2 opengles metal software' -d 'SDL render driver hint'
complete -c scrcpy -l no-mipmaps -d 'Disable mipmap generation'
complete -c scrcpy -l background-color -x -d 'Background color (#RGB or #RRGGBB)'
complete -c scrcpy -l disable-screensaver -d 'Disable screensaver while running'

# Information and misc
complete -c scrcpy -l list-apps -d 'List installed Android apps'
complete -c scrcpy -l list-cameras -d 'List device cameras'
complete -c scrcpy -l list-camera-sizes -d 'List valid camera capture sizes'
complete -c scrcpy -l list-displays -d 'List device displays'
complete -c scrcpy -l list-encoders -d 'List video and audio encoders'
complete -c scrcpy -s V -l verbosity -x -a 'verbose debug info warn error' -d 'Log level'
complete -c scrcpy -l pause-on-exit -a 'true false if-error' -d 'Pause on exit'
complete -c scrcpy -l no-terminal-title -d 'Disable terminal title updates'
complete -c scrcpy -s h -l help -d 'Print help'
complete -c scrcpy -s v -l version -d 'Print version'
