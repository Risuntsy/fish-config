function dockur_windows_up
    docker-compose -f ~/App/dockur_windows/docker-compose.yaml up -d
end

function dockur_windows_down
    docker-compose -f ~/App/dockur_windows/docker-compose.yaml down
end

function dockur_windows_show
    #  TODO
    docker-compose -f ~/App/dockur_windows/docker-compose.yaml restart
end

function dockur_windows_clean
    dockur_windows_down
    sudo rm -rf  /home/risun/.local/share/dockur_windows
end

