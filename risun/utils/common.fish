function _open
    switch (uname)
        case Darwin
            command open $argv
        case Linux
            command xdg-open $argv &
    end
end

function _awake_run
    if _is_macos
        if command --query caffeinate
            caffeinate $argv
        else
            echo "caffeinate not found, run $argv directly"
            $argv
        end
    else if _is_linux
        if command --query systemd-inhibit
            systemd-inhibit --what=idle:sleep:shutdown --why="Running a long task" $argv
        else
            echo "systemd-inhibit not found, running command directly."
            $argv
        end
    else
        echo "Unsupported OS, running command directly."
        $argv
    end
end


function fish_reload
    source ~/.config/fish/config.fish
end