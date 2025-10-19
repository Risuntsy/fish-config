function rm
    if command --query trash
        trash $argv
    else
        echo "trash not found, do nothing"
        return 1
    end
end

function real_rm
    command rm $argv
end

function brew_up
    if command --query brew
        brew update && brew upgrade
    else
        echo "brew not found, do nothing"
        return 1
    end
end

function 7z
    if command --query 7zz
        7zz $argv
    else
        echo "7z not found, do nothing"
        return 1
    end
end

function poweroff
    sudo shutdown -h now
end

function reboot
    sudo reboot
end

function fd_clean_ds_store
    if test (count $argv) -eq 0
        fd --hidden --type f .DS_Store . --exec-batch rm
    else
        fd --hidden --type f .DS_Store $argv[1] --exec-batch rm
    end
end
