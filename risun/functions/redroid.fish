function docker_redroid_clean
    docker_redroid_down $argv
    sudo rm -rf  /mnt/kingston_nv3/redroid/$argv[1]
end

function docker_redroid_up
    docker-compose -f ~/App/redroid/$argv[1]/docker-compose.yaml up -d; or return $status
end

function docker_redroid_down
    docker-compose -f ~/App/redroid/$argv[1]/docker-compose.yaml down
end

