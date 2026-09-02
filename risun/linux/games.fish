# Games launch commands (Linux only)

set -g DW_PROTON_PATH "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/DW-Proton Latest"
set -g GE_PROTON_PATH "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/Proton-GE Latest"

set -g DEFAULT_GAME_PROTON $GE_PROTON_PATH


set -g _GAME_LABWC_SESSION "$HOME/.config/fish/risun/linux/labwc-daily-session.sh"

# Every launcher is a thin wrapper around _game_run. Each toggle has exactly one
# flag, the opposite of its default: wayland, mangohud and labwc are off unless
# enabled, gamemode and wayvnc are on unless disabled. Anything _game_run does
# not recognize is forwarded to the game executable.
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
        'enable-wayland' \
        'disable-gamemode' \
        'enable-mangohud' \
        'labwc' \
        'headless' \
        'disable-wayvnc' \
        -- $argv
    or return 1

    set -l game_args $argv

    set -l proton $DEFAULT_GAME_PROTON
    test -n "$_flag_proton"; and set proton $_flag_proton

    set -l name (basename $_flag_prefix)
    test -n "$_flag_name"; and set name $_flag_name

    set -l wayland 0
    set -q _flag_enable_wayland; and set wayland 1

    if not test -d $proton
        echo "$name: Proton not found at: $proton" >&2
        return 1
    end

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

    if not set -q _flag_labwc
        set -a env_vars PROTON_ENABLE_WAYLAND=$wayland
        systemd-inhibit \
            --what=idle \
            --who=$name \
            --why="Game is running" \
            $env_cmd \
            $env_vars \
            $command
        return $status
    end

    # labwc mode: the game runs inside a nested compositor, so Proton's own
    # Wayland backend stays off regardless of --enable-wayland.
    set -a env_vars PROTON_ENABLE_WAYLAND=0
    # Keep the pad on the host session instead of the nested game. An empty
    # allowlist ignores every controller, so this does not break when the pad
    # is switched to a mode that reports a different VID/PID -- and unlike
    # SDL_GAMECONTROLLER_IGNORE_DEVICES, Proton does not drop it when its own
    # Wayland backend is on.
    set -a env_vars SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT=0x0000/0x0000

    set -l session_argv $_GAME_LABWC_SESSION
    set -l backend wayland
    if set -q _flag_headless
        set backend headless
        set -q _flag_disable_wayvnc; and set -a session_argv --disable-wayvnc
    else
        set -a session_argv \
            --auto-output \
            --disable-wayvnc
    end

    set -l session_command (string join -- ' ' (string escape -- \
        $session_argv \
        $env_cmd \
        $env_vars \
        $command))

    env WLR_BACKENDS=$backend \
        labwc \
        --session "$session_command"
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

# Runs WuWa with its save directories redirected at --config-base, restoring
# them once the game exits. Remaining arguments are forwarded to _game_run.
function _wuwa_run --description "Launch Wuthering Waves with a swapped save directory"
    argparse --ignore-unknown 'config-base=' 'disable-csharp' -- $argv
    or return 1

    set -l saved_dir "$HOME/Games/.bin/wuwa/Client/Saved"

    _wuwa_symlink_saved --saved-dir "$saved_dir" --config-base "$_flag_config_base"
    or return 1

    # Left alone, the C# (Sharphereal) environment is picked server-side by a
    # gray rollout keyed on the device id. Force it on; --disable-csharp passes
    # no switch at all and hands the choice back to the server.
    set -l csharp_args -ForceEnableCSharpEnvironment
    set -q _flag_disable_csharp; and set csharp_args

    _game_run \
        --name wuwa \
        --exe "$HOME/Games/.bin/wuwa/Wuthering Waves.exe" \
        --cwd "$HOME/Games/.bin/wuwa" \
        --env SteamOS=1 \
        $argv \
        $csharp_args
    set -l game_status $status

    _wuwa_restore_saved --saved-dir "$saved_dir"
    return $game_status
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

    _wuwa_symlink_saved \
        --saved-dir "$saved_dir" \
        --config-base "$HOME/Games/.config/wuwa"
    or return 1

    _game_run \
        --name wuwa_bs \
        --exe "$launcher_dir/3.6.1.exe" \
        --prefix "$HOME/Games/wuwa" \
        --cwd "$launcher_dir" \
        --env SteamOS=1 \
        --machine-id-file "$launcher_dir/.wine-machine-id" \
        $argv
    set -l game_status $status

    _wuwa_restore_saved --saved-dir "$saved_dir"
    return $game_status
end

function wuwa_daily --description "Launch Wuthering Waves daily inside a labwc session"
    argparse --ignore-unknown \
        'enable-dx11' \
        -- $argv
    or return 1

    # dx11 is off by default here
    set -l dx11_args
    set -q _flag_enable_dx11; and set dx11_args -dx11

    _wuwa_run --config-base "$HOME/Games/.config/wuwa_daily" \
        --prefix "$HOME/Games/wuwa_daily" \
        --labwc \
        $argv \
        $dx11_args
end

function wuwa_kill --description "Stop Wuthering Waves by killing its wineserver"
    _game_kill --prefix "$HOME/Games/wuwa"
end

function wuwa_daily_kill --description "Stop Wuthering Waves daily by killing its wineserver"
    _game_kill --prefix "$HOME/Games/wuwa_daily"
