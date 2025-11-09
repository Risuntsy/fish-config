if not _is_nixos
    if command --query fnm
        # fnm env
        fnm env --use-on-cd --shell fish | source
    end
end

if command --query podman
    podman completion fish | source
end
