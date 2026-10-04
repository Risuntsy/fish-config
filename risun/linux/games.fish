# Games launch commands (Linux only)

source (path dirname (status filename))/game-proton.fish

set -g DW_PROTON_PATH (_game_resolve_proton dw 2>/dev/null)
set -g GE_PROTON_PATH (_game_resolve_proton ge 2>/dev/null)

set -g DEFAULT_GAME_PROTON dw


set -g _GAME_LABWC_SESSION (path resolve (path dirname (status filename))/labwc-daily-session.py)

# Every launcher is a thin wrapper around _game_run. Each toggle has exactly one
# flag, the opposite of its default: Proton Wayland and gamemode are on unless
# disabled, while mangohud and labwc are off unless enabled. labwc is headed
# unless --headless; headless wayvnc is on unless --disable-wayvnc. Anything
# _game_run does not recognize is forwarded to the game executable.
function _game_run --description "Launch a Proton game via umu-run, directly or inside a labwc session"
    argparse --ignore-unknown \
        'name=' \
        'exe=' \
        'prefix=' \
        'proton=' \
        'gameid=' \
        'cwd=' \
        'env=+' \
        'machine-id-file=' \
        'disable-wayland' \
        'disable-gamemode' \
        'enable-mangohud' \
        'labwc' \
        'session-id=' \
        'headless' \
        'disable-wayvnc' \
        'retry-times=' \
        -- $argv
    or return 1

    set -l game_args $argv

    set -l proton $DEFAULT_GAME_PROTON
    test -n "$_flag_proton"; and set proton $_flag_proton

    set -l name (basename $_flag_prefix)
    test -n "$_flag_name"; and set name $_flag_name

    set -l wayland 1
    set -q _flag_disable_wayland; and set wayland 0

    # A session ID names the nested compositor, so it only means something when
    # there is one. Without an ID the session simply goes unregistered.
    if test -n "$_flag_session_id"; and not set -q _flag_labwc
        echo "$name: --session-id requires --labwc" >&2
        return 1
    end
    if set -q _flag_headless; and not set -q _flag_labwc
        echo "$name: --headless requires --labwc" >&2
        return 1
    end
    if set -q _flag_disable_wayvnc; and not set -q _flag_labwc
        echo "$name: --disable-wayvnc requires --labwc" >&2
        return 1
    end

    set proton (_game_resolve_proton "$proton")
    or return 1

    if not test -f $_flag_exe
        echo "$name: game executable not found at: $_flag_exe" >&2
        return 1
    end

    if test -n "$_flag_cwd"; and not test -d $_flag_cwd
        echo "$name: game directory not found at: $_flag_cwd" >&2
        return 1
    end

    if test -n "$_flag_machine_id_file"
        if not test -f $_flag_machine_id_file
            echo "$name: machine-id file not found at: $_flag_machine_id_file" >&2
            return 1
        end
        if not command -q bwrap
            echo "$name: bwrap is required to override the Wine system UUID" >&2
            return 1
        end
    end

    set -l env_vars \
        WINEPREFIX=$_flag_prefix \
        PROTONPATH=$proton \
        PROTON_ENABLE_WAYLAND=$wayland \
        MESA_VK_IGNORE_CONFORMANCE_WARNING=true
    test -n "$_flag_gameid"; and set -a env_vars GAMEID=$_flag_gameid
    # --env may be repeated; each value is a bare NAME=VALUE pair.
    set -q _flag_env; and set -a env_vars $_flag_env

    set -l command \
        umu-run \
        $_flag_exe \
        $game_args
    set -q _flag_enable_mangohud; and set command mangohud $command

    # gamemode is on by default, but labwc mode already runs the game inside a
    # dedicated session, so leave the host governor alone there.
    if not set -q _flag_disable_gamemode; and not set -q _flag_labwc
        set command gamemoderun $command
    end

    # Wine derives Win32_ComputerSystemProduct.UUID from the Linux machine-id.
    # Override it inside a private mount namespace without changing the host.
    if test -n "$_flag_machine_id_file"
        set command \
            bwrap \
            --dev-bind / / \
            --ro-bind $_flag_machine_id_file /etc/machine-id \
            -- \
            $command
    end

    mkdir -p $_flag_prefix

    # Some games only run from their own directory. env changes directory for
    # the game alone, so the launcher never leaves the shell somewhere else.
    set -l env_cmd env
    test -n "$_flag_cwd"; and set env_cmd env --chdir=$_flag_cwd

    # Retrying is off by default: a game that dies should surface the error
    # rather than silently relaunch. Callers whose game has a known flaky
    # startup (e.g. an anti-cheat driver race) opt in with --retry-times.
    # Only a fast failure is retried; a crash minutes into a session is a real
    # problem and should be reported instead of retried away.
    set -l max_attempts 1
    test -n "$_flag_retry_times"; and set max_attempts $_flag_retry_times
    set -l fail_seconds 60

    if not set -q _flag_labwc
        for attempt in (seq $max_attempts)
            set -l started (date +%s)
            systemd-inhibit \
                --what=idle \
                --who=$name \
                --why="Game is running" \
                $env_cmd \
                $env_vars \
                $command
            set -l game_status $status
            set -l elapsed (math (date +%s) - $started)

            if test $game_status -eq 0
                return 0
            end
            if test $attempt -eq $max_attempts; or test $elapsed -ge $fail_seconds
                return $game_status
            end
            echo "$name: exited $game_status after $elapsed""s, attempt $attempt/$max_attempts" >&2
        end
        return 1
    end

    # Keep the pad on the host session instead of the nested game. An empty
    # allowlist ignores every controller, so this does not break when the pad
    # is switched to a mode that reports a different VID/PID -- and unlike
    # SDL_GAMECONTROLLER_IGNORE_DEVICES, Proton does not drop it when its own
    # Wayland backend is on.
    set -a env_vars SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT=0x0000/0x0000

    set -l session_argv uv run python $_GAME_LABWC_SESSION run
    test -n "$_flag_session_id"; and set -a session_argv --session-id "$_flag_session_id"
    # Headed labwc already has a window on the host, so skip wayVNC. Headless
    # has no local screen, so start wayVNC unless the caller opts out.
    set -l backend wayland
    if set -q _flag_headless
        set backend headless
        set -q _flag_disable_wayvnc; and set -a session_argv --disable-wayvnc
    else
        set -a session_argv --auto-output --disable-wayvnc
    end

    for attempt in (seq $max_attempts)
        set -l status_file (mktemp)
        or return 1
        set -l session_command (string join -- ' ' (string escape -- \
            $session_argv --exit-status-file $status_file \
            $env_cmd \
            $env_vars \
            $command))
        set -l started (date +%s)
        env WLR_BACKENDS=$backend \
            labwc \
            --session "$session_command"
        set -l game_status $status
        if test $game_status -eq 0
            # A missing result means the session helper did not finish.
            set game_status 1
            set -l session_status (string trim -- (cat $status_file))
            if string match -qr '^[0-9]+$' -- "$session_status"
                set game_status $session_status
            end
        end
        command unlink $status_file
        set -l elapsed (math (date +%s) - $started)

        if test $game_status -eq 0
            return 0
        end
        if test $attempt -eq $max_attempts; or test $elapsed -ge $fail_seconds
            return $game_status
        end
        echo "$name: exited $game_status after $elapsed""s, attempt $attempt/$max_attempts" >&2
    end
    return 1
