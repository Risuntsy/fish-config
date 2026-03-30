function code_config_fish
    code ~/.config/fish --profile common
end

function zed_config_fish
    zed ~/.config/fish
end

function code_config_maa
    if command -q maa
        code $(maa dir config) --profile web
    else
        echo "maa not found"
        return 1
    end
end

function zed_config_maa
    if command -q maa
        zed $(maa dir config)
    else
        echo "maa not found"
        return 1
    end
end

function code_config_gradle
    if test -d ~/.gradle
        code ~/.gradle --profile java
    else
        echo "~/.gradle not found"
        return 1
    end
end

function zed_config_gradle
    if test -d ~/.gradle
        zed ~/.gradle
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

function zed_config_hosts
    if _is_linux
        zed /etc/hosts
    end

    if _is_macos
        zed /private/etc/hosts
    end
end

function code_config_dotfile
    code ~/DEV/dotfiles --profile web
end

function zed_config_dotfile
    zed ~/DEV/dotfiles
end

function code_config_nix
    code_common ~/Note/memo/os/linux/distro/nix
end

function zed_config_nix
    zed ~/Note/memo/os/linux/distro/nix
end

function code_config_arch
    code_common ~/Note/memo/os/linux/distro/arch
end

function zed_config_arch
    zed ~/Note/memo/os/linux/distro/arch
end

function code_config_fedora
    code_common ~/Note/memo/os/linux/distro/fedora
end

function zed_config_fedora
    zed ~/Note/memo/os/linux/distro/fedora
end

function code_config_systemd
    code_common ~/.config/systemd/user
end

function zed_config_systemd
    zed ~/.config/systemd/user
end


function code_config_sing_box
    code_web ~/Note/config/sing-box
end

function zed_config_sing_box
    zed ~/Note/config/sing-box
end

if _is_linux
    function code_config_container
        code_common ~/.config/containers
    end
    function zed_config_container
        zed ~/.config/containers
    end
end



function code_note_app
    code ~/App --profile web
end

function zed_note_app
    zed ~/App
end

function code_note_memo
    code ~/Note/memo --profile web
end

function zed_note_memo
    zed ~/Note/memo
end

function code_note_note
    code ~/Note --profile web
end

function zed_note_note
    zed ~/Note
end

function code_note_config
    code ~/Note/config --profile web
end

function zed_note_config
    zed ~/Note/config
end

function code_note_config_push
    pushd ~/Note/config
    ./push.sh
    popd
end


function code_config_fcitx
    if _is_linux
        if test -d ~/.local/share/fcitx5/rime/
            code_web ~/.local/share/fcitx5/rime/
        else
            return 1
        end
    end

    echo 'not support yet'
    return -1
end


function zed_config_fcitx
    if _is_linux
        if test -d ~/.local/share/fcitx5/rime/
            zed ~/.local/share/fcitx5/rime/
        else
            return 1
        end
    end

    echo 'not support yet'
    return -1
end
