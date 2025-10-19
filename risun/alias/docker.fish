function docker_clean_all
    docker system prune -a
end

function docker_clean_images
    docker image prune -a
end

function docker_clean_containers
    docker container prune
end

