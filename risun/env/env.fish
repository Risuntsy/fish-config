if command --query podman
    podman completion fish | source
end

if test -d $HOME/.bun/bin; and not contains $HOME/.bun/bin $fish_user_paths
    fish_add_path $HOME/.bun/bin
end

if test -d $HOME/.local/share/flutter/bin
    fish_add_path -U -p $HOME/.local/share/flutter/bin
end
