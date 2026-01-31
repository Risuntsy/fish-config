function code_config_fish
    code ~/.config/fish --profile common
end

function cursor_config_fish
    cursor ~/.config/fish --profile common
end

function code_config_maa
    if command -q maa
        code $(maa dir config) --profile web
    else
        echo "maa not found"
        return 1
    end
end

function cursor_config_maa
    if command -q maa
        cursor $(maa dir config) --profile web
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

function cursor_config_gradle
    if test -d ~/.gradle
        cursor ~/.gradle --profile java
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

function cursor_config_hosts
    if _is_linux
        cursor /etc/hosts
    end

    if _is_macos
        cursor /private/etc/hosts
    end
end

function code_config_dotfile
    code ~/DEV/dotfiles --profile web
end

function cursor_config_dotfile
    cursor ~/DEV/dotfiles
end

function code_config_nix
    code_common ~/Note/memo/os/linux/distro/nix
end

function cursor_config_nix
    cursor ~/Note/memo/os/linux/distro/nix
end

function code_config_arch
    code_common ~/Note/memo/os/linux/distro/arch
end

function cursor_config_arch
    cursor ~/Note/memo/os/linux/distro/arch
end

function code_config_fedora
    code_common ~/Note/memo/os/linux/distro/fedora
end

function cursor_config_fedora
    cursor ~/Note/memo/os/linux/distro/fedora
end

function code_config_systemd
    code_common ~/.config/systemd/user
end

function cursor_config_systemd
    cursor ~/.config/systemd/user
end


function code_config_sing_box
    code_web ~/Note/config/sing-box
end

function cursor_config_sing_box
    cursor ~/Note/config/sing-box
end

if _is_linux
    function code_config_container
        code_common ~/.config/containers
    end
    function cursor_config_container
        cursor ~/.config/containers
    end
end



function code_note_app
    code ~/App --profile web
end

function cursor_note_app
    cursor ~/App
end

function code_note_memo
    code ~/Note/memo --profile web
end

function cursor_note_memo
    cursor ~/Note/memo
end

function code_note_note
    code ~/Note --profile web
end

function cursor_note_note
    cursor ~/Note
end

function code_note_config
    code ~/Note/config --profile web
end

function cursor_note_config
    cursor ~/Note/config
end

function code_note_config_push
    pushd ~/Note/config
    ./push.sh
    popd
end
