function update_system --description "Update the system packages"
    if _is_archlinux
        if command -q yay
            yay -Syu
        else
            sudo pacman -Syu
        end
    end

    if _is_fedora
        sudo dnf update --refresh
    end

    if command -q flatpak
        flatpak update
    end

    if _is_macos
        if command -q brew
            brew update
            brew upgrade
        end
    end
end

function rsync_copy_incr
    if test (count $argv) -lt 2
        printf "%s\n" "Usage: rsync_copy_incr <source> <destination>"
        return 1
    end
    rsync -av --update --delete $argv[1]/ $argv[2]/
end

function rsync_backup_arknights
    set folder (find ~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/ -type d -name "Arknights Game" -print -quit)
    set destination /mnt/kingston_nv3/games/hypergryph/arknights

    if test -n "$folder"; and test -d "$folder"
        mkdir -p "$destination/Arknights Game"
        rsync_copy_incr "$folder" "$destination/Arknights Game"
    else
        printf "%s\n" "Arknights Game folder not found."
        return 1
    end
end

function rsync_backup_endfield
    set folder (find ~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/ -type d -name "Endfield Game" -print -quit)
    set destination /mnt/kingston_nv3/games/hypergryph/endfield

    if test -n "$folder"; and test -d "$folder"
        mkdir -p "$destination/Endfield Game"
        rsync_copy_incr "$folder" "$destination/Endfield Game"
    else
        printf "%s\n" "Endfield Game folder not found."
        return 1
    end
end