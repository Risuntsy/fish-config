if not _is_nixos

    if not contains $HOME/.local/share/fnm $PATH; and test -d $HOME/.local/share/fnm
        fish_add_path $HOME/.local/share/fnm
    end 

    if command --query fnm
        # fnm env
        fnm env --use-on-cd --shell fish | source
    end
end


