# Games launch commands (Linux only)

set -g DW_PROTON_PATH "/home/risun/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/DW-Proton Latest"

function wuwa --description "Launch Wuthering Waves via umu-run"
    set -l proton_path $DW_PROTON_PATH
    set -l game_exe "$HOME/Games/.bin/wuwa/Wuthering Waves.exe"

    if not test -d $proton_path
        echo "wuwa: Proton not found at: $proton_path" >&2
        return 1
    end

    if not test -f $game_exe
        echo "wuwa: Game executable not found at: $game_exe" >&2
        return 1
    end

    mkdir -p "$HOME/Games/wuwa"
    systemd-inhibit --what=idle --who="wuwa" --why="Game is running" \
        env WINEPREFIX="$HOME/Games/wuwa" \
            PROTONPATH=$proton_path \
            umu-run $game_exe
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

function wuwa_stop --description "Stop Wuthering Waves by killing its wineserver"
    set -lx PROTONPATH $DW_PROTON_PATH
    set -lx WINEPREFIX "$HOME/Games/wuwa"
    wineserver_kill
end

function hypergryph_launcher --description "Launch Arknights Endfield (Hypergryph) via umu-run"
    set -l proton_path $DW_PROTON_PATH
    set -l game_exe "$HOME/Games/arknights-endfield/drive_c/Program Files/Hypergryph Launcher/Launcher.exe"

    if not test -d $proton_path
        echo "endfield: Proton not found at: $proton_path" >&2
        return 1
    end

    if not test -f $game_exe
        echo "endfield: Game executable not found at: $game_exe" >&2
        return 1
    end

    mkdir -p "$HOME/Games/arknights-endfield"
    systemd-inhibit --what=idle --who="hypergryph_launcher" --why="Game is running" \
        env WINEPREFIX="$HOME/Games/arknights-endfield" \
            PROTONPATH=$proton_path \
            umu-run $game_exe
end

function hypergryph_kill --description "Stop Arknights Endfield by killing its wineserver"
    set -lx PROTONPATH $DW_PROTON_PATH
    set -lx WINEPREFIX "$HOME/Games/arknights-endfield"
    wineserver_kill
end

function hypergryph_install --description "Run a Hypergryph installer exe into the arknights-endfield WINEPREFIX"
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
    labwc -S "env WINEPREFIX=\"$HOME/Games/arknights_endfield_daily\" PROTONPATH=\"$DW_PROTON_PATH\" umu-run \"$HOME/Games/.bin/Arknights Endfield/Endfield.exe\""
end