end

# Prints {"wayland_display": ..., "vnc_port": ...} for a session that is up,
# so another terminal can reach the nested compositor a daily launcher created.
function game_session --description "Print a labwc daily session's connection details as JSON"
    # The Python CLI needs `get <id>`. Accept both `game_session wuwa` and
    # `game_session get wuwa` so a leading get is not passed through twice.
    set -l id $argv
    if test (count $id) -ge 1; and test $id[1] = get
        set -e id[1]
    end
    uv run python $_GAME_LABWC_SESSION get $id
end

function wineserver_kill --description "Kill the wineserver for the current PROTONPATH/WINEPREFIX"
    if test -z "$PROTONPATH"
        echo "wineserver_kill: PROTONPATH is not set" >&2
        return 1
    end

    if test -z "$WINEPREFIX"
        echo "wineserver_kill: WINEPREFIX is not set" >&2
        return 1
    end

    set -l wineserver "$PROTONPATH/files/bin/wineserver"

    if not test -x $wineserver
        echo "wineserver_kill: wineserver not found at: $wineserver" >&2
        return 1
    end

    env WINEPREFIX="$WINEPREFIX" $wineserver -k
end

function _game_kill --description "Kill the wineserver for a game prefix"
    argparse 'prefix=' 'proton=' -- $argv
    or return 1

    set -l proton $DEFAULT_GAME_PROTON
    test -n "$_flag_proton"; and set proton $_flag_proton
    set proton (_game_resolve_proton "$proton")
    or return 1

    set -lx PROTONPATH $proton
    set -lx WINEPREFIX $_flag_prefix
    wineserver_kill
