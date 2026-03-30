if command --query podman
    podman completion fish | source
end

if test -d $HOME/.bun/bin; and not contains $HOME/.bun/bin $fish_user_paths
    fish_add_path $HOME/.bun/bin
end

