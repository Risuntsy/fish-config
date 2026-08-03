if command --query podman
    podman completion fish | source
end

# bun
set -gx BUN_INSTALL "$HOME/.bun"
if test -d $BUN_INSTALL/bin; and not contains $BUN_INSTALL/bin $fish_user_paths
    fish_add_path $BUN_INSTALL/bin
end

if test -d $HOME/.local/share/flutter/bin
    fish_add_path -U -p $HOME/.local/share/flutter/bin
end
# uv / local bin
if test -d "$HOME/.local/bin"; and not contains "$HOME/.local/bin" $fish_user_paths
    fish_add_path "$HOME/.local/bin"
end

if test -d $HOME/.local/share/flutter/bin
    fish_add_path -U -p $HOME/.local/share/flutter/bin
end