end

# --- Wuthering Waves ---------------------------------------------------------

function _wuwa_symlink_saved --description "Symlink WuWa Config, DeviceSaved, and LocalStorage"
    argparse 'saved-dir=' 'config-base=' -- $argv
    or return 1

    set -l saved_dir $_flag_saved_dir
    set -l config_base $_flag_config_base

    # The game recreates Saved/ from scratch after an update, so it may not
    # exist yet on the first launch afterwards.
    mkdir -p "$saved_dir"
    mkdir -p "$config_base/Config" "$config_base/DeviceSaved" "$config_base/LocalStorage"

    for name in Config DeviceSaved LocalStorage
        set -l target "$saved_dir/$name"
        set -l source "$config_base/$name"

        if test -L "$target"
            rm -f "$target"
        else if test -d "$target"
            if test -d "$target.bak"
                rm -rf "$target.bak"
            end
            mv "$target" "$target.bak"
        end

        # Launching with the link missing would write saves into the game
        # directory instead of the config base, so bail out loudly.
        if not ln -s "$source" "$target"
            echo "wuwa: failed to link $target -> $source" >&2
            return 1
        end
    end
end

function _wuwa_restore_saved --description "Restore WuWa Config, DeviceSaved, and LocalStorage"
    argparse 'saved-dir=' -- $argv
    or return 1

    set -l saved_dir $_flag_saved_dir

    for name in Config DeviceSaved LocalStorage
        set -l target "$saved_dir/$name"
        if test -L "$target"
            rm -f "$target"
        end
        if test -d "$target.bak"
            mv "$target.bak" "$target"
        end
    end
end

# Redirect the shared save directories exclusively until the command exits.
function _wuwa_with_saved --description "Hold the shared WuWa save-directory lock while running a command"
    argparse 'saved-dir=' 'config-base=' -- $argv
    or return 1

    set -l saved_dir $_flag_saved_dir
    set -l lock_dir (path dirname "$saved_dir")
    mkdir -p "$lock_dir"
    or return 1

    # Keep the lock file in Client: Saved can be recreated by game updates.
    # The open descriptor holds the lock through both launch and restoration.
    begin
        if not flock --nonblock 9
            echo "wuwa: shared save directory is in use: $saved_dir" >&2
            return 1
        end

        _wuwa_symlink_saved --saved-dir "$saved_dir" --config-base "$_flag_config_base"
        or return 1

        $argv
        set -l game_status $status
        _wuwa_restore_saved --saved-dir "$saved_dir"
        return $game_status
    end 9>"$lock_dir/.wuwa-saved.lock"
end

