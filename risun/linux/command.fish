function update_system --description "Update the system packages"
    if _is_archlinux
        if command -q yay
            yay -Syu
        else
            sudo pacman -Syu
        end
    end

    if _is_fedora
        sudo dnf update
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
