function podman_purge_all
    podman system prune --all --volumes --force
end