function _wuwa_run --description "Launch Wuthering Waves with a swapped save directory"
    argparse --ignore-unknown 'config-base=' 'disable-csharp' 'session-id=' -- $argv
    or return 1

    # Named here rather than left in $argv: argparse only keeps an unknown
    # option and its value adjacent by luck, and _game_run would then read the
    # wrong token as the ID.
    set -l session_args
    set -q _flag_session_id; and set session_args --session-id "$_flag_session_id"

    set -l saved_dir "$HOME/Games/.bin/wuwa/Client/Saved"

    # Left alone, the C# (Sharphereal) environment is picked server-side by a
    # gray rollout keyed on the device id. Force it on; --disable-csharp passes
    # no switch at all and hands the choice back to the server.
    set -l csharp_args -ForceEnableCSharpEnvironment
    set -q _flag_disable_csharp; and set csharp_args

    _wuwa_with_saved --saved-dir "$saved_dir" --config-base "$_flag_config_base" -- \
        _game_run \
        --name wuwa \
        --exe "$HOME/Games/.bin/wuwa/Wuthering Waves.exe" \
        --cwd "$HOME/Games/.bin/wuwa" \
        --env SteamOS=1 \
        $session_args \
        $argv \
        -krqlv=uhd \
        $csharp_args
end

function wuwa --description "Launch Wuthering Waves via umu-run"
    argparse --ignore-unknown \
        'enable-dx11' \
        -- $argv
    or return 1

    # dx11 is off by default here
    set -l dx11_args
    set -q _flag_enable_dx11; and set dx11_args -dx11

    _wuwa_run --config-base "$HOME/Games/.config/wuwa" \
        --prefix "$HOME/Games/wuwa" \
        $argv \
        $dx11_args
end

function wuwa_bs --description "Launch the WuWa BS launcher in the Wuthering Waves prefix"
    set -l launcher_dir "$HOME/Games/.bin/wuwa_bs/China"
    set -l saved_dir "$HOME/Games/.bin/wuwa/Client/Saved"

    _wuwa_with_saved --saved-dir "$saved_dir" --config-base "$HOME/Games/.config/wuwa" -- \
        _game_run \
        --name wuwa_bs \
        --exe "$launcher_dir/3.6.1.exe" \
        --prefix "$HOME/Games/wuwa" \
        --cwd "$launcher_dir" \
        --env SteamOS=1 \
        --machine-id-file "$launcher_dir/.wine-machine-id" \
        $argv
end

function wuwa_daily --description "Launch Wuthering Waves daily inside a labwc session"
    argparse --ignore-unknown \
        'enable-dx11' \
        'session-id=' \
        -- $argv
    or return 1

    # dx11 is off by default here
    set -l dx11_args
    set -q _flag_enable_dx11; and set dx11_args -dx11

    # Registering is opt-in: without an ID the session is anonymous, exactly as
    # before. Pass one to make it reachable through `game_session <id>`.
    set -l session_args
    set -q _flag_session_id; and set session_args --session-id "$_flag_session_id"

    _wuwa_run --config-base "$HOME/Games/.config/wuwa_daily" \
        --prefix "$HOME/Games/wuwa_daily" \
        --labwc \
        --disable-wayland \
        $session_args \
        $argv \
        $dx11_args
end

