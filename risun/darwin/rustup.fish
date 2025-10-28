function setup_rustup_completions
    if command -q rustup; and not test -f ~/.config/fish/completions/rustup.fish
        mkdir -p ~/.config/fish/completions
        rustup completions fish > ~/.config/fish/completions/rustup.fish
    end
end

if not contains $HOME/.cargo/bin $PATH; and command -q rustup; and test -d $HOME/.cargo/bin
    fish_add_path $HOME/.cargo/bin
end
