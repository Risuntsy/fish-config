# Games launch commands (Linux only)

set -g DW_PROTON_PATH "/home/risun/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/DW-Proton Latest"

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
    set -l game_args

    for arg in $argv
        switch $arg
            case --enable-mangohud
                set enable_mangohud 1
            case --disable-gamemode
                set enable_gamemode 0
            case '*'
                set -a game_args $arg
        end
    end

    if not test -d $proton_path
        echo "wuwa: Proton not found at: $proton_path" >&2
        return 1
    end

    if not test -f $game_exe
        echo "wuwa: Game executable not found at: $game_exe" >&2
        return 1
    end

    set -l game_dir "$HOME/Games/.bin/wuwa"
    set -l saved_dir "$game_dir/Client/Saved"
    set -l config_base "$HOME/Games/.config/wuwa"

    _wuwa_symlink_saved "$saved_dir" "$config_base"

    set -l command umu-run $game_exe $game_args
    if test $enable_mangohud -eq 1
        set command mangohud $command
    end
    if test $enable_gamemode -eq 1
        set command gamemoderun $command
    end

    mkdir -p "$HOME/Games/wuwa"
    systemd-inhibit --what=idle --who="wuwa" --why="Game is running" \
        env WINEPREFIX="$HOME/Games/wuwa" \
            PROTONPATH=$proton_path \
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
    set -l game_args

    for arg in $argv
        switch $arg
            case --enable-mangohud
                set enable_mangohud 1
            case --disable-gamemode
                set enable_gamemode 0
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
            PROTONPATH=$proton_path \
            $command
end

function hypergryph_launcher_kill --description "Stop Arknights Endfield by killing its wineserver"
    set -lx PROTONPATH $DW_PROTON_PATH
    set -lx WINEPREFIX "$HOME/Games/arknights-endfield"
    wineserver_kill
end

function hypergryph_launcher_install --description "Run a Hypergryph installer exe into the arknights-endfield WINEPREFIX"
    if test (count $argv) -lt 1
        echo "hypergryph_install: usage: hypergryph_install <installer.exe>" >&2
        return 1
    end

    set -l installer $argv[1]

    if not test -f $installer
        echo "hypergryph_install: installer not found at: $installer" >&2
        return 1
    end

    set -l proton_path $DW_PROTON_PATH

    if not test -d $proton_path
        echo "hypergryph_install: Proton not found at: $proton_path" >&2
        return 1
    end

    mkdir -p "$HOME/Games/arknights-endfield"
    env WINEPREFIX="$HOME/Games/arknights-endfield" \
        PROTONPATH=$proton_path \
        umu-run $installer
end

function labwc_endfield_daily --description "Launch Arknights Endfield daily build via labwc"
    cd "$HOME/Games/.bin/Arknights Endfield"
    WLR_BACKENDS=headless labwc -S "env WINEPREFIX=\"$HOME/Games/arknights_endfield_daily\" PROTONPATH=\"$DW_PROTON_PATH\" SDL_GAMECONTROLLER_IGNORE_DEVICES=0x045e/0x028e umu-run \"$HOME/Games/.bin/Arknights Endfield/Endfield.exe\""
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
    set -l game_args

    for arg in $argv
        switch $arg
            case --enable-mangohud
                set enable_mangohud 1
            case --disable-gamemode
                set enable_gamemode 0
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
    systemd-inhibit --what=idle --who="naraka" --why="Game is running" \
        env WINEPREFIX="$HOME/Games/naraka" \
            PROTONPATH=$proton_path \
            $command
end

function naraka_kill --description "Stop Naraka: Bladepoint by killing its wineserver"
    set -lx PROTONPATH $DW_PROTON_PATH
    set -lx WINEPREFIX "$HOME/Games/naraka"
    wineserver_kill
end

function labwc_wuwa_daily --description "Launch Wuthering Waves daily via labwc"
    cd "$HOME/Games/.bin/wuwa"

    set -l game_dir "$HOME/Games/.bin/wuwa"
    set -l saved_dir "$game_dir/Client/Saved"
    set -l config_base "$HOME/Games/.config/wuwa_daily"

    _wuwa_symlink_saved "$saved_dir" "$config_base"

    # WLR_BACKENDS=headless 
    labwc -S "env WINEPREFIX=\"$HOME/Games/wuwa_daily\" PROTONPATH=\"$DW_PROTON_PATH\" umu-run \"$HOME/Games/.bin/wuwa/Wuthering Waves.exe\""
    _wuwa_restore_saved "$saved_dir"
end

function wuwa_daily_kill --description "Stop Wuthering Waves daily by killing its wineserver"
    set -lx PROTONPATH $DW_PROTON_PATH
    set -lx WINEPREFIX "$HOME/Games/wuwa_daily"
    wineserver_kill
end
