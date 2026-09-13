function _game_resolve_proton --description "Resolve a Proton family or explicit build path"
    set -l candidates
    switch "$argv[1]"
        case dw
            set candidates /usr/share/steam/compatibilitytools.d/dwproton \
                "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/DW-Proton Latest"
        case ge
            set candidates /usr/share/steam/compatibilitytools.d/proton-ge-custom \
                "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/Proton-GE Latest"
        case '*'
            set candidates "$argv[1]"
    end

    for candidate in $candidates
        if test -f "$candidate/proton"; and test -x "$candidate/files/bin/wineserver"
            printf '%s\n' "$candidate"
            return 0
        end
    end

    printf 'Proton build not found; checked:\n' >&2
    printf '  %s\n' $candidates >&2
    return 1
end
