# Games launch commands (Linux only)

set -g DW_PROTON_PATH "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/DW-Proton Latest"

function _wuwa_symlink_saved --description "Symlink WuWa Config, DeviceSaved, and LocalStorage"
    set -l saved_dir $argv[1]
    set -l config_base $argv[2]

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

        ln -s "$source" "$target"
    end
end

function _wuwa_restore_saved --description "Restore WuWa Config, DeviceSaved, and LocalStorage"
    set -l saved_dir $argv[1]

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

function wuwa --description "Launch Wuthering Waves via umu-run"
    cd "$HOME/Games/.bin/wuwa"
    set -l proton_path $DW_PROTON_PATH
    set -l game_exe "$HOME/Games/.bin/wuwa/Wuthering Waves.exe"
    set -l enable_mangohud 0
    set -l enable_gamemode 1
    set -l enable_wayland 1
    set -l enable_dx11 1
    set -l game_args

    for arg in $argv
        switch $arg
            case --enable-mangohud
                set enable_mangohud 1
            case --disable-gamemode
                set enable_gamemode 0
            case --disable-wayland
                set enable_wayland 0
            case --enable-dx11
                set enable_dx11 1
            case '*'
                set -a game_args $arg
        end
    end

    if not test -d $proton_path
        echo "wuwa: Proton not found at: $proton_path" >&2
        return 1
    end

    if not test -f "$game_exe"
        echo "wuwa: Game executable not found at: $game_exe" >&2
        return 1
    end

    set -l game_dir "$HOME/Games/.bin/wuwa"
    set -l saved_dir "$game_dir/Client/Saved"
    set -l config_base "$HOME/Games/.config/wuwa"

    _wuwa_symlink_saved "$saved_dir" "$config_base"

    if test $enable_dx11 -eq 1
        set -a game_args -dx11
    end

    set -l command umu-run "$game_exe" $game_args
    if test $enable_mangohud -eq 1
        set command mangohud $command
    end
    if test $enable_gamemode -eq 1
        set command gamemoderun $command
    end

    mkdir -p "$HOME/Games/wuwa"
    set -l wayland_env PROTON_ENABLE_WAYLAND=0
    if test $enable_wayland -eq 1
        set wayland_env PROTON_ENABLE_WAYLAND=1
    end

    systemd-inhibit --what=idle --who="wuwa" --why="Game is running" \
        env WINEPREFIX="$HOME/Games/wuwa" \
        PROTONPATH=$proton_path \
        $wayland_env \
        $command
    _wuwa_restore_saved "$saved_dir"
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

function wuwa_kill --description "Stop Wuthering Waves by killing its wineserver"
    set -lx PROTONPATH $DW_PROTON_PATH
    set -lx WINEPREFIX "$HOME/Games/wuwa"
    wineserver_kill
end

function hypergryph_launcher --description "Launch Arknights Endfield (Hypergryph) via umu-run"
    set -l proton_path $DW_PROTON_PATH
    set -l game_exe "$HOME/Games/arknights-endfield/drive_c/Program Files/Hypergryph Launcher/Launcher.exe"
    set -l enable_mangohud 0
    set -l enable_gamemode 1
    set -l wayland_env PROTON_ENABLE_WAYLAND=0
    set -l game_args

    for arg in $argv
        switch $arg
            case --enable-mangohud
                set enable_mangohud 1
            case --disable-gamemode
                set enable_gamemode 0
            case --enable-wayland
                set wayland_env PROTON_ENABLE_WAYLAND=1
            case --disable-wayland
                set wayland_env PROTON_ENABLE_WAYLAND=0
            case '*'
                set -a game_args $arg
        end
    end

    if not test -d $proton_path
        echo "endfield: Proton not found at: $proton_path" >&2
        return 1
    end

    if not test -f $game_exe
        echo "endfield: Game executable not found at: $game_exe" >&2
        return 1
    end

    set -l command umu-run $game_exe $game_args
    if test $enable_mangohud -eq 1
        set command mangohud $command
    end
    if test $enable_gamemode -eq 1
        set command gamemoderun $command
    end

    mkdir -p "$HOME/Games/arknights-endfield"
    systemd-inhibit --what=idle --who="hypergryph_launcher" --why="Game is running" \
        env WINEPREFIX="$HOME/Games/arknights-endfield" \
        GAMEID=umu-arknights-endfield \
        PROTONPATH=$proton_path \
        $wayland_env \
        $command
end

function hypergryph_launcher_kill --description "Stop Arknights Endfield by killing its wineserver"
    set -lx PROTONPATH $DW_PROTON_PATH
    set -lx WINEPREFIX "$HOME/Games/arknights-endfield"
    wineserver_kill
end


