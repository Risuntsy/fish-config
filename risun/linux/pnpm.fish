if command -q pnpm && test -d ~/.local/share/pnpm
    set -gx PNPM_HOME ~/.local/share/pnpm
    if not contains -- $PNPM_HOME $fish_user_paths
        fish_add_path $PNPM_HOME
    end
end
