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
        echo "Usage: rsync_copy_incr <source> <destination>"
        return 1
    end
    rsync -av --update --delete $argv[1]/ $argv[2]/
end

