function code_config_fish
    code ~/.config/fish --profile common
end

function code_config_maa
    code $(maa dir config) --profile web
end

function code_config_gradle
    if test -d ~/.gradle
        code ~/.gradle --profile java
    else
        echo "~/.gradle not found"
        return 1
    end
end

function code_config_hosts
    if _is_linux
        code_web /etc/hosts
    end

    if _is_macos
        code_web /private/etc/hosts
    end
end

function code_config_dotfile
    code ~/DEV/dotfiles --profile web
end

function code_config_nix
    code_common ~/Note/memo/os/linux/distro/nix
end

function code_config_arch
    code_common ~/Note/memo/os/linux/distro/arch
end

function code_config_sing_box
    code_web ~/Note/config/sing-box
end

if _is_linux
    function code_config_container
        code_common ~/.config/containers
    end
end