function hypergryph_launcher_install --description "Run a Hypergryph installer exe into the arknights-endfield WINEPREFIX"
    if test (count $argv) -lt 1
        echo "hypergryph_launcher_install: usage: hypergryph_launcher_install <installer.exe>" >&2
        return 1
    end

    set -l installer $argv[1]

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

    set -l version_dirs "$payload_dir"/*
    set -l version_dir
    for candidate in $version_dirs
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

    set -l installed_version (basename "$version_dir")
    echo "hypergryph_launcher_install: installed Hypergryph Launcher $installed_version to: $install_dir"
end

function _labwc_daily_game_command --description "Build a shell-safe daily game command"
    set -l prefix $argv[1]
    set -l game_exe $argv[2]
    set -l game_args $argv[3..-1]

    string join -- ' ' (string escape -- \
        env \
        WINEPREFIX="$prefix" \
        PROTONPATH="$DW_PROTON_PATH" \
        PROTON_ENABLE_WAYLAND=0 \
        SDL_GAMECONTROLLER_IGNORE_DEVICES=0x045e/0x028e \
        umu-run "$game_exe" $game_args)
end

function _labwc_daily_session --description "Run a daily game in a labwc session"
    set -l headless $argv[1]
    set -l enable_wayvnc $argv[2]
    set -l game_command $argv[3]
    set -l session_argv "$HOME/.config/fish/risun/linux/labwc-daily-session.sh"
    set -l backend wayland

    if test $headless -eq 1
        set backend headless
        if test $enable_wayvnc -eq 0
            set -a session_argv --disable-wayvnc
        end
    else
        set -a session_argv --auto-output --disable-wayvnc
    end

    set -l session_command (string join -- ' ' (string escape -- $session_argv) $game_command)
    env WLR_BACKENDS=$backend labwc --session "$session_command"
end

function labwc_endfield_daily --description "Launch Arknights Endfield daily build via labwc"
    set -l headless 0
    set -l enable_wayvnc 1

    for arg in $argv
        switch $arg
            case --headless
                set headless 1
            case --enable-wayvnc
                set enable_wayvnc 1
            case --disable-wayvnc
                set enable_wayvnc 0
            case '*'
                echo "labwc_endfield_daily: unknown argument: $arg" >&2
                return 1
        end
    end

    cd "$HOME/Games/.bin/Arknights Endfield"
    set -l game_command (_labwc_daily_game_command \
        "$HOME/Games/arknights_endfield_daily" \
        "$HOME/Games/.bin/Arknights Endfield/Endfield.exe")
    _labwc_daily_session $headless $enable_wayvnc "$game_command"
end

function endfield_daily_kill --description "Stop Arknights Endfield daily build by killing its wineserver"
    set -lx PROTONPATH $DW_PROTON_PATH
    set -lx WINEPREFIX "$HOME/Games/arknights_endfield_daily"
    wineserver_kill
end

function naraka --description "Launch Naraka: Bladepoint via umu-run"
    cd "$HOME/Games/.bin/Naraka"
    set -l proton_path $DW_PROTON_PATH
    set -l game_exe "$HOME/Games/.bin/Naraka/LauncherGame.exe"
    set -l enable_mangohud 0
    set -l enable_gamemode 1
    set -l enable_wayland 1
    set -l game_args

    for arg in $argv
        switch $arg
            case --enable-mangohud
                set enable_mangohud 1
            case --disable-gamemode
                set enable_gamemode 0
            case --disable-wayland
                set enable_wayland 0
            case '*'
                set -a game_args $arg
        end
    end

    if not test -d $proton_path
        echo "naraka: Proton not found at: $proton_path" >&2
        return 1
    end

    if not test -f $game_exe
        echo "naraka: Game executable not found at: $game_exe" >&2
        return 1
    end

    set -l command umu-run $game_exe $game_args
    if test $enable_mangohud -eq 1
        set command mangohud $command
    end
    if test $enable_gamemode -eq 1
        set command gamemoderun $command
    end

    mkdir -p "$HOME/Games/naraka"
    set -l wayland_env PROTON_ENABLE_WAYLAND=0
    if test $enable_wayland -eq 1
        set wayland_env PROTON_ENABLE_WAYLAND=1
    end
    systemd-inhibit --what=idle --who="naraka" --why="Game is running" \
        env WINEPREFIX="$HOME/Games/naraka" \
        PROTONPATH=$proton_path \
        $wayland_env \
        $command
end

function naraka_kill --description "Stop Naraka: Bladepoint by killing its wineserver"
    set -lx PROTONPATH $DW_PROTON_PATH
    set -lx WINEPREFIX "$HOME/Games/naraka"
    wineserver_kill
end

function labwc_wuwa_daily --description "Launch Wuthering Waves daily via labwc"
    set -l headless 0
    set -l enable_dx11 0
    set -l enable_wayvnc 1

    for arg in $argv
        switch $arg
            case --headless
                set headless 1
            case --enable-dx11
                set enable_dx11 1
            case --enable-wayvnc
                set enable_wayvnc 1
            case --disable-wayvnc
                set enable_wayvnc 0
            case '*'
                echo "labwc_wuwa_daily: unknown argument: $arg" >&2
                return 1
        end
    end

    cd "$HOME/Games/.bin/wuwa"
    set -l game_dir "$HOME/Games/.bin/wuwa"
    set -l saved_dir "$game_dir/Client/Saved"
    set -l config_base "$HOME/Games/.config/wuwa_daily"

    _wuwa_symlink_saved "$saved_dir" "$config_base"

    set -l game_args
    if test $enable_dx11 -eq 1
        set -a game_args -dx11
    end
    set -l game_command (_labwc_daily_game_command \
        "$HOME/Games/wuwa_daily" \
        "$HOME/Games/.bin/wuwa/Wuthering Waves.exe" \
        $game_args)
    _labwc_daily_session $headless $enable_wayvnc "$game_command"
    _wuwa_restore_saved "$saved_dir"
end

function wuwa_daily_kill --description "Stop Wuthering Waves daily by killing its wineserver"
    set -lx PROTONPATH $DW_PROTON_PATH
    set -lx WINEPREFIX "$HOME/Games/wuwa_daily"
    wineserver_kill
end
