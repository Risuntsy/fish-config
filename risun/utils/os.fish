function _is_linux
    if test (uname) = "Linux"
        return 0
    else
        return 1
    end
end

function _is_macos
    if test (uname) = "Darwin"
        return 0
    else
        return 1
    end
end

function _is_nixos
    if test -f /etc/nixos/configuration.nix
        return 0
    else
        return 1
    end
end


function _is_archlinux
    if test -f /etc/os-release; and grep -q "Arch Linux" /etc/os-release
        return 0
    else
        return 1
    end
end