end

# --- Arknights: Endfield -----------------------------------------------------

function endfield --description "Launch Arknights Endfield via umu-run, retrying the anti-cheat startup race"
    set -l game_dir "$HOME/Games/arknights-endfield/drive_c/Program Files/Hypergryph Launcher/games/Arknights Endfield"

    # ACE's kernel driver resolves ntoskrnl routines Proton only stubs, and a
    # stub raises instead of returning. When that exception escapes ACE's own
    # handler it kills winedevice.exe and the game dies within seconds, before
    # a window ever appears. Which call turns fatal differs per launch, so a
    # fresh attempt usually gets through. Only the fast failure is retried: a
    # crash minutes into a session should surface, not silently relaunch.
    set -l max_attempts 5
    set -l fail_seconds 60

    for attempt in (seq $max_attempts)
        set -l started (date +%s)
        _game_run \
            --name endfield \
            --exe "$game_dir/Endfield.exe" \
            --prefix "$HOME/Games/arknights-endfield" \
            --gameid umu-arknights-endfield \
            --cwd "$game_dir" \
            $argv
        set -l game_status $status
        set -l elapsed (math (date +%s) - $started)

        if test $game_status -eq 0
            return 0
        end

        # _game_run returns 1 for its own checks (missing Proton or exe), which
        # retrying only repeats.
        if test $game_status -eq 1; or test $elapsed -ge $fail_seconds
            return $game_status
        end

        echo "endfield: exited $game_status after $elapsed""s, attempt $attempt/$max_attempts" >&2
    end

    echo "endfield: failed to start after $max_attempts attempts" >&2
    return 1
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
    _game_kill --prefix "$HOME/Games/arknights-endfield"
end

function hypergryph_launcher --description "Launch Arknights Endfield (Hypergryph) via umu-run"
    _game_run \
        --name hypergryph_launcher \
        --exe "$HOME/Games/arknights-endfield/drive_c/Program Files/Hypergryph Launcher/Launcher.exe" \
        --prefix "$HOME/Games/arknights-endfield" \
        --gameid umu-arknights-endfield \
        $argv
end

function endfield_daily --description "Launch Arknights Endfield daily build inside a labwc session"
    _game_run \
        --name endfield_daily \
        --exe "$HOME/Games/.bin/Arknights Endfield/Endfield.exe" \
        --prefix "$HOME/Games/arknights_endfield_daily" \
        --cwd "$HOME/Games/.bin/Arknights Endfield" \
        --labwc \
        $argv
end

function endfield_kill --description "Stop Arknights Endfield by killing its wineserver"
    _game_kill --prefix "$HOME/Games/arknights-endfield"
end

function hypergryph_launcher_kill --description "Stop Arknights Endfield by killing its wineserver"
    endfield_kill
end

function endfield_daily_kill --description "Stop Arknights Endfield daily build by killing its wineserver"
    _game_kill --prefix "$HOME/Games/arknights_endfield_daily"
end

function hypergryph_launcher_install --description "Run a Hypergryph installer exe into the arknights-endfield WINEPREFIX"
    argparse 'installer=' -- $argv
    or return 1

    if test -z "$_flag_installer"
        echo "hypergryph_launcher_install: usage: hypergryph_launcher_install --installer <installer.exe>" >&2
        return 1
    end

    set -l installer $_flag_installer

    if not test -f $installer
        echo "hypergryph_launcher_install: installer not found at: $installer" >&2
        return 1
    end

    set -l prefix "$HOME/Games/arknights-endfield"
    set -l install_dir "$prefix/drive_c/Program Files/Hypergryph Launcher"

    if not command -q 7z
        echo "hypergryph_launcher_install: 7z is required to extract the NSIS payload" >&2
        return 1
    end

    set -l tmpdir (mktemp -d)
    if test -z "$tmpdir"
        echo "hypergryph_launcher_install: failed to create temporary directory" >&2
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
        echo "hypergryph_launcher_install: installer payload not found in archive" >&2
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
        echo "hypergryph_launcher_install: Launcher.exe and Games.exe not found in installer payload" >&2
        return 1
    end

    rm -rf "$install_dir"
    mkdir -p "$install_dir"
    cp -a "$payload_dir/." "$install_dir/"
    cp -f "$version_dir/Launcher.exe" "$install_dir/Launcher.exe"
    rm -rf "$tmpdir"

    echo "hypergryph_launcher_install: installed Hypergryph Launcher "(basename "$version_dir")" to: $install_dir"
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
    _game_kill --prefix "$HOME/Games/naraka"
end

# --- Alice In Cradle ---------------------------------------------------------

function alice_in_cradle --description "Launch Alice In Cradle via umu-run"
    _game_run \
        --name alice_in_cradle \
        --exe "$HOME/Games/.bin/AliceInCradle/AliceInCradle.exe" \
        --prefix "$HOME/Games/alice_in_cradle" \
        --cwd "$HOME/Games/.bin/AliceInCradle" \
        $argv
end

function alice_in_cradle_kill --description "Stop Alice In Cradle by killing its wineserver"
    _game_kill --prefix "$HOME/Games/alice_in_cradle"
end

function aic --description "Alias of alice_in_cradle"
    alice_in_cradle $argv
end

function aic_kill --description "Alias of alice_in_cradle_kill"
    alice_in_cradle_kill $argv
end