# Test whether the official Wuthering Waves launcher runs under Proton. It lives in its own
# prefix so a broken install cannot touch the real wuwa prefix or its saves.
# Run the downloaded installer once with --install, then launch without it.
#
# Out of the box the launcher window never opens under Wine. The workaround
# (github.com/timetetng/wutheringwaves-cli-manager docs/wuwa-launcher.md) is to
# report Windows 7 to WebView2 and binary-patch launcher_main.dll. Both are
# checked before every launch because a launcher update ships a fresh DLL.
# The launcher keeps each release in a version directory; use the newest.
function _wuwa_launcher_dll --description "Print the newest launcher_main.dll path"
    set -l version_dir (path filter -d $argv[1]/*.*.*.* | sort -V | tail -n1)
    if test -z "$version_dir"
        echo "wuwa_launcher: no version directory in: $argv[1]" >&2
        return 1
    end
    echo "$version_dir/launcher_main.dll"
end

function _wuwa_launcher_restore --description "Restore launcher_main.dll from its .bak"
    set -l dll (_wuwa_launcher_dll $argv[1])
    or return 1
    if not test -f $dll.bak
        echo "wuwa_launcher: no backup to restore at: $dll.bak" >&2
        return 1
    end
    mv -f $dll.bak $dll
    or return 1
    echo "wuwa_launcher: restored $dll"
end

function _wuwa_launcher_fix --description "Apply the WebView2 and launcher_main.dll workarounds"
    argparse 'prefix=' 'launcher-dir=' 'proton=' -- $argv
    or return 1

    set -l prefix $_flag_prefix

    set -l key 'Software\\\\Wine\\\\AppDefaults\\\\msedgewebview2.exe'
    if not grep -qF "[$key]" "$prefix/user.reg" 2>/dev/null
        set -l proton (_game_resolve_proton "$_flag_proton")
        or return 1
        env WINEPREFIX=$prefix PROTONPATH=$proton \
            umu-run reg add 'HKCU\Software\Wine\AppDefaults\msedgewebview2.exe' \
            /v Version /d win7 /f
        or begin
            echo "wuwa_launcher: failed to set the WebView2 Windows version" >&2
            return 1
        end
    end

    set -l dll (_wuwa_launcher_dll $_flag_launcher_dir)
    or return 1
    if not grep -qa (printf '\x12AllowsTransparency') $dll
        return 0
    end

    # Same-length replacement, so perl does what the guide uses bbe for. The
    # pattern only matches an unpatched DLL, so the .bak is always pristine.
    cp -f $dll $dll.bak
    or return 1
    if not perl -0777 -pe 's/\x12AllowsTransparency/\x09IsEnabled\x1bA\x00\x03AAAAA/g' $dll.bak >$dll
        cp -f $dll.bak $dll
        echo "wuwa_launcher: failed to patch $dll" >&2
        return 1
    end
    echo "wuwa_launcher: patched $dll"
end

# With no action flag this launches the launcher, applying the fix first.
# --install, --patch, --restore and --kill each do only their own job and are
# exclusive. --restore undoes the DLL patch; the next launch reapplies it.
function wuwa_launcher --description "Install, patch, restore, launch, or kill the official Wuthering Waves launcher"
    argparse --ignore-unknown --exclusive install,patch,restore,kill \
        'install=' 'patch' 'restore' 'kill' 'launcher-dir=' 'proton=' -- $argv
    or return 1

    set -l prefix "$HOME/Games/wuwa_launcher"
    set -l launcher_dir "$prefix/drive_c/Program Files/Wuthering Waves"
    test -n "$_flag_launcher_dir"; and set launcher_dir $_flag_launcher_dir

    set -l proton $DEFAULT_GAME_PROTON
    test -n "$_flag_proton"; and set proton $_flag_proton

    if set -q _flag_kill
        _game_kill --prefix "$prefix" --proton "$proton"
        return
    end

    if set -q _flag_restore
        _wuwa_launcher_restore "$launcher_dir"
        return
    end

    if set -q _flag_patch
        _wuwa_launcher_fix --prefix "$prefix" --launcher-dir "$launcher_dir" --proton "$proton"
        return
    end

    set -l exe "$launcher_dir/launcher.exe"
    set -l cwd_args --cwd "$launcher_dir"
    set -l install_run_args
    if test -n "$_flag_install"
        set exe (path resolve -- $_flag_install)
        set cwd_args
        # Installers need no GameMode and can use the host's 64-bit libraries.
        set install_run_args --disable-gamemode --env PROTON_USE_WOW64=1
    else
        _wuwa_launcher_fix --prefix "$prefix" --launcher-dir "$launcher_dir" --proton "$proton"
        or return 1
    end

    # The launcher UI is a WebView2 page. Under Proton's Wayland driver it
    # loads and runs (its log shows the page and background video playing) but
    # the window stays black, so always use X11.
    _game_run \
        --name wuwa_launcher \
        --exe "$exe" \
        --prefix "$prefix" \
        --proton "$proton" \
        --disable-wayland \
        $cwd_args \
        $install_run_args \
        $argv
end

function wuwa_kill --description "Stop Wuthering Waves by killing its wineserver"
    _game_kill --prefix "$HOME/Games/wuwa" $argv
end

function wuwa_daily_kill --description "Stop Wuthering Waves daily by killing its wineserver"
    _game_kill --prefix "$HOME/Games/wuwa_daily" $argv
end

# --- Arknights: Endfield -----------------------------------------------------

function endfield --description "Launch Arknights Endfield via umu-run, retrying the anti-cheat startup race"
    argparse --ignore-unknown 'retry-times=' -- $argv
    or return 1

    set -l game_dir "$HOME/Games/arknights-endfield/drive_c/Program Files/Hypergryph Launcher/games/Arknights Endfield"

    # ACE's kernel driver resolves ntoskrnl routines Proton only stubs, and a
    # stub raises instead of returning. When that exception escapes ACE's own
    # handler it kills winedevice.exe and the game dies within seconds, before
    # a window ever appears. Which call turns fatal differs per launch, so a
    # fresh attempt usually gets through -- retry by default here.
    set -l retry_times 5
    test -n "$_flag_retry_times"; and set retry_times $_flag_retry_times

    _game_run \
        --name endfield \
        --exe "$game_dir/Endfield.exe" \
        --prefix "$HOME/Games/arknights-endfield" \
        --gameid umu-arknights-endfield \
        --cwd "$game_dir" \
        --retry-times $retry_times \
        $argv
end

function arknights --description "Launch Arknights via umu-run"
    set -l game_dir "$HOME/Games/arknights-endfield/drive_c/Program Files/Hypergryph Launcher/games/Arknights"
    _game_run \
        --name arknights \
        --exe "$game_dir/Arknights.exe" \
        --prefix "$HOME/Games/arknights-endfield" \
        --gameid umu-arknights \
        --cwd "$game_dir" \
        $argv
end

function arknights_kill --description "Stop Arknights by killing its wineserver"
    _game_kill --prefix "$HOME/Games/arknights-endfield" $argv
end

function endfield_daily --description "Launch Arknights Endfield daily build inside a labwc session"
    argparse --ignore-unknown 'session-id=' -- $argv
    or return 1

    set -l session_args
    set -q _flag_session_id; and set session_args --session-id "$_flag_session_id"

    _game_run \
        --name endfield_daily \
        --exe "$HOME/Games/.bin/Arknights Endfield/Endfield.exe" \
        --prefix "$HOME/Games/arknights_endfield_daily" \
        --cwd "$HOME/Games/.bin/Arknights Endfield" \
        --labwc \
        --disable-wayland \
        $session_args \
        $argv
end

function endfield_kill --description "Stop Arknights Endfield by killing its wineserver"
    _game_kill --prefix "$HOME/Games/arknights-endfield" $argv
end

function endfield_daily_kill --description "Stop Arknights Endfield daily build by killing its wineserver"
    _game_kill --prefix "$HOME/Games/arknights_endfield_daily" $argv
end

# The installer is an NSIS archive, so its payload is extracted directly
# instead of running it under Wine.
function _hypergryph_launcher_install --description "Extract a Hypergryph installer exe into a WINEPREFIX"
    argparse 'installer=' 'prefix=' -- $argv
    or return 1

    set -l installer $_flag_installer

    if not test -f $installer
        echo "hypergryph_launcher: installer not found at: $installer" >&2
        return 1
    end

    set -l prefix $_flag_prefix
    set -l install_dir "$prefix/drive_c/Program Files/Hypergryph Launcher"

    if not command -q 7z
        echo "hypergryph_launcher: 7z is required to extract the NSIS payload" >&2
        return 1
    end

    set -l tmpdir (mktemp -d)
    if test -z "$tmpdir"
        echo "hypergryph_launcher: failed to create temporary directory" >&2
        return 1
    end

    7z x -y -bso0 -bsp0 "$installer" "-o$tmpdir" '$0/*'
    set -l extract_status $status
    if test $extract_status -ne 0
        rm -rf "$tmpdir"
        return $extract_status
    end

    set -l payload_dir "$tmpdir/\$0"
    if not test -d "$payload_dir"
        rm -rf "$tmpdir"
        echo "hypergryph_launcher: installer payload not found in archive" >&2
        return 1
    end

    set -l version_dir
    for candidate in "$payload_dir"/*
        if test -f "$candidate/Launcher.exe"; and test -f "$candidate/Games.exe"
            set version_dir $candidate
            break
        end
    end

    if test -z "$version_dir"
        rm -rf "$tmpdir"
        echo "hypergryph_launcher: Launcher.exe and Games.exe not found in installer payload" >&2
        return 1
    end

    rm -rf "$install_dir"
    mkdir -p "$install_dir"
    cp -a "$payload_dir/." "$install_dir/"
    cp -f "$version_dir/Launcher.exe" "$install_dir/Launcher.exe"
    rm -rf "$tmpdir"

    echo "hypergryph_launcher: installed Hypergryph Launcher "(basename "$version_dir")" to: $install_dir"
end

# With no action flag this launches the launcher. --install and --kill each do
# only their own job and are exclusive.
function hypergryph_launcher --description "Install, launch, or kill the Hypergryph launcher"
    argparse --ignore-unknown --exclusive install,kill 'install=' 'kill' -- $argv
    or return 1

    set -l prefix "$HOME/Games/arknights-endfield"

    if set -q _flag_kill
        _game_kill --prefix "$prefix" $argv
        return
    end

    if test -n "$_flag_install"
        _hypergryph_launcher_install --installer "$_flag_install" --prefix "$prefix"
        return
    end

    _game_run \
        --name hypergryph_launcher \
        --exe "$prefix/drive_c/Program Files/Hypergryph Launcher/Launcher.exe" \
        --prefix "$prefix" \
        --gameid umu-arknights-endfield \
        $argv
end

# --- Reverse: 1999 ----------------------------------------------------------

# NSIS requires its /D destination override to be the final argument.
function re1999 --description "Install, launch, or kill Reverse: 1999 via umu-run"
    argparse --ignore-unknown --exclusive install,kill 'install=' 'kill' 'proton=' -- $argv
    or return 1

    set -l prefix "$HOME/Games/re1999"
    set -l proton $DEFAULT_GAME_PROTON
    test -n "$_flag_proton"; and set proton $_flag_proton

    if set -q _flag_kill
        _game_kill --prefix "$prefix" --proton "$proton" $argv
        return
    end

    set -l launcher_dir "$prefix/drive_c/Reverse1999/reverse1999_global"
    set -l exe "$launcher_dir/reverse1999-launcher.exe"
    set -l cwd_args --cwd "$launcher_dir"
    set -l install_args
    set -l install_run_args
    if set -q _flag_install
        set exe (path resolve -- "$_flag_install")
        set cwd_args
        set install_run_args --disable-gamemode --env PROTON_USE_WOW64=1
        set install_args '/D=C:\Reverse1999'
    end

    _game_run \
        --name re1999 \
        --exe "$exe" \
        --prefix "$prefix" \
        --proton "$proton" \
        --disable-wayland \
        $cwd_args \
        $install_run_args \
        $argv \
        $install_args
end

# --- Naraka: Bladepoint ------------------------------------------------------

function naraka --description "Launch Naraka: Bladepoint via umu-run"
    _game_run \
        --name naraka \
        --exe "$HOME/Games/.bin/Naraka/LauncherGame.exe" \
        --prefix "$HOME/Games/naraka" \
        --cwd "$HOME/Games/.bin/Naraka" \
        $argv
end

function naraka_kill --description "Stop Naraka: Bladepoint by killing its wineserver"
    _game_kill --prefix "$HOME/Games/naraka" $argv
end

# --- Alice In Cradle ---------------------------------------------------------

function alice_in_cradle --description "Launch Alice In Cradle via umu-run"
    _game_run \
        --name alice_in_cradle \
        --exe "$HOME/Games/.bin/AliceInCradle/AliceInCradle.exe" \
        --prefix "$HOME/Games/alice_in_cradle" \
        --cwd "$HOME/Games/.bin/AliceInCradle" \
        --disable-gamemode \
        $argv
end

function alice_in_cradle_kill --description "Stop Alice In Cradle by killing its wineserver"
    _game_kill --prefix "$HOME/Games/alice_in_cradle" $argv
end

function aic --description "Alias of alice_in_cradle"
    alice_in_cradle $argv
end

function aic_kill --description "Alias of alice_in_cradle_kill"
    alice_in_cradle_kill $argv
end

# --- Symphonic Rain ----------------------------------------------------------

function symphonic_rain --description "Set up, launch, or stop Symphonic Rain"
    argparse --ignore-unknown --exclusive setup,kill 'setup=?' 'kill' 'proton=' -- $argv
    or return 1

    set -l game_dir "$HOME/Games/.bin/Symphonic Rain"
    set -l prefix "$HOME/Games/symphonic_rain"
    set -l game_dir_file "$prefix/game-dir"
    if test -f "$game_dir_file"
        read game_dir < "$game_dir_file"
    end
    set -l proton $DEFAULT_GAME_PROTON
    test -n "$_flag_proton"; and set proton $_flag_proton
    set proton (_game_resolve_proton "$proton")
    or return 1

    if set -q _flag_kill
        _game_kill --prefix "$prefix" --proton "$proton"
        return
    end

    if set -q _flag_setup
        set game_dir "$HOME/Games/.bin/Symphonic Rain"
        if test -n "$_flag_setup"
            set game_dir $_flag_setup
        else if test (count $argv) -gt 0
            set game_dir $argv[1]
        end
        set game_dir (path resolve -- "$game_dir")
        for file in SR_qc.exe SR_qc.MOO sr_loc.dll Essai.ttf
            if not test -f "$game_dir/$file"
                echo "symphonic_rain: required game file not found: $game_dir/$file" >&2
                return 1
            end
        end

        mkdir -p "$prefix/drive_c/windows/Fonts"
        or return 1
        cp "$game_dir/Essai.ttf" "$prefix/drive_c/windows/Fonts/Essai.ttf"
        or return 1

        # Derive the locale key from Wine's directory rather than assuming a
        # drive letter. The translated executable loads its MOO through it.
        set -l setup_file "$prefix/drive_c/symphonic-rain-setup.cmd"
        printf '%s\r\n' '@echo off' \
            'reg add "HKEY_CURRENT_USER\Software\Borland\Locales" /v "%cd%\SR_qc.exe" /d MOO /f' > "$setup_file"
        or return 1
        env --chdir="$game_dir" WINEPREFIX="$prefix" PROTONPATH="$proton" PROTON_USE_WOW64=1 \
            umu-run cmd.exe /c 'C:\symphonic-rain-setup.cmd'
        set -l setup_status $status
        rm -f "$setup_file"
        test $setup_status -eq 0; or return $setup_status
        printf '%s\n' "$game_dir" > "$game_dir_file"
        return $status
    end

    _game_run \
        --name symphonic_rain \
        --exe "$game_dir/SR_qc.exe" \
        --prefix "$prefix" \
        --proton "$proton" \
        --cwd "$game_dir" \
        --disable-wayland \
        --disable-gamemode \
        --env PROTON_USE_WOW64=1 \
        $argv
end

function symphonic_rain_kill --description "Stop Symphonic Rain by killing its wineserver"
    symphonic_rain --kill $argv
end
