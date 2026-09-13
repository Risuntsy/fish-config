if command --query podman
    podman completion fish | source
end

set -gx BUN_INSTALL "$HOME/.bun"

for tool_bin in \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "$BUN_INSTALL/bin" \
    "$HOME/.deno/bin" \
    "$HOME/go/bin" \
    "$HOME/.local/share/flutter/bin" \
    "$HOME/.opencode/bin" \
    "$HOME/App/.bin"
    if test -d "$tool_bin"; and not contains -- "$tool_bin" $PATH
        fish_add_path --global "$tool_bin"
    end
end